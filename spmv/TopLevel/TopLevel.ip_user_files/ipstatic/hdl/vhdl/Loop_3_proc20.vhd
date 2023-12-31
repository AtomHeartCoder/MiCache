-- ==============================================================
-- RTL generated by Vivado(TM) HLS - High-Level Synthesis from C, C++ and SystemC
-- Version: 2017.4
-- Copyright (C) 1986-2017 Xilinx, Inc. All Rights Reserved.
-- 
-- ===========================================================

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity Loop_3_proc20 is
port (
    ap_clk : IN STD_LOGIC;
    ap_rst : IN STD_LOGIC;
    ap_start : IN STD_LOGIC;
    ap_done : OUT STD_LOGIC;
    ap_continue : IN STD_LOGIC;
    ap_idle : OUT STD_LOGIC;
    ap_ready : OUT STD_LOGIC;
    output_size_dout : IN STD_LOGIC_VECTOR (31 downto 0);
    output_size_empty_n : IN STD_LOGIC;
    output_size_read : OUT STD_LOGIC;
    rowptr_stream_TDATA : IN STD_LOGIC_VECTOR (31 downto 0);
    rowptr_stream_TVALID : IN STD_LOGIC;
    rowptr_stream_TREADY : OUT STD_LOGIC;
    rowptr_stream_TKEEP : IN STD_LOGIC_VECTOR (3 downto 0);
    rowptr_stream_TLAST : IN STD_LOGIC;
    row_size_stream_V_TDATA : OUT STD_LOGIC_VECTOR (31 downto 0);
    row_size_stream_V_TVALID : OUT STD_LOGIC;
    row_size_stream_V_TREADY : IN STD_LOGIC );
end;


architecture behav of Loop_3_proc20 is 
    constant ap_const_logic_1 : STD_LOGIC := '1';
    constant ap_const_logic_0 : STD_LOGIC := '0';
    constant ap_ST_fsm_state1 : STD_LOGIC_VECTOR (3 downto 0) := "0001";
    constant ap_ST_fsm_state2 : STD_LOGIC_VECTOR (3 downto 0) := "0010";
    constant ap_ST_fsm_pp0_stage0 : STD_LOGIC_VECTOR (3 downto 0) := "0100";
    constant ap_ST_fsm_state6 : STD_LOGIC_VECTOR (3 downto 0) := "1000";
    constant ap_const_lv32_0 : STD_LOGIC_VECTOR (31 downto 0) := "00000000000000000000000000000000";
    constant ap_const_boolean_1 : BOOLEAN := true;
    constant ap_const_lv1_0 : STD_LOGIC_VECTOR (0 downto 0) := "0";
    constant ap_const_lv1_1 : STD_LOGIC_VECTOR (0 downto 0) := "1";
    constant ap_const_lv2_0 : STD_LOGIC_VECTOR (1 downto 0) := "00";
    constant ap_const_lv2_2 : STD_LOGIC_VECTOR (1 downto 0) := "10";
    constant ap_const_lv2_3 : STD_LOGIC_VECTOR (1 downto 0) := "11";
    constant ap_const_lv2_1 : STD_LOGIC_VECTOR (1 downto 0) := "01";
    constant ap_const_lv32_2 : STD_LOGIC_VECTOR (31 downto 0) := "00000000000000000000000000000010";
    constant ap_const_boolean_0 : BOOLEAN := false;
    constant ap_const_lv32_1 : STD_LOGIC_VECTOR (31 downto 0) := "00000000000000000000000000000001";
    constant ap_const_lv32_3 : STD_LOGIC_VECTOR (31 downto 0) := "00000000000000000000000000000011";

    signal ap_done_reg : STD_LOGIC := '0';
    signal ap_CS_fsm : STD_LOGIC_VECTOR (3 downto 0) := "0001";
    attribute fsm_encoding : string;
    attribute fsm_encoding of ap_CS_fsm : signal is "none";
    signal ap_CS_fsm_state1 : STD_LOGIC;
    attribute fsm_encoding of ap_CS_fsm_state1 : signal is "none";
    signal rowptr_stream_V_data_0_data_out : STD_LOGIC_VECTOR (31 downto 0);
    signal rowptr_stream_V_data_0_vld_in : STD_LOGIC;
    signal rowptr_stream_V_data_0_vld_out : STD_LOGIC;
    signal rowptr_stream_V_data_0_ack_in : STD_LOGIC;
    signal rowptr_stream_V_data_0_ack_out : STD_LOGIC;
    signal rowptr_stream_V_data_0_payload_A : STD_LOGIC_VECTOR (31 downto 0);
    signal rowptr_stream_V_data_0_payload_B : STD_LOGIC_VECTOR (31 downto 0);
    signal rowptr_stream_V_data_0_sel_rd : STD_LOGIC := '0';
    signal rowptr_stream_V_data_0_sel_wr : STD_LOGIC := '0';
    signal rowptr_stream_V_data_0_sel : STD_LOGIC;
    signal rowptr_stream_V_data_0_load_A : STD_LOGIC;
    signal rowptr_stream_V_data_0_load_B : STD_LOGIC;
    signal rowptr_stream_V_data_0_state : STD_LOGIC_VECTOR (1 downto 0) := "00";
    signal rowptr_stream_V_data_0_state_cmp_full : STD_LOGIC;
    signal rowptr_stream_V_last_0_vld_in : STD_LOGIC;
    signal rowptr_stream_V_last_0_ack_out : STD_LOGIC;
    signal rowptr_stream_V_last_0_state : STD_LOGIC_VECTOR (1 downto 0) := "00";
    signal row_size_stream_V_1_data_out : STD_LOGIC_VECTOR (31 downto 0);
    signal row_size_stream_V_1_vld_in : STD_LOGIC;
    signal row_size_stream_V_1_vld_out : STD_LOGIC;
    signal row_size_stream_V_1_ack_in : STD_LOGIC;
    signal row_size_stream_V_1_ack_out : STD_LOGIC;
    signal row_size_stream_V_1_payload_A : STD_LOGIC_VECTOR (31 downto 0);
    signal row_size_stream_V_1_payload_B : STD_LOGIC_VECTOR (31 downto 0);
    signal row_size_stream_V_1_sel_rd : STD_LOGIC := '0';
    signal row_size_stream_V_1_sel_wr : STD_LOGIC := '0';
    signal row_size_stream_V_1_sel : STD_LOGIC;
    signal row_size_stream_V_1_load_A : STD_LOGIC;
    signal row_size_stream_V_1_load_B : STD_LOGIC;
    signal row_size_stream_V_1_state : STD_LOGIC_VECTOR (1 downto 0) := "00";
    signal row_size_stream_V_1_state_cmp_full : STD_LOGIC;
    signal output_size_blk_n : STD_LOGIC;
    signal rowptr_stream_TDATA_blk_n : STD_LOGIC;
    signal ap_CS_fsm_pp0_stage0 : STD_LOGIC;
    attribute fsm_encoding of ap_CS_fsm_pp0_stage0 : signal is "none";
    signal ap_enable_reg_pp0_iter1 : STD_LOGIC := '0';
    signal ap_block_pp0_stage0 : BOOLEAN;
    signal row_size_stream_V_TDATA_blk_n : STD_LOGIC;
    signal tmp_8_i_reg_160 : STD_LOGIC_VECTOR (0 downto 0);
    signal ap_enable_reg_pp0_iter2 : STD_LOGIC := '0';
    signal ap_reg_pp0_iter1_tmp_8_i_reg_160 : STD_LOGIC_VECTOR (0 downto 0);
    signal i2_i_reg_83 : STD_LOGIC_VECTOR (31 downto 0);
    signal output_size_read_reg_141 : STD_LOGIC_VECTOR (31 downto 0);
    signal ap_block_state1 : BOOLEAN;
    signal tmp_7_i_fu_94_p2 : STD_LOGIC_VECTOR (31 downto 0);
    signal tmp_7_i_reg_146 : STD_LOGIC_VECTOR (31 downto 0);
    signal ap_CS_fsm_state2 : STD_LOGIC;
    attribute fsm_encoding of ap_CS_fsm_state2 : signal is "none";
    signal exitcond3_i_fu_99_p2 : STD_LOGIC_VECTOR (0 downto 0);
    signal ap_block_state3_pp0_stage0_iter0 : BOOLEAN;
    signal ap_block_state4_pp0_stage0_iter1 : BOOLEAN;
    signal ap_block_state4_io : BOOLEAN;
    signal ap_block_state5_pp0_stage0_iter2 : BOOLEAN;
    signal ap_block_state5_io : BOOLEAN;
    signal ap_block_pp0_stage0_11001 : BOOLEAN;
    signal i_fu_104_p2 : STD_LOGIC_VECTOR (31 downto 0);
    signal ap_enable_reg_pp0_iter0 : STD_LOGIC := '0';
    signal tmp_8_i_fu_110_p2 : STD_LOGIC_VECTOR (0 downto 0);
    signal tmp_fu_128_p2 : STD_LOGIC_VECTOR (31 downto 0);
    signal ap_block_pp0_stage0_subdone : BOOLEAN;
    signal ap_condition_pp0_exit_iter0_state3 : STD_LOGIC;
    signal end_val_tmp_data_fu_56 : STD_LOGIC_VECTOR (31 downto 0);
    signal ap_block_pp0_stage0_01001 : BOOLEAN;
    signal ap_CS_fsm_state6 : STD_LOGIC;
    attribute fsm_encoding of ap_CS_fsm_state6 : signal is "none";
    signal ap_NS_fsm : STD_LOGIC_VECTOR (3 downto 0);
    signal ap_idle_pp0 : STD_LOGIC;
    signal ap_enable_pp0 : STD_LOGIC;


begin




    ap_CS_fsm_assign_proc : process(ap_clk)
    begin
        if (ap_clk'event and ap_clk =  '1') then
            if (ap_rst = '1') then
                ap_CS_fsm <= ap_ST_fsm_state1;
            else
                ap_CS_fsm <= ap_NS_fsm;
            end if;
        end if;
    end process;


    ap_done_reg_assign_proc : process(ap_clk)
    begin
        if (ap_clk'event and ap_clk =  '1') then
            if (ap_rst = '1') then
                ap_done_reg <= ap_const_logic_0;
            else
                if ((ap_continue = ap_const_logic_1)) then 
                    ap_done_reg <= ap_const_logic_0;
                elsif (((row_size_stream_V_1_ack_in = ap_const_logic_1) and (ap_const_logic_1 = ap_CS_fsm_state6))) then 
                    ap_done_reg <= ap_const_logic_1;
                end if; 
            end if;
        end if;
    end process;


    ap_enable_reg_pp0_iter0_assign_proc : process(ap_clk)
    begin
        if (ap_clk'event and ap_clk =  '1') then
            if (ap_rst = '1') then
                ap_enable_reg_pp0_iter0 <= ap_const_logic_0;
            else
                if (((ap_const_boolean_0 = ap_block_pp0_stage0_subdone) and (ap_const_logic_1 = ap_condition_pp0_exit_iter0_state3) and (ap_const_logic_1 = ap_CS_fsm_pp0_stage0))) then 
                    ap_enable_reg_pp0_iter0 <= ap_const_logic_0;
                elsif ((ap_const_logic_1 = ap_CS_fsm_state2)) then 
                    ap_enable_reg_pp0_iter0 <= ap_const_logic_1;
                end if; 
            end if;
        end if;
    end process;


    ap_enable_reg_pp0_iter1_assign_proc : process(ap_clk)
    begin
        if (ap_clk'event and ap_clk =  '1') then
            if (ap_rst = '1') then
                ap_enable_reg_pp0_iter1 <= ap_const_logic_0;
            else
                if ((ap_const_boolean_0 = ap_block_pp0_stage0_subdone)) then
                    if ((ap_const_logic_1 = ap_condition_pp0_exit_iter0_state3)) then 
                        ap_enable_reg_pp0_iter1 <= (ap_const_logic_1 xor ap_condition_pp0_exit_iter0_state3);
                    elsif ((ap_const_boolean_1 = ap_const_boolean_1)) then 
                        ap_enable_reg_pp0_iter1 <= ap_enable_reg_pp0_iter0;
                    end if;
                end if; 
            end if;
        end if;
    end process;


    ap_enable_reg_pp0_iter2_assign_proc : process(ap_clk)
    begin
        if (ap_clk'event and ap_clk =  '1') then
            if (ap_rst = '1') then
                ap_enable_reg_pp0_iter2 <= ap_const_logic_0;
            else
                if ((ap_const_boolean_0 = ap_block_pp0_stage0_subdone)) then 
                    ap_enable_reg_pp0_iter2 <= ap_enable_reg_pp0_iter1;
                elsif ((ap_const_logic_1 = ap_CS_fsm_state2)) then 
                    ap_enable_reg_pp0_iter2 <= ap_const_logic_0;
                end if; 
            end if;
        end if;
    end process;


    row_size_stream_V_1_sel_rd_assign_proc : process(ap_clk)
    begin
        if (ap_clk'event and ap_clk =  '1') then
            if (ap_rst = '1') then
                row_size_stream_V_1_sel_rd <= ap_const_logic_0;
            else
                if (((row_size_stream_V_1_ack_out = ap_const_logic_1) and (row_size_stream_V_1_vld_out = ap_const_logic_1))) then 
                                        row_size_stream_V_1_sel_rd <= not(row_size_stream_V_1_sel_rd);
                end if; 
            end if;
        end if;
    end process;


    row_size_stream_V_1_sel_wr_assign_proc : process(ap_clk)
    begin
        if (ap_clk'event and ap_clk =  '1') then
            if (ap_rst = '1') then
                row_size_stream_V_1_sel_wr <= ap_const_logic_0;
            else
                if (((row_size_stream_V_1_ack_in = ap_const_logic_1) and (row_size_stream_V_1_vld_in = ap_const_logic_1))) then 
                                        row_size_stream_V_1_sel_wr <= not(row_size_stream_V_1_sel_wr);
                end if; 
            end if;
        end if;
    end process;


    row_size_stream_V_1_state_assign_proc : process(ap_clk)
    begin
        if (ap_clk'event and ap_clk =  '1') then
            if (ap_rst = '1') then
                row_size_stream_V_1_state <= ap_const_lv2_0;
            else
                if ((((row_size_stream_V_1_state = ap_const_lv2_2) and (row_size_stream_V_1_vld_in = ap_const_logic_0)) or ((row_size_stream_V_1_state = ap_const_lv2_3) and (row_size_stream_V_1_vld_in = ap_const_logic_0) and (row_size_stream_V_1_ack_out = ap_const_logic_1)))) then 
                    row_size_stream_V_1_state <= ap_const_lv2_2;
                elsif ((((row_size_stream_V_1_state = ap_const_lv2_1) and (row_size_stream_V_1_ack_out = ap_const_logic_0)) or ((row_size_stream_V_1_state = ap_const_lv2_3) and (row_size_stream_V_1_ack_out = ap_const_logic_0) and (row_size_stream_V_1_vld_in = ap_const_logic_1)))) then 
                    row_size_stream_V_1_state <= ap_const_lv2_1;
                elsif (((not(((row_size_stream_V_1_vld_in = ap_const_logic_0) and (row_size_stream_V_1_ack_out = ap_const_logic_1))) and not(((row_size_stream_V_1_ack_out = ap_const_logic_0) and (row_size_stream_V_1_vld_in = ap_const_logic_1))) and (row_size_stream_V_1_state = ap_const_lv2_3)) or ((row_size_stream_V_1_state = ap_const_lv2_1) and (row_size_stream_V_1_ack_out = ap_const_logic_1)) or ((row_size_stream_V_1_state = ap_const_lv2_2) and (row_size_stream_V_1_vld_in = ap_const_logic_1)))) then 
                    row_size_stream_V_1_state <= ap_const_lv2_3;
                else 
                    row_size_stream_V_1_state <= ap_const_lv2_2;
                end if; 
            end if;
        end if;
    end process;


    rowptr_stream_V_data_0_sel_rd_assign_proc : process(ap_clk)
    begin
        if (ap_clk'event and ap_clk =  '1') then
            if (ap_rst = '1') then
                rowptr_stream_V_data_0_sel_rd <= ap_const_logic_0;
            else
                if (((rowptr_stream_V_data_0_ack_out = ap_const_logic_1) and (rowptr_stream_V_data_0_vld_out = ap_const_logic_1))) then 
                                        rowptr_stream_V_data_0_sel_rd <= not(rowptr_stream_V_data_0_sel_rd);
                end if; 
            end if;
        end if;
    end process;


    rowptr_stream_V_data_0_sel_wr_assign_proc : process(ap_clk)
    begin
        if (ap_clk'event and ap_clk =  '1') then
            if (ap_rst = '1') then
                rowptr_stream_V_data_0_sel_wr <= ap_const_logic_0;
            else
                if (((rowptr_stream_V_data_0_ack_in = ap_const_logic_1) and (rowptr_stream_V_data_0_vld_in = ap_const_logic_1))) then 
                                        rowptr_stream_V_data_0_sel_wr <= not(rowptr_stream_V_data_0_sel_wr);
                end if; 
            end if;
        end if;
    end process;


    rowptr_stream_V_data_0_state_assign_proc : process(ap_clk)
    begin
        if (ap_clk'event and ap_clk =  '1') then
            if (ap_rst = '1') then
                rowptr_stream_V_data_0_state <= ap_const_lv2_0;
            else
                if ((((rowptr_stream_V_data_0_state = ap_const_lv2_2) and (rowptr_stream_V_data_0_vld_in = ap_const_logic_0)) or ((rowptr_stream_V_data_0_state = ap_const_lv2_3) and (rowptr_stream_V_data_0_vld_in = ap_const_logic_0) and (rowptr_stream_V_data_0_ack_out = ap_const_logic_1)))) then 
                    rowptr_stream_V_data_0_state <= ap_const_lv2_2;
                elsif ((((rowptr_stream_V_data_0_state = ap_const_lv2_1) and (rowptr_stream_V_data_0_ack_out = ap_const_logic_0)) or ((rowptr_stream_V_data_0_state = ap_const_lv2_3) and (rowptr_stream_V_data_0_ack_out = ap_const_logic_0) and (rowptr_stream_V_data_0_vld_in = ap_const_logic_1)))) then 
                    rowptr_stream_V_data_0_state <= ap_const_lv2_1;
                elsif (((not(((rowptr_stream_V_data_0_vld_in = ap_const_logic_0) and (rowptr_stream_V_data_0_ack_out = ap_const_logic_1))) and not(((rowptr_stream_V_data_0_ack_out = ap_const_logic_0) and (rowptr_stream_V_data_0_vld_in = ap_const_logic_1))) and (rowptr_stream_V_data_0_state = ap_const_lv2_3)) or ((rowptr_stream_V_data_0_state = ap_const_lv2_1) and (rowptr_stream_V_data_0_ack_out = ap_const_logic_1)) or ((rowptr_stream_V_data_0_state = ap_const_lv2_2) and (rowptr_stream_V_data_0_vld_in = ap_const_logic_1)))) then 
                    rowptr_stream_V_data_0_state <= ap_const_lv2_3;
                else 
                    rowptr_stream_V_data_0_state <= ap_const_lv2_2;
                end if; 
            end if;
        end if;
    end process;


    rowptr_stream_V_last_0_state_assign_proc : process(ap_clk)
    begin
        if (ap_clk'event and ap_clk =  '1') then
            if (ap_rst = '1') then
                rowptr_stream_V_last_0_state <= ap_const_lv2_0;
            else
                if ((((rowptr_stream_V_last_0_state = ap_const_lv2_2) and (rowptr_stream_V_last_0_vld_in = ap_const_logic_0)) or ((rowptr_stream_V_last_0_state = ap_const_lv2_3) and (rowptr_stream_V_last_0_vld_in = ap_const_logic_0) and (rowptr_stream_V_last_0_ack_out = ap_const_logic_1)))) then 
                    rowptr_stream_V_last_0_state <= ap_const_lv2_2;
                elsif ((((rowptr_stream_V_last_0_state = ap_const_lv2_1) and (rowptr_stream_V_last_0_ack_out = ap_const_logic_0)) or ((rowptr_stream_V_last_0_state = ap_const_lv2_3) and (rowptr_stream_V_last_0_ack_out = ap_const_logic_0) and (rowptr_stream_V_last_0_vld_in = ap_const_logic_1)))) then 
                    rowptr_stream_V_last_0_state <= ap_const_lv2_1;
                elsif (((not(((rowptr_stream_V_last_0_vld_in = ap_const_logic_0) and (rowptr_stream_V_last_0_ack_out = ap_const_logic_1))) and not(((rowptr_stream_V_last_0_ack_out = ap_const_logic_0) and (rowptr_stream_V_last_0_vld_in = ap_const_logic_1))) and (rowptr_stream_V_last_0_state = ap_const_lv2_3)) or ((rowptr_stream_V_last_0_state = ap_const_lv2_1) and (rowptr_stream_V_last_0_ack_out = ap_const_logic_1)) or ((rowptr_stream_V_last_0_state = ap_const_lv2_2) and (rowptr_stream_V_last_0_vld_in = ap_const_logic_1)))) then 
                    rowptr_stream_V_last_0_state <= ap_const_lv2_3;
                else 
                    rowptr_stream_V_last_0_state <= ap_const_lv2_2;
                end if; 
            end if;
        end if;
    end process;


    i2_i_reg_83_assign_proc : process (ap_clk)
    begin
        if (ap_clk'event and ap_clk = '1') then
            if (((exitcond3_i_fu_99_p2 = ap_const_lv1_0) and (ap_const_boolean_0 = ap_block_pp0_stage0_11001) and (ap_enable_reg_pp0_iter0 = ap_const_logic_1) and (ap_const_logic_1 = ap_CS_fsm_pp0_stage0))) then 
                i2_i_reg_83 <= i_fu_104_p2;
            elsif ((ap_const_logic_1 = ap_CS_fsm_state2)) then 
                i2_i_reg_83 <= ap_const_lv32_0;
            end if; 
        end if;
    end process;
    process (ap_clk)
    begin
        if (ap_clk'event and ap_clk = '1') then
            if (((ap_const_boolean_0 = ap_block_pp0_stage0_11001) and (ap_const_logic_1 = ap_CS_fsm_pp0_stage0))) then
                ap_reg_pp0_iter1_tmp_8_i_reg_160 <= tmp_8_i_reg_160;
            end if;
        end if;
    end process;
    process (ap_clk)
    begin
        if (ap_clk'event and ap_clk = '1') then
            if (((ap_const_boolean_0 = ap_block_pp0_stage0_11001) and (ap_enable_reg_pp0_iter1 = ap_const_logic_1) and (ap_const_logic_1 = ap_CS_fsm_pp0_stage0))) then
                end_val_tmp_data_fu_56 <= rowptr_stream_V_data_0_data_out;
            end if;
        end if;
    end process;
    process (ap_clk)
    begin
        if (ap_clk'event and ap_clk = '1') then
            if ((not(((ap_start = ap_const_logic_0) or (output_size_empty_n = ap_const_logic_0) or (ap_done_reg = ap_const_logic_1))) and (ap_const_logic_1 = ap_CS_fsm_state1))) then
                output_size_read_reg_141 <= output_size_dout;
            end if;
        end if;
    end process;
    process (ap_clk)
    begin
        if (ap_clk'event and ap_clk = '1') then
            if ((row_size_stream_V_1_load_A = ap_const_logic_1)) then
                row_size_stream_V_1_payload_A <= tmp_fu_128_p2;
            end if;
        end if;
    end process;
    process (ap_clk)
    begin
        if (ap_clk'event and ap_clk = '1') then
            if ((row_size_stream_V_1_load_B = ap_const_logic_1)) then
                row_size_stream_V_1_payload_B <= tmp_fu_128_p2;
            end if;
        end if;
    end process;
    process (ap_clk)
    begin
        if (ap_clk'event and ap_clk = '1') then
            if ((rowptr_stream_V_data_0_load_A = ap_const_logic_1)) then
                rowptr_stream_V_data_0_payload_A <= rowptr_stream_TDATA;
            end if;
        end if;
    end process;
    process (ap_clk)
    begin
        if (ap_clk'event and ap_clk = '1') then
            if ((rowptr_stream_V_data_0_load_B = ap_const_logic_1)) then
                rowptr_stream_V_data_0_payload_B <= rowptr_stream_TDATA;
            end if;
        end if;
    end process;
    process (ap_clk)
    begin
        if (ap_clk'event and ap_clk = '1') then
            if ((ap_const_logic_1 = ap_CS_fsm_state2)) then
                tmp_7_i_reg_146 <= tmp_7_i_fu_94_p2;
            end if;
        end if;
    end process;
    process (ap_clk)
    begin
        if (ap_clk'event and ap_clk = '1') then
            if (((exitcond3_i_fu_99_p2 = ap_const_lv1_0) and (ap_const_boolean_0 = ap_block_pp0_stage0_11001) and (ap_const_logic_1 = ap_CS_fsm_pp0_stage0))) then
                tmp_8_i_reg_160 <= tmp_8_i_fu_110_p2;
            end if;
        end if;
    end process;

    ap_NS_fsm_assign_proc : process (ap_start, ap_done_reg, ap_CS_fsm, ap_CS_fsm_state1, output_size_empty_n, row_size_stream_V_1_ack_in, ap_enable_reg_pp0_iter1, ap_enable_reg_pp0_iter2, exitcond3_i_fu_99_p2, ap_enable_reg_pp0_iter0, ap_block_pp0_stage0_subdone, ap_CS_fsm_state6)
    begin
        case ap_CS_fsm is
            when ap_ST_fsm_state1 => 
                if ((not(((ap_start = ap_const_logic_0) or (output_size_empty_n = ap_const_logic_0) or (ap_done_reg = ap_const_logic_1))) and (ap_const_logic_1 = ap_CS_fsm_state1))) then
                    ap_NS_fsm <= ap_ST_fsm_state2;
                else
                    ap_NS_fsm <= ap_ST_fsm_state1;
                end if;
            when ap_ST_fsm_state2 => 
                ap_NS_fsm <= ap_ST_fsm_pp0_stage0;
            when ap_ST_fsm_pp0_stage0 => 
                if ((not(((exitcond3_i_fu_99_p2 = ap_const_lv1_1) and (ap_const_boolean_0 = ap_block_pp0_stage0_subdone) and (ap_enable_reg_pp0_iter1 = ap_const_logic_0) and (ap_enable_reg_pp0_iter0 = ap_const_logic_1))) and not(((ap_const_boolean_0 = ap_block_pp0_stage0_subdone) and (ap_enable_reg_pp0_iter1 = ap_const_logic_0) and (ap_enable_reg_pp0_iter2 = ap_const_logic_1))))) then
                    ap_NS_fsm <= ap_ST_fsm_pp0_stage0;
                elsif ((((exitcond3_i_fu_99_p2 = ap_const_lv1_1) and (ap_const_boolean_0 = ap_block_pp0_stage0_subdone) and (ap_enable_reg_pp0_iter1 = ap_const_logic_0) and (ap_enable_reg_pp0_iter0 = ap_const_logic_1)) or ((ap_const_boolean_0 = ap_block_pp0_stage0_subdone) and (ap_enable_reg_pp0_iter1 = ap_const_logic_0) and (ap_enable_reg_pp0_iter2 = ap_const_logic_1)))) then
                    ap_NS_fsm <= ap_ST_fsm_state6;
                else
                    ap_NS_fsm <= ap_ST_fsm_pp0_stage0;
                end if;
            when ap_ST_fsm_state6 => 
                if (((row_size_stream_V_1_ack_in = ap_const_logic_1) and (ap_const_logic_1 = ap_CS_fsm_state6))) then
                    ap_NS_fsm <= ap_ST_fsm_state1;
                else
                    ap_NS_fsm <= ap_ST_fsm_state6;
                end if;
            when others =>  
                ap_NS_fsm <= "XXXX";
        end case;
    end process;
    ap_CS_fsm_pp0_stage0 <= ap_CS_fsm(2);
    ap_CS_fsm_state1 <= ap_CS_fsm(0);
    ap_CS_fsm_state2 <= ap_CS_fsm(1);
    ap_CS_fsm_state6 <= ap_CS_fsm(3);
        ap_block_pp0_stage0 <= not((ap_const_boolean_1 = ap_const_boolean_1));

    ap_block_pp0_stage0_01001_assign_proc : process(rowptr_stream_V_data_0_vld_out, ap_enable_reg_pp0_iter1)
    begin
                ap_block_pp0_stage0_01001 <= ((rowptr_stream_V_data_0_vld_out = ap_const_logic_0) and (ap_enable_reg_pp0_iter1 = ap_const_logic_1));
    end process;


    ap_block_pp0_stage0_11001_assign_proc : process(rowptr_stream_V_data_0_vld_out, ap_enable_reg_pp0_iter1, ap_enable_reg_pp0_iter2, ap_block_state4_io, ap_block_state5_io)
    begin
                ap_block_pp0_stage0_11001 <= (((ap_const_boolean_1 = ap_block_state5_io) and (ap_enable_reg_pp0_iter2 = ap_const_logic_1)) or ((ap_enable_reg_pp0_iter1 = ap_const_logic_1) and ((rowptr_stream_V_data_0_vld_out = ap_const_logic_0) or (ap_const_boolean_1 = ap_block_state4_io))));
    end process;


    ap_block_pp0_stage0_subdone_assign_proc : process(rowptr_stream_V_data_0_vld_out, ap_enable_reg_pp0_iter1, ap_enable_reg_pp0_iter2, ap_block_state4_io, ap_block_state5_io)
    begin
                ap_block_pp0_stage0_subdone <= (((ap_const_boolean_1 = ap_block_state5_io) and (ap_enable_reg_pp0_iter2 = ap_const_logic_1)) or ((ap_enable_reg_pp0_iter1 = ap_const_logic_1) and ((rowptr_stream_V_data_0_vld_out = ap_const_logic_0) or (ap_const_boolean_1 = ap_block_state4_io))));
    end process;


    ap_block_state1_assign_proc : process(ap_start, ap_done_reg, output_size_empty_n)
    begin
                ap_block_state1 <= ((ap_start = ap_const_logic_0) or (output_size_empty_n = ap_const_logic_0) or (ap_done_reg = ap_const_logic_1));
    end process;

        ap_block_state3_pp0_stage0_iter0 <= not((ap_const_boolean_1 = ap_const_boolean_1));

    ap_block_state4_io_assign_proc : process(row_size_stream_V_1_ack_in, tmp_8_i_reg_160)
    begin
                ap_block_state4_io <= ((tmp_8_i_reg_160 = ap_const_lv1_0) and (row_size_stream_V_1_ack_in = ap_const_logic_0));
    end process;


    ap_block_state4_pp0_stage0_iter1_assign_proc : process(rowptr_stream_V_data_0_vld_out)
    begin
                ap_block_state4_pp0_stage0_iter1 <= (rowptr_stream_V_data_0_vld_out = ap_const_logic_0);
    end process;


    ap_block_state5_io_assign_proc : process(row_size_stream_V_1_ack_in, ap_reg_pp0_iter1_tmp_8_i_reg_160)
    begin
                ap_block_state5_io <= ((ap_reg_pp0_iter1_tmp_8_i_reg_160 = ap_const_lv1_0) and (row_size_stream_V_1_ack_in = ap_const_logic_0));
    end process;

        ap_block_state5_pp0_stage0_iter2 <= not((ap_const_boolean_1 = ap_const_boolean_1));

    ap_condition_pp0_exit_iter0_state3_assign_proc : process(exitcond3_i_fu_99_p2)
    begin
        if ((exitcond3_i_fu_99_p2 = ap_const_lv1_1)) then 
            ap_condition_pp0_exit_iter0_state3 <= ap_const_logic_1;
        else 
            ap_condition_pp0_exit_iter0_state3 <= ap_const_logic_0;
        end if; 
    end process;


    ap_done_assign_proc : process(ap_done_reg, row_size_stream_V_1_ack_in, ap_CS_fsm_state6)
    begin
        if (((row_size_stream_V_1_ack_in = ap_const_logic_1) and (ap_const_logic_1 = ap_CS_fsm_state6))) then 
            ap_done <= ap_const_logic_1;
        else 
            ap_done <= ap_done_reg;
        end if; 
    end process;

    ap_enable_pp0 <= (ap_idle_pp0 xor ap_const_logic_1);

    ap_idle_assign_proc : process(ap_start, ap_CS_fsm_state1)
    begin
        if (((ap_start = ap_const_logic_0) and (ap_const_logic_1 = ap_CS_fsm_state1))) then 
            ap_idle <= ap_const_logic_1;
        else 
            ap_idle <= ap_const_logic_0;
        end if; 
    end process;


    ap_idle_pp0_assign_proc : process(ap_enable_reg_pp0_iter1, ap_enable_reg_pp0_iter2, ap_enable_reg_pp0_iter0)
    begin
        if (((ap_enable_reg_pp0_iter0 = ap_const_logic_0) and (ap_enable_reg_pp0_iter2 = ap_const_logic_0) and (ap_enable_reg_pp0_iter1 = ap_const_logic_0))) then 
            ap_idle_pp0 <= ap_const_logic_1;
        else 
            ap_idle_pp0 <= ap_const_logic_0;
        end if; 
    end process;


    ap_ready_assign_proc : process(row_size_stream_V_1_ack_in, ap_CS_fsm_state6)
    begin
        if (((row_size_stream_V_1_ack_in = ap_const_logic_1) and (ap_const_logic_1 = ap_CS_fsm_state6))) then 
            ap_ready <= ap_const_logic_1;
        else 
            ap_ready <= ap_const_logic_0;
        end if; 
    end process;

    exitcond3_i_fu_99_p2 <= "1" when (i2_i_reg_83 = tmp_7_i_reg_146) else "0";
    i_fu_104_p2 <= std_logic_vector(unsigned(i2_i_reg_83) + unsigned(ap_const_lv32_1));

    output_size_blk_n_assign_proc : process(ap_start, ap_done_reg, ap_CS_fsm_state1, output_size_empty_n)
    begin
        if ((not(((ap_start = ap_const_logic_0) or (ap_done_reg = ap_const_logic_1))) and (ap_const_logic_1 = ap_CS_fsm_state1))) then 
            output_size_blk_n <= output_size_empty_n;
        else 
            output_size_blk_n <= ap_const_logic_1;
        end if; 
    end process;


    output_size_read_assign_proc : process(ap_start, ap_done_reg, ap_CS_fsm_state1, output_size_empty_n)
    begin
        if ((not(((ap_start = ap_const_logic_0) or (output_size_empty_n = ap_const_logic_0) or (ap_done_reg = ap_const_logic_1))) and (ap_const_logic_1 = ap_CS_fsm_state1))) then 
            output_size_read <= ap_const_logic_1;
        else 
            output_size_read <= ap_const_logic_0;
        end if; 
    end process;

    row_size_stream_V_1_ack_in <= row_size_stream_V_1_state(1);
    row_size_stream_V_1_ack_out <= row_size_stream_V_TREADY;

    row_size_stream_V_1_data_out_assign_proc : process(row_size_stream_V_1_payload_A, row_size_stream_V_1_payload_B, row_size_stream_V_1_sel)
    begin
        if ((row_size_stream_V_1_sel = ap_const_logic_1)) then 
            row_size_stream_V_1_data_out <= row_size_stream_V_1_payload_B;
        else 
            row_size_stream_V_1_data_out <= row_size_stream_V_1_payload_A;
        end if; 
    end process;

    row_size_stream_V_1_load_A <= (row_size_stream_V_1_state_cmp_full and not(row_size_stream_V_1_sel_wr));
    row_size_stream_V_1_load_B <= (row_size_stream_V_1_state_cmp_full and row_size_stream_V_1_sel_wr);
    row_size_stream_V_1_sel <= row_size_stream_V_1_sel_rd;
    row_size_stream_V_1_state_cmp_full <= '0' when (row_size_stream_V_1_state = ap_const_lv2_1) else '1';

    row_size_stream_V_1_vld_in_assign_proc : process(ap_CS_fsm_pp0_stage0, ap_enable_reg_pp0_iter1, tmp_8_i_reg_160, ap_block_pp0_stage0_11001)
    begin
        if (((tmp_8_i_reg_160 = ap_const_lv1_0) and (ap_const_boolean_0 = ap_block_pp0_stage0_11001) and (ap_enable_reg_pp0_iter1 = ap_const_logic_1) and (ap_const_logic_1 = ap_CS_fsm_pp0_stage0))) then 
            row_size_stream_V_1_vld_in <= ap_const_logic_1;
        else 
            row_size_stream_V_1_vld_in <= ap_const_logic_0;
        end if; 
    end process;

    row_size_stream_V_1_vld_out <= row_size_stream_V_1_state(0);
    row_size_stream_V_TDATA <= row_size_stream_V_1_data_out;

    row_size_stream_V_TDATA_blk_n_assign_proc : process(row_size_stream_V_1_state, ap_CS_fsm_pp0_stage0, ap_enable_reg_pp0_iter1, ap_block_pp0_stage0, tmp_8_i_reg_160, ap_enable_reg_pp0_iter2, ap_reg_pp0_iter1_tmp_8_i_reg_160)
    begin
        if ((((ap_reg_pp0_iter1_tmp_8_i_reg_160 = ap_const_lv1_0) and (ap_const_boolean_0 = ap_block_pp0_stage0) and (ap_enable_reg_pp0_iter2 = ap_const_logic_1)) or ((tmp_8_i_reg_160 = ap_const_lv1_0) and (ap_const_boolean_0 = ap_block_pp0_stage0) and (ap_enable_reg_pp0_iter1 = ap_const_logic_1) and (ap_const_logic_1 = ap_CS_fsm_pp0_stage0)))) then 
            row_size_stream_V_TDATA_blk_n <= row_size_stream_V_1_state(1);
        else 
            row_size_stream_V_TDATA_blk_n <= ap_const_logic_1;
        end if; 
    end process;

    row_size_stream_V_TVALID <= row_size_stream_V_1_state(0);

    rowptr_stream_TDATA_blk_n_assign_proc : process(rowptr_stream_V_data_0_state, ap_CS_fsm_pp0_stage0, ap_enable_reg_pp0_iter1, ap_block_pp0_stage0)
    begin
        if (((ap_const_boolean_0 = ap_block_pp0_stage0) and (ap_enable_reg_pp0_iter1 = ap_const_logic_1) and (ap_const_logic_1 = ap_CS_fsm_pp0_stage0))) then 
            rowptr_stream_TDATA_blk_n <= rowptr_stream_V_data_0_state(0);
        else 
            rowptr_stream_TDATA_blk_n <= ap_const_logic_1;
        end if; 
    end process;

    rowptr_stream_TREADY <= rowptr_stream_V_last_0_state(1);
    rowptr_stream_V_data_0_ack_in <= rowptr_stream_V_data_0_state(1);

    rowptr_stream_V_data_0_ack_out_assign_proc : process(ap_CS_fsm_pp0_stage0, ap_enable_reg_pp0_iter1, ap_block_pp0_stage0_11001)
    begin
        if (((ap_const_boolean_0 = ap_block_pp0_stage0_11001) and (ap_enable_reg_pp0_iter1 = ap_const_logic_1) and (ap_const_logic_1 = ap_CS_fsm_pp0_stage0))) then 
            rowptr_stream_V_data_0_ack_out <= ap_const_logic_1;
        else 
            rowptr_stream_V_data_0_ack_out <= ap_const_logic_0;
        end if; 
    end process;


    rowptr_stream_V_data_0_data_out_assign_proc : process(rowptr_stream_V_data_0_payload_A, rowptr_stream_V_data_0_payload_B, rowptr_stream_V_data_0_sel)
    begin
        if ((rowptr_stream_V_data_0_sel = ap_const_logic_1)) then 
            rowptr_stream_V_data_0_data_out <= rowptr_stream_V_data_0_payload_B;
        else 
            rowptr_stream_V_data_0_data_out <= rowptr_stream_V_data_0_payload_A;
        end if; 
    end process;

    rowptr_stream_V_data_0_load_A <= (rowptr_stream_V_data_0_state_cmp_full and not(rowptr_stream_V_data_0_sel_wr));
    rowptr_stream_V_data_0_load_B <= (rowptr_stream_V_data_0_state_cmp_full and rowptr_stream_V_data_0_sel_wr);
    rowptr_stream_V_data_0_sel <= rowptr_stream_V_data_0_sel_rd;
    rowptr_stream_V_data_0_state_cmp_full <= '0' when (rowptr_stream_V_data_0_state = ap_const_lv2_1) else '1';
    rowptr_stream_V_data_0_vld_in <= rowptr_stream_TVALID;
    rowptr_stream_V_data_0_vld_out <= rowptr_stream_V_data_0_state(0);

    rowptr_stream_V_last_0_ack_out_assign_proc : process(ap_CS_fsm_pp0_stage0, ap_enable_reg_pp0_iter1, ap_block_pp0_stage0_11001)
    begin
        if (((ap_const_boolean_0 = ap_block_pp0_stage0_11001) and (ap_enable_reg_pp0_iter1 = ap_const_logic_1) and (ap_const_logic_1 = ap_CS_fsm_pp0_stage0))) then 
            rowptr_stream_V_last_0_ack_out <= ap_const_logic_1;
        else 
            rowptr_stream_V_last_0_ack_out <= ap_const_logic_0;
        end if; 
    end process;

    rowptr_stream_V_last_0_vld_in <= rowptr_stream_TVALID;
    tmp_7_i_fu_94_p2 <= std_logic_vector(unsigned(output_size_read_reg_141) + unsigned(ap_const_lv32_1));
    tmp_8_i_fu_110_p2 <= "1" when (i2_i_reg_83 = ap_const_lv32_0) else "0";
    tmp_fu_128_p2 <= std_logic_vector(unsigned(rowptr_stream_V_data_0_data_out) - unsigned(end_val_tmp_data_fu_56));
end behav;
