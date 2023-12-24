package fpgamshr.main

import chisel3._
import chisel3.util._
import fpgamshr.util.{DReg, ElasticBuffer, BaseReorderBufferAXI, ReorderBufferAXI, DummyReorderBufferAXI, ReorderBufferIO}
import fpgamshr.interfaces._
import fpgamshr.crossbar.{Crossbar, MultilayerCrossbar}
import fpgamshr.reqhandler.cuckoo.{RequestHandlerCuckoo, RequestHandlerBase, InCacheMSHR}
import fpgamshr.reqhandler.traditional.{RequestHandlerBlockingCache, RequestHandlerTraditionalMSHR}
import fpgamshr.extmemarbiter.{InOrderHybridArbiter, ExternalMemoryArbiterBase}
import fpgamshr.profiling.{Profiling, ProfilingCounter, ProfilingInterface, ProfilingSelector}

import scala.collection.mutable.ArrayBuffer
import scala.language.reflectiveCalls
import com.typesafe.config.ConfigFactory

import java.io.File

object FPGAMSHR {
	def loadParams(configFilePath: Option[String]) = {
		val fileConfig = 
			if (configFilePath.isDefined)
				ConfigFactory.load(ConfigFactory.parseFile(new File(configFilePath.get)))
			else
				ConfigFactory.load("FPGAMSHR")
		if (configFilePath.isDefined) {
			println(s"Reading configuration from ${configFilePath.get}")
		} else {
			println(s"No configuration file passed, reading from default configuration src/main/resources/FPGAMSHR.conf")
		}
		reqAddrWidth  = fileConfig.getInt("reqAddrWidth")
		memAddrWidth  = fileConfig.getInt("memAddrWidth")
		memAddrOffset = java.lang.Long.decode(fileConfig.getString("memAddrOffset"))
		reqDataWidth  = fileConfig.getInt("reqDataWidth")
		reqIdWidth    = fileConfig.getInt("reqIdWidth")
		memIdWidth    = fileConfig.getInt("memIdWidth")
		memDataWidth  = fileConfig.getInt("memDataWidth")

		useROB         = fileConfig.getInt("useROB") != 0
		numInputs      = fileConfig.getInt("numInputs")
		numReqHandlers = fileConfig.getInt("numReqHandlers")

		numCacheWays            = fileConfig.getInt("numCacheWays")
		cacheSizeBytes          = fileConfig.getInt("cacheSizeBytes")
		cacheSizeReductionWidth = fileConfig.getInt("cacheSizeReductionWidth")

		// numHashTables           = fileConfig.getInt("numHashTables")
		// numMSHRPerHashTable     = fileConfig.getInt("numMSHRPerHashTable")
		numHashTables           = numCacheWays
		numMSHRPerHashTable     = (cacheSizeBytes / (memDataWidth / 8)) / numCacheWays
		mshrAssocMemorySize     = fileConfig.getInt("mshrAssocMemorySize")
		mshrAlmostFullRelMargin = fileConfig.getInt("mshrAlmostFullRelMargin")
		sameHashFunction        = fileConfig.getInt("sameHashFunction") != 0

		numSubentriesPerRow = fileConfig.getInt("numSubentriesPerRow")
		subentryAddrWidth   = fileConfig.getInt("subentryAddrWidth")
		nextPtrCacheSize    = fileConfig.getInt("nextPtrCacheSize")
		blockOnNextPtr      = fileConfig.getInt("blockOnNextPtr") != 0

		memMaxOutstandingReads       = fileConfig.getInt("memMaxOutstandingReads")
		reordExtMemArbiterQueueDepth = fileConfig.getInt("reordExtMemArbiterQueueDepth")
		numMemoryPorts               = fileConfig.getInt("numMemoryPorts")

		// numCacheBlockPerPC = fileConfig.getInt("numCacheBlockPerPC")
		numCacheBlockPerPC = numReqHandlers / numMemoryPorts

		println(s"""Configuration list:
reqAddrWidth=${reqAddrWidth}
memAddrWidth=${memAddrWidth}
memAddrOffset=${memAddrOffset}
reqDataWidth=${reqDataWidth}
reqIdWidth=${reqIdWidth}
memIdWidth=${memIdWidth}
memDataWidth=${memDataWidth}
useROB=${useROB}
numInputs=${numInputs}
numReqHandlers=${numReqHandlers}
numCacheWays=${numCacheWays}
cacheSizeBytes=${cacheSizeBytes}
cacheSizeReductionWidth=${cacheSizeReductionWidth}
numHashTables=${numHashTables}
numMSHRPerHashTable=${numMSHRPerHashTable}
mshrAssocMemorySize=${mshrAssocMemorySize}
mshrAlmostFullRelMargin=${mshrAlmostFullRelMargin}
sameHashFunction=${sameHashFunction}
numSubentriesPerRow=${numSubentriesPerRow}
subentryAddrWidth=${subentryAddrWidth}
nextPtrCacheSize=${nextPtrCacheSize}
blockOnNextPtr=${blockOnNextPtr}
memMaxOutstandingReads=${memMaxOutstandingReads}
reordExtMemArbiterQueueDepth=${reordExtMemArbiterQueueDepth}
numMemoryPorts=${numMemoryPorts}
""")


	}

	def ipName(): String = s"""MiCache_ra${FPGAMSHR.reqAddrWidth}
_id${FPGAMSHR.reqIdWidth}
_in${FPGAMSHR.numInputs}
_bk${FPGAMSHR.numReqHandlers}
_csz${if((FPGAMSHR.cacheSizeBytes > 0) && (FPGAMSHR.numCacheWays > 0)) FPGAMSHR.cacheSizeBytes else 0}
_ht${FPGAMSHR.numHashTables}
_mshr${FPGAMSHR.numMSHRPerHashTable}
_st${if(FPGAMSHR.numHashTables > 0) FPGAMSHR.mshrAssocMemorySize else 0}
_se${if(FPGAMSHR.numSubentriesPerRow == 0) FPGAMSHR.calSubentryPerLine() else FPGAMSHR.numSubentriesPerRow}
${if (FPGAMSHR.sameHashFunction) "_nocuckoo" else ""}
_mp${FPGAMSHR.numMemoryPorts}""".replace("\n", "") + (if(FPGAMSHR.useROB) "_rob" else "") + (if(Profiling.enable) "" else "_noprof")

	def calSubentryPerLine(): Int = {
		val bramPortWidthAlignment = InCacheMSHR.subentryAlignWidth * 2 // BRAM18 provides 2-byte-wide ports
		val bram18Count = (FPGAMSHR.memDataWidth / bramPortWidthAlignment) + (if (FPGAMSHR.memDataWidth % bramPortWidthAlignment == 0) 0 else 1)
		val bramPortWidth = bram18Count * bramPortWidthAlignment
		// println(s"BRAM18 count = ${bram18Count}, BRAM port width = ${bramPortWidth}")

		val idWidth = FPGAMSHR.reqIdWidth + log2Ceil(FPGAMSHR.numInputs)
		val offsetWidth = log2Ceil(FPGAMSHR.memDataWidth / FPGAMSHR.reqDataWidth)
		val aligned = roundUp(offsetWidth + idWidth, InCacheMSHR.subentryAlignWidth)
		val entriesPerLine = bramPortWidth / aligned
		val idxWidth = log2Ceil(entriesPerLine)
		// val exceeded = max * (offsetWidth + idWidth) + roundUp(maxIdxWidth, 8) > FPGAMSHR.memDataWidth
		// println(s"max entry count=${entriesPerLine}, max index width=${idxWidth}, lineWidth=${bramPortWidth}, offsetWidth=${offsetWidth}, idWidth=${idWidth}")
		// val entriesPerLine = if (exceeded) max - 1 else max
		entriesPerLine
	}

	def roundUp(a: Int, alignment: Int) = a + (alignment - a % alignment) % alignment

