architecture tc_write_to_all_addresses of mem_block_ent_tb is
    constant C_SCOPE : string  := "tb_seq";
    
    signal clk : std_logic := '0';
    signal rst : std_logic := '0';
    signal sbi_if : t_sbi_if(addr(GC_ADDR_WIDTH - 1 downto 0),
                             wdata(GC_DATA_WIDTH - 1 downto 0),
                             rdata(GC_DATA_WIDTH - 1 downto 0));

begin

    i_th : entity test_lib.mem_block_th
        generic map(
            GC_ADDR_WIDTH => GC_ADDR_WIDTH,
            GC_DATA_WIDTH => GC_DATA_WIDTH)
        port map(
            clk    => clk,
            rst    => rst,
            sbi_if => sbi_if);

    p_main_seq : process
        variable v_addr     : unsigned(GC_ADDR_WIDTH-1 downto 0);
        variable v_wdata    : std_logic_vector(GC_DATA_WIDTH-1 downto 0);
        variable v_exp_data : std_logic_vector(GC_DATA_WIDTH-1 downto 0);
    begin
        await_uvvm_initialization(VOID);

        start_clock(CLOCK_GENERATOR_VVCT, C_CLK_GEN_VVC_IDX, "Start clock", C_SCOPE);
        gen_pulse(rst, 2 * C_CLK_PERIOD, "Pulsed reset-signal for 2 x clk period", C_SCOPE);

        log(ID_LOG_HDR, "TC: " & GC_TESTCASE, C_SCOPE);
        
        -- Write unique data to all addresses, then check
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
        
        await_uvvm_completion(1 ms);
        
        wait for 1000 ns;
        report_alert_counters(FINAL);
        log(ID_LOG_HDR, "SIMULATION COMPLETED", C_SCOPE);
        std.env.stop; wait;
    end process p_main_seq;

end architecture tc_write_to_all_addresses;
  