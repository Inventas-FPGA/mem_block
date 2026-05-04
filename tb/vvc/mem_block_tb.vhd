library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;

library uvvm_vvc_framework;
context uvvm_vvc_framework.vvc_framework_context;

library bitvis_vip_sbi;
context bitvis_vip_sbi.vvc_context;

library bitvis_vip_clock_generator;
context bitvis_vip_clock_generator.vvc_context;

library design_lib;

library test_lib;
use test_lib.mem_block_tb_pkg.all;

--hdlregression:tb
entity mem_block_tb is
    generic(
        GC_TESTCASE   : string  := "UVVM";
        GC_ADDR_WIDTH : natural := 8;
        GC_DATA_WIDTH : natural := 32
    );
end entity;

architecture tb_arch of mem_block_tb is
    constant C_SCOPE : string  := "tb_seq";

    signal clk : std_logic := '0';
    signal rst : std_logic := '0';
    signal sbi_if : t_sbi_if(addr(GC_ADDR_WIDTH - 1 downto 0),
                             wdata(GC_DATA_WIDTH - 1 downto 0),
                             rdata(GC_DATA_WIDTH - 1 downto 0));

                                                          


begin

    dut_inst : entity design_lib.mem_block
        generic map(
            GC_ADDR_WIDTH => GC_ADDR_WIDTH,
            GC_DATA_WIDTH => GC_DATA_WIDTH)
        port map(
            clk   => clk,
            rst   => rst,
            cs    => sbi_if.cs,
            wena  => sbi_if.wena,
            rena  => sbi_if.rena,
            addr  => sbi_if.addr,
            wdata => sbi_if.wdata,
            rdata => sbi_if.rdata,
            ready => sbi_if.ready );
            
    i_sbi_vvc : entity bitvis_vip_sbi.sbi_vvc
        generic map(
            GC_INSTANCE_IDX => C_SBI_VVC_IDX,
            GC_ADDR_WIDTH   => GC_ADDR_WIDTH,
            GC_DATA_WIDTH   => GC_DATA_WIDTH)
        port map(
            clk               => clk,
            sbi_vvc_master_if => sbi_if); 
            
    i_clock_generator_vvc : entity bitvis_vip_clock_generator.clock_generator_vvc
        generic map(
            GC_INSTANCE_IDX    => C_CLK_GEN_VVC_IDX,
            GC_CLOCK_NAME      => "Clock",
            GC_CLOCK_PERIOD    => C_CLK_PERIOD,
            GC_CLOCK_HIGH_TIME => C_CLK_PERIOD/2)
        port map(
            clk => clk);

    i_ti_uvvm_engine : entity uvvm_vvc_framework.ti_uvvm_engine;


    p_main_seq : process
        variable v_addr     : unsigned(GC_ADDR_WIDTH-1 downto 0);
        variable v_wdata    : std_logic_vector(GC_DATA_WIDTH-1 downto 0);
        variable v_exp_data : std_logic_vector(GC_DATA_WIDTH-1 downto 0);
    begin
        await_uvvm_initialization(VOID);

        start_clock(CLOCK_GENERATOR_VVCT, C_CLK_GEN_VVC_IDX, "Start clock", C_SCOPE);
        gen_pulse(rst, 2 * C_CLK_PERIOD, "Pulsed reset-signal for 2 x clk period", C_SCOPE);

        log(ID_LOG_HDR, "TC: " & GC_TESTCASE, C_SCOPE);
        

        if GC_TESTCASE = "read_empty" then
            log(ID_SEQUENCER, "Check all addresses are zero after reset", C_SCOPE);
            for idx in 0 to (2**GC_ADDR_WIDTH - 1) loop
                v_addr := to_unsigned(idx, v_addr'length);
                v_exp_data := (others => '0');
                sbi_check(SBI_VVCT, C_SBI_VVC_IDX, v_addr, v_exp_data, "Check empty mem", scope => C_SCOPE);
            end loop;

        elsif GC_TESTCASE = "write_and_overwrite" then
            log(ID_SEQUENCER, "Write to one address, then overwrite", C_SCOPE);
            v_addr := to_unsigned(5, v_addr'length);
            sbi_write(SBI_VVCT, C_SBI_VVC_IDX, v_addr, x"AAAA5555", "Write first value", C_SCOPE);
            sbi_check(SBI_VVCT, C_SBI_VVC_IDX, v_addr, x"AAAA5555", "Check first value", scope => C_SCOPE);
            sbi_write(SBI_VVCT, C_SBI_VVC_IDX, v_addr, x"12345678", "Overwrite value", C_SCOPE);
            sbi_check(SBI_VVCT, C_SBI_VVC_IDX, v_addr, x"12345678", "Check overwritten value", scope => C_SCOPE);

        elsif GC_TESTCASE = "write_to_all_addresses" then
            log(ID_SEQUENCER, "Write unique data to all addresses, then check", C_SCOPE);
            for idx in 0 to (2**GC_ADDR_WIDTH - 1) loop
                v_addr := to_unsigned(idx, v_addr'length);
                v_wdata := std_logic_vector(to_unsigned(idx * 3 + 7, v_wdata'length));
                sbi_write(SBI_VVCT, C_SBI_VVC_IDX, v_addr, v_wdata, "Write to all", C_SCOPE);
            end loop;
            for idx in 0 to (2**GC_ADDR_WIDTH - 1) loop
                v_addr := to_unsigned(idx, v_addr'length);
                v_exp_data := std_logic_vector(to_unsigned(idx * 3 + 7, v_exp_data'length));
                sbi_check(SBI_VVCT, C_SBI_VVC_IDX, v_addr, v_exp_data, "Check all", scope => C_SCOPE);
            end loop;

        elsif GC_TESTCASE = "write_max_and_min" then
            log(ID_SEQUENCER, "Write max and min values to a few addresses", C_SCOPE);
            v_addr := to_unsigned(0, v_addr'length);
            sbi_write(SBI_VVCT, C_SBI_VVC_IDX, v_addr, x"00000000", "Write min", C_SCOPE);
            sbi_check(SBI_VVCT, C_SBI_VVC_IDX, v_addr, x"00000000", "Check min", scope => C_SCOPE);
            v_addr := to_unsigned(1, v_addr'length);
            sbi_write(SBI_VVCT, C_SBI_VVC_IDX, v_addr, x"FFFFFFFF", "Write max", C_SCOPE);
            sbi_check(SBI_VVCT, C_SBI_VVC_IDX, v_addr, x"FFFFFFFF", "Check max", scope => C_SCOPE);

        elsif GC_TESTCASE = "edge_addresses" then
            log(ID_SEQUENCER, "Write/read first and last address", C_SCOPE);
            v_addr := to_unsigned(0, v_addr'length);
            sbi_write(SBI_VVCT, C_SBI_VVC_IDX, v_addr, x"DEADBEEF", "Write first addr", C_SCOPE);
            sbi_check(SBI_VVCT, C_SBI_VVC_IDX, v_addr, x"DEADBEEF", "Check first addr", scope => C_SCOPE);
            v_addr := to_unsigned((2**GC_ADDR_WIDTH)-1, v_addr'length);
            sbi_write(SBI_VVCT, C_SBI_VVC_IDX, v_addr, x"CAFEBABE", "Write last addr", C_SCOPE);
            sbi_check(SBI_VVCT, C_SBI_VVC_IDX, v_addr, x"CAFEBABE", "Check last addr", scope => C_SCOPE);

        elsif GC_TESTCASE = "random_write_and_read" then
            log(ID_SEQUENCER, "Write random data to random addresses, then check", C_SCOPE);
            for idx in 1 to 5 loop
                v_wdata := random(GC_DATA_WIDTH);
                v_addr := unsigned(random(GC_ADDR_WIDTH));
                sbi_write(SBI_VVCT, C_SBI_VVC_IDX, v_addr, v_wdata, "Write random", C_SCOPE);
                sbi_check(SBI_VVCT, C_SBI_VVC_IDX, v_addr, v_wdata, "Check random", scope => C_SCOPE);
            end loop;

        elsif GC_TESTCASE = "fast_back_to_back_access" then
            log(ID_SEQUENCER, "Write and read back-to-back to same address", C_SCOPE);
            v_addr := to_unsigned(3, v_addr'length);
            for idx in 0 to 4 loop
                v_wdata := std_logic_vector(to_unsigned(idx * 11, v_wdata'length));
                sbi_write(SBI_VVCT, C_SBI_VVC_IDX, v_addr, v_wdata, "Write fast", C_SCOPE);
                sbi_check(SBI_VVCT, C_SBI_VVC_IDX, v_addr, v_wdata, "Check fast", scope => C_SCOPE);
            end loop;

        else
            alert(TB_ERROR, "Unknown TC: " & GC_TESTCASE);
        end if;
        
        await_uvvm_completion(1 ms);
        
        wait for 1000 ns;
        report_alert_counters(FINAL);
        log(ID_LOG_HDR, "SIMULATION COMPLETED", C_SCOPE);
        std.env.stop; wait;
    end process p_main_seq;

end architecture tb_arch;
  