	var reqAddrWidth = 0
	var memAddrWidth = 0
	var memAddrOffset = 0L
	var reqDataWidth = 0
	var reqIdWidth = 0
	var memIdWidth = 0
	var memDataWidth = 0

	var useROB = true
	var numInputs = 0
	var numReqHandlers = 0

	var numCacheWays = 0
	var cacheSizeBytes = 0
	var cacheSizeReductionWidth = 0

	var numHashTables = 0
	var numMSHRPerHashTable = 0
	var mshrAssocMemorySize = 0
	var mshrAlmostFullRelMargin = 0
	var sameHashFunction = true

	var numSubentriesPerRow = 0
	var subentryAddrWidth = 0
	var nextPtrCacheSize = 0
	var blockOnNextPtr = true

	var memMaxOutstandingReads = 0
	var reordExtMemArbiterQueueDepth = 0
	var numMemoryPorts = 0

	var numCacheBlockPerPC = 0

	var outputDir = "."
	val version = 0.11
}

class FPGAMSHR extends Module {
	require(isPow2(FPGAMSHR.reqDataWidth))
	require(isPow2(FPGAMSHR.memDataWidth))
	require(isPow2(FPGAMSHR.numInputs))
	require(isPow2(FPGAMSHR.numReqHandlers))
	require(isPow2(FPGAMSHR.numMemoryPorts))
	// require(FPGAMSHR.numMemoryPorts >= FPGAMSHR.numReqHandlers) // for HBM multi-channel

	/* +1 because of the special section dedicated to the FPGAMSHR, crossbar and external memory arbiter */
	val totalProfilingAddrWidth = log2Ceil(FPGAMSHR.numReqHandlers + FPGAMSHR.numInputs + 1) +
									Profiling.regAddrWidth +
									Profiling.subModuleAddrWidth +
									log2Ceil(Profiling.dataWidth / 8)

	val io = IO(new Bundle {
		val in = Vec(FPGAMSHR.numInputs, new AXI4FullReadOnly(UInt(FPGAMSHR.reqDataWidth.W), FPGAMSHR.reqAddrWidth, FPGAMSHR.reqIdWidth))
		val out = Flipped(Vec(FPGAMSHR.numMemoryPorts, new AXI4FullReadOnly(UInt(FPGAMSHR.memDataWidth.W), FPGAMSHR.memAddrWidth, FPGAMSHR.memIdWidth)))
		val axiProfiling = new AXI4Lite(UInt(Profiling.dataWidth.W), totalProfilingAddrWidth)
		// for cycle counter control 
		val pe_running = Vec(FPGAMSHR.numInputs, Input(Bool()))
		val pe_done = Vec(FPGAMSHR.numInputs, Input(Bool()))
		val pe_all_running = Output(Bool())
		// for aux_reset
		val reset_out = Output(Bool())
		// val clock2x = Input(Clock())
	})

	val cycleCountEn = RegInit(false.B)
	when (io.pe_done.asUInt.andR) {
		cycleCountEn := false.B
	} .elsewhen (io.pe_running.asUInt.andR & ~cycleCountEn) {
		cycleCountEn := true.B
	}
	io.pe_all_running := cycleCountEn

	/* Control interface */
	/* Address 0 (control):
	- bit 0: clear if write 1
	- bit 1: snapshot if write 1
	- bit 2: invalidate if write 1
	Address 8: log2CacheSizeReduction
	Address 16: maxUsedMSHRs
	Address 24: aux_reset_in
	*/
	/* TODO: rename axiProfiling to axiControl */
	val inputProfilingWriteDataEb = Module(new ElasticBuffer(io.axiProfiling.WDATA.cloneType))
	val inputProfilingWriteAddrEb = Module(new ElasticBuffer(UInt(2.W)))
	val inputProfilingWriteStrbEb = Module(new ElasticBuffer(io.axiProfiling.WSTRB.cloneType))
	inputProfilingWriteDataEb.io.in.bits  := io.axiProfiling.WDATA
	inputProfilingWriteDataEb.io.in.valid := io.axiProfiling.WVALID
	inputProfilingWriteStrbEb.io.in.bits  := io.axiProfiling.WSTRB
	inputProfilingWriteStrbEb.io.in.valid := io.axiProfiling.WVALID
	io.axiProfiling.WREADY                := inputProfilingWriteDataEb.io.in.ready & inputProfilingWriteStrbEb.io.in.ready
	inputProfilingWriteAddrEb.io.in.bits  := io.axiProfiling.AWADDR(log2Ceil(Profiling.dataWidth / 8) + 1, log2Ceil(Profiling.dataWidth / 8))
	inputProfilingWriteAddrEb.io.in.valid := io.axiProfiling.AWVALID
	io.axiProfiling.AWREADY               := inputProfilingWriteAddrEb.io.in.ready
	/* Consume one address and one data only when both are available */
	inputProfilingWriteDataEb.io.out.ready := inputProfilingWriteAddrEb.io.out.valid & ~io.axiProfiling.BVALID
	inputProfilingWriteStrbEb.io.out.ready := inputProfilingWriteAddrEb.io.out.valid & ~io.axiProfiling.BVALID
	inputProfilingWriteAddrEb.io.out.ready := inputProfilingWriteDataEb.io.out.valid & ~io.axiProfiling.BVALID
	val dataAddrAvailable = inputProfilingWriteAddrEb.io.out.valid & inputProfilingWriteDataEb.io.out.valid & ~io.axiProfiling.BVALID

	val clear      = RegNext(dataAddrAvailable & (inputProfilingWriteAddrEb.io.out.bits === 0.U) & (inputProfilingWriteDataEb.io.out.bits(0) === 1.U) & inputProfilingWriteStrbEb.io.out.bits.asUInt.andR)
	val snapshot   = RegNext(dataAddrAvailable & (inputProfilingWriteAddrEb.io.out.bits === 0.U) & (inputProfilingWriteDataEb.io.out.bits(1) === 1.U) & inputProfilingWriteStrbEb.io.out.bits.asUInt.andR)
	val invalidate = RegNext(dataAddrAvailable & (inputProfilingWriteAddrEb.io.out.bits === 0.U) & (inputProfilingWriteDataEb.io.out.bits(2) === 1.U) & inputProfilingWriteStrbEb.io.out.bits.asUInt.andR)
	val enableCache = RegInit(true.B)
	val log2CacheSizeReduction = RegInit(0.U)
	val numMSHRTotal = FPGAMSHR.numHashTables * FPGAMSHR.numMSHRPerHashTable
	val maxAllowedMSHRs = RegInit((numMSHRTotal * (1 - FPGAMSHR.mshrAlmostFullRelMargin)).toInt.U)
	val maxAllowedSubentries = RegInit((1 << FPGAMSHR.subentryAddrWidth).U)
	val resetCycleConut = RegInit(0.U(8.W))
	when (dataAddrAvailable & (inputProfilingWriteAddrEb.io.out.bits === 0.U) & inputProfilingWriteStrbEb.io.out.bits.asUInt.andR) {
		when (inputProfilingWriteDataEb.io.out.bits(3) === 1.U) {
			enableCache := true.B
		} .elsewhen(inputProfilingWriteDataEb.io.out.bits(4) === 1.U) {
			enableCache := false.B
		}
	}
	if (FPGAMSHR.cacheSizeReductionWidth > 0) {
		when (dataAddrAvailable & (inputProfilingWriteAddrEb.io.out.bits === 1.U) & inputProfilingWriteStrbEb.io.out.bits.asUInt.andR) {
		// when (dataAddrAvailable & (inputProfilingWriteAddrEb.io.out.bits === 1.U)) {
			log2CacheSizeReduction := inputProfilingWriteDataEb.io.out.bits(FPGAMSHR.cacheSizeReductionWidth-1, 0)
		}
	} else {
		log2CacheSizeReduction := 0.U
	}
	if (numMSHRTotal > 0) {
		when (dataAddrAvailable & (inputProfilingWriteAddrEb.io.out.bits === 2.U) & inputProfilingWriteStrbEb.io.out.bits.asUInt.andR) {
			maxAllowedMSHRs := inputProfilingWriteDataEb.io.out.bits(log2Ceil(numMSHRTotal)-1, 0)
		}
		when (dataAddrAvailable & (inputProfilingWriteAddrEb.io.out.bits === 3.U) & inputProfilingWriteStrbEb.io.out.bits.asUInt.andR) {
		// when (dataAddrAvailable & (inputProfilingWriteAddrEb.io.out.bits === 3.U)) {
			// maxAllowedSubentries := inputProfilingWriteDataEb.io.out.bits(FPGAMSHR.subentryAddrWidth, 0)
			resetCycleConut := inputProfilingWriteDataEb.io.out.bits
		}
	}

	val sNormal :: sWaitAxiResp :: sResetting :: Nil = Enum(3)
	val resetState = RegInit(sNormal)
	val waitAxiRespCounter = RegInit(0.U(8.W))
	switch (resetState) {
		is (sNormal) {
			when (resetCycleConut > 0.U) {
				resetState := sWaitAxiResp
				waitAxiRespCounter := 255.U
			}
		}
		is (sWaitAxiResp) {
			when (waitAxiRespCounter === 0.U) {
				resetState := sResetting
			} .otherwise {
				waitAxiRespCounter := waitAxiRespCounter - 1.U
			}
		}
		is (sResetting) {
			when (resetCycleConut === 0.U) {
				resetState := sNormal
			} .otherwise {
				resetCycleConut := resetCycleConut - 1.U
			}
		}
	}
	io.reset_out := resetState === sResetting

	/* Input address structure:
	-----------------------------------------------------------------------------
	|     tag    |  req handler address  |    offset     |          0           |
	-----------------------------------------------------------------------------
	|<-tagWidth->|<-reqHandlerAddrWidth->|<-offsetWidth->|<-subWordOffsetWidth->|
	|<--------------------------------addrWidth-------------------------------->|
	Address between crossbar and request handler:
	------------------------------
	|     tag    |    offset     |
	------------------------------
	|<-tagWidth->|<-offsetWidth->|
	*/
	val bitsPerByte = 8
	val subWordOffsetWidth = log2Ceil(FPGAMSHR.reqDataWidth / bitsPerByte) /* Completely ignored */
	val offsetWidth = log2Ceil(FPGAMSHR.memDataWidth / FPGAMSHR.reqDataWidth)
	val reqHandlerAddrWidth = log2Ceil(FPGAMSHR.numReqHandlers)
	val tagWidth = FPGAMSHR.reqAddrWidth - subWordOffsetWidth - offsetWidth - reqHandlerAddrWidth
	/* ID structure:
	---------------------------------
	|    input id    | original id  |
	---------------------------------
	|<-inputIdWidth->|<-reqIdWidth->|
	*/

	// val crossbar = Module(new Crossbar(
	val crossbar = Module(new MultilayerCrossbar(
		nInputs      = FPGAMSHR.numInputs,
		nOutputs     = FPGAMSHR.numReqHandlers,
		addrWidth    = FPGAMSHR.reqAddrWidth - subWordOffsetWidth,
		reqDataWidth = FPGAMSHR.reqDataWidth,
		memDataWidth = FPGAMSHR.memDataWidth,
		idWidth      = FPGAMSHR.reqIdWidth,
		numCBsPerPC  = FPGAMSHR.numCacheBlockPerPC
	))
	val reorderBuffers: Array[ReorderBufferIO] =
		Array.fill(FPGAMSHR.numInputs)(
			Module(
				if (FPGAMSHR.useROB)
					new ReorderBufferAXI(FPGAMSHR.reqAddrWidth, FPGAMSHR.reqDataWidth, FPGAMSHR.reqIdWidth)
				else
					new DummyReorderBufferAXI(FPGAMSHR.reqAddrWidth, FPGAMSHR.reqDataWidth, FPGAMSHR.reqIdWidth)
			).io
		)

	io.in.zip(reorderBuffers).foreach(x => x._2.in <> x._1)
	// reorderBuffers.foreach(_.clock2x := io.clock2x)
	val crossbarInputs = reorderBuffers.map(_.out)
	for (i <- 0 until FPGAMSHR.numInputs) {
		crossbar.io.ins(i).addr.bits.addr := crossbarInputs(i).ARADDR(FPGAMSHR.reqAddrWidth - 1, subWordOffsetWidth)
		crossbar.io.ins(i).addr.valid     := crossbarInputs(i).ARVALID
		crossbarInputs(i).ARREADY         := crossbar.io.ins(i).addr.ready
		crossbar.io.ins(i).addr.bits.id   := crossbarInputs(i).ARID
		crossbarInputs(i).RDATA           := crossbar.io.ins(i).data.bits.data
		crossbarInputs(i).RVALID          := crossbar.io.ins(i).data.valid
		crossbar.io.ins(i).data.ready     := crossbarInputs(i).RREADY
		crossbarInputs(i).RID             := crossbar.io.ins(i).data.bits.id
		/* TODO: respond with SLVERR (2) if ARLEN and ARSIZE signal a burst longer than 1 beat. */
		crossbarInputs(i).RRESP           := 0.U
		/* Unused signals */
		crossbarInputs(i).RLAST           := true.B
	}

	val outCrossbarIdWidth = crossbar.io.outs(0).addr.bits.id.getWidth
	val outCrossbarAddrWidth = crossbar.io.outs(0).addr.bits.addr.getWidth
	// var reqHandlers: Array[RequestHandlerIO] = Array.fill(FPGAMSHR.numReqHandlers)(Module(new RequestHandlerBlockingCache(reqAddrWidth=outCrossbarAddrWidth,
	//     FPGAMSHR.reqDataWidth, reqIdWidth=outCrossbarIdWidth, FPGAMSHR.memDataWidth, FPGAMSHR.numCacheWays, FPGAMSHR.cacheSizeBytes)).io)
	val reqHandlers: Array[RequestHandlerIO] =
		if (FPGAMSHR.numMSHRPerHashTable > 0) {
			if (FPGAMSHR.numHashTables > 0) {
				Array.fill(FPGAMSHR.numReqHandlers)(
					Module(new RequestHandlerCuckoo(
						reqAddrWidth=outCrossbarAddrWidth,
						FPGAMSHR.reqDataWidth,
						reqIdWidth=outCrossbarIdWidth,
						FPGAMSHR.memDataWidth,
						FPGAMSHR.numHashTables,
						FPGAMSHR.numMSHRPerHashTable,
						FPGAMSHR.mshrAssocMemorySize,
						FPGAMSHR.numSubentriesPerRow,
						FPGAMSHR.subentryAddrWidth,
						FPGAMSHR.numCacheWays,
						FPGAMSHR.cacheSizeBytes,
						FPGAMSHR.cacheSizeReductionWidth,
						numMSHRWidth=log2Ceil(numMSHRTotal + 1),
						FPGAMSHR.nextPtrCacheSize,
						FPGAMSHR.blockOnNextPtr,
						FPGAMSHR.sameHashFunction
					)).io
				)
			} else {
				Array.fill(FPGAMSHR.numReqHandlers)(
					Module(new RequestHandlerTraditionalMSHR(
						reqAddrWidth=outCrossbarAddrWidth,
						FPGAMSHR.reqDataWidth,
						reqIdWidth=outCrossbarIdWidth,
						FPGAMSHR.memDataWidth,
						FPGAMSHR.numMSHRPerHashTable,
						FPGAMSHR.numSubentriesPerRow,
						FPGAMSHR.numCacheWays,
						FPGAMSHR.cacheSizeBytes,
						FPGAMSHR.cacheSizeReductionWidth
					)).io
				)
			}
		} else {
			Array.fill(FPGAMSHR.numReqHandlers)(
				Module(new RequestHandlerBlockingCache(
					reqAddrWidth=outCrossbarAddrWidth,
					FPGAMSHR.reqDataWidth,
					reqIdWidth=outCrossbarIdWidth,
					FPGAMSHR.memDataWidth,
					FPGAMSHR.numCacheWays,
					FPGAMSHR.cacheSizeBytes,
					FPGAMSHR.cacheSizeReductionWidth
				)).io
			)
		}

	val numExtMemArbiter = FPGAMSHR.numReqHandlers / FPGAMSHR.numCacheBlockPerPC
	val numPCsPerArbiter = FPGAMSHR.numMemoryPorts / numExtMemArbiter
	val extMemArbiters =
		for {i <- 0 until numExtMemArbiter} yield
			Module(new InOrderHybridArbiter(
				FPGAMSHR.reqAddrWidth,
				FPGAMSHR.memAddrWidth,
				FPGAMSHR.memDataWidth,
				FPGAMSHR.memIdWidth,
				FPGAMSHR.numReqHandlers,
				FPGAMSHR.memMaxOutstandingReads,
				FPGAMSHR.memAddrOffset,
				numMemoryPorts=FPGAMSHR.numMemoryPorts,
				memArbiterId=i,
				FPGAMSHR.numCacheBlockPerPC
			))

	for (i <- 0 until FPGAMSHR.numReqHandlers) {
		reqHandlers(i).inReq <> crossbar.io.outs(i)
		reqHandlers(i).invalidate             := invalidate
		reqHandlers(i).log2CacheSizeReduction := log2CacheSizeReduction
		reqHandlers(i).maxAllowedMSHRs        := maxAllowedMSHRs
		reqHandlers(i).maxAllowedSubentries   := maxAllowedSubentries
		reqHandlers(i).enableCache            := enableCache
		// reqHandlers(i).clock2x := io.clock2x

		extMemArbiters(i / FPGAMSHR.numCacheBlockPerPC).io.inReq(i % FPGAMSHR.numCacheBlockPerPC) <> reqHandlers(i).outMemReq
		reqHandlers(i).inMemResp <> extMemArbiters(i / FPGAMSHR.numCacheBlockPerPC).io.outResp(i % FPGAMSHR.numCacheBlockPerPC)
	}

	for (i <- 0 until numExtMemArbiter) {
		for (j <- 0 until numPCsPerArbiter) {
			extMemArbiters(i).io.outMem(j) <> io.out(i + j * numExtMemArbiter)
		}
	}

	/* Profiling */
	if (Profiling.enable) {
		val inputProfilingReadEb = Module(new ElasticBuffer(UInt((totalProfilingAddrWidth - log2Ceil(Profiling.dataWidth / 8)).W))) /* We latch the address */
		inputProfilingReadEb.io.in.bits  := io.axiProfiling.ARADDR(totalProfilingAddrWidth-1, log2Ceil(Profiling.dataWidth / 8))
		inputProfilingReadEb.io.in.valid := io.axiProfiling.ARVALID
		io.axiProfiling.ARREADY          := inputProfilingReadEb.io.in.ready

		val totalCycleCounter = ProfilingCounter(cycleCountEn, Profiling.dataWidth, snapshot, clear)
		val cyclesExtMemNotReady = io.out.map(x => ProfilingCounter(x.ARVALID & ~x.ARREADY, Profiling.dataWidth, snapshot, clear))
		val reqSent = io.out.map(x => ProfilingCounter(x.ARVALID & x.ARREADY, Profiling.dataWidth, snapshot, clear))
		val respReceived = io.out.map(x => ProfilingCounter(x.ARVALID & x.ARREADY, Profiling.dataWidth, snapshot, clear))
		// val fpgamshrRegAddr = Wire(DecoupledIO(UInt(Profiling.regAddrWidth.W)))
		val fpgamshrSubModuleAddr = Wire(DecoupledIO(UInt((Profiling.regAddrWidth + Profiling.subModuleAddrWidth).W)))
		// val w = fpgamshrSubModuleAddr.bits.getWidth
		// println(s"fpgamshrSubModuleAddr.bits.getWidth=$w")

		val fpgamshrRegAxiProfiling = Wire(new AXI4LiteReadOnlyProfiling(Profiling.dataWidth, Profiling.regAddrWidth))
		val fpgamshrProfilingInterface = ProfilingInterface(fpgamshrRegAxiProfiling.axi,
															Vec(ArrayBuffer(totalCycleCounter) ++ cyclesExtMemNotReady ++ reqSent ++ respReceived))
		fpgamshrRegAxiProfiling.axi.RDATA  := fpgamshrProfilingInterface.bits
		fpgamshrRegAxiProfiling.axi.RRESP  := 0.U
		fpgamshrRegAxiProfiling.axi.RVALID := fpgamshrProfilingInterface.valid
		fpgamshrProfilingInterface.ready   := fpgamshrRegAxiProfiling.axi.RREADY

		val dummyAxiProfiling = Wire(new AXI4LiteReadOnlyProfiling(Profiling.dataWidth, Profiling.regAddrWidth))
		dummyAxiProfiling.axi.RDATA   := DontCare
		dummyAxiProfiling.axi.RRESP   := 0.U
		dummyAxiProfiling.axi.RVALID  := false.B
		dummyAxiProfiling.axi.ARREADY := true.B

		val fpgamshrSelector = ProfilingSelector(fpgamshrSubModuleAddr,
												Array(fpgamshrRegAxiProfiling) ++ Seq.fill(3)(dummyAxiProfiling), snapshot=snapshot, clear=clear)
		val fpgamshrAxiProfiling = Wire(new AXI4LiteReadOnlyProfiling(Profiling.dataWidth, Profiling.regAddrWidth + Profiling.subModuleAddrWidth))
		fpgamshrAxiProfiling.axi.RDATA   := fpgamshrSelector.bits
		fpgamshrAxiProfiling.axi.RRESP   := 0.U
		fpgamshrAxiProfiling.axi.RVALID  := fpgamshrSelector.valid
		fpgamshrSelector.ready           := fpgamshrAxiProfiling.axi.RREADY
		fpgamshrSubModuleAddr.bits       := fpgamshrAxiProfiling.axi.ARADDR
		fpgamshrSubModuleAddr.valid      := fpgamshrAxiProfiling.axi.ARVALID
		fpgamshrAxiProfiling.axi.ARREADY := fpgamshrSubModuleAddr.ready

		val subModulesProfilingInterfaces = reqHandlers.map(_.axiProfiling) ++ reorderBuffers.map(_.axiProfiling) ++ Array(fpgamshrAxiProfiling)
		val globalSelector = ProfilingSelector(inputProfilingReadEb.io.out, subModulesProfilingInterfaces, clear=clear, snapshot=snapshot)
		val outputProfilingEb = ElasticBuffer(globalSelector)
		io.axiProfiling.RDATA   := outputProfilingEb.bits
		io.axiProfiling.RVALID  := outputProfilingEb.valid
		outputProfilingEb.ready := io.axiProfiling.RREADY
		io.axiProfiling.RRESP   := 0.U
		io.axiProfiling.BRESP   := 0.U

		val axiprofBVALID = RegInit(false.B)
		when (dataAddrAvailable) {
			axiprofBVALID := true.B
		}.elsewhen (axiprofBVALID & io.axiProfiling.BREADY) {
			axiprofBVALID := false.B
		}
		io.axiProfiling.BVALID := axiprofBVALID
		// io.axiProfiling.BVALID := RegNext(io.axiProfiling.WVALID)
		// io.axiProfiling.AWREADY := true.B
		// io.axiProfiling.WREADY := true.B
	} else {
		io.axiProfiling.ARREADY := false.B
		io.axiProfiling.RVALID  := false.B
		io.axiProfiling.RDATA   := DontCare
		io.axiProfiling.RRESP   := DontCare
		io.axiProfiling.AWREADY := false.B
		io.axiProfiling.WREADY  := false.B
		io.axiProfiling.BRESP   := 0.U
		io.axiProfiling.BVALID  := false.B
	}
}
