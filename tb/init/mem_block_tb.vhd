library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library design_lib;

--hdlregression:tb
entity mem_block_tb is
  generic(
    GC_TESTCASE   : string  := "read_empty";
    GC_ADDR_WIDTH : natural := 8;
    GC_DATA_WIDTH : natural := 32
  );
end entity;

architecture tb_arch of mem_block_tb is

  constant C_CLK_PERIOD : time := 10 ns;

  signal clk   : std_logic := '0';
  signal rst   : std_logic := '0';
  signal cs    : std_logic := '0';
  signal wena  : std_logic := '0';
  signal rena  : std_logic := '0';
  signal addr  : unsigned(GC_ADDR_WIDTH - 1 downto 0) := (others => '0');
  signal wdata : std_logic_vector(GC_DATA_WIDTH - 1 downto 0) := (others => '0');
  signal rdata : std_logic_vector(GC_DATA_WIDTH - 1 downto 0);
  signal ready : std_logic;

begin

  dut_inst : entity design_lib.mem_block
    generic map(
      GC_ADDR_WIDTH => GC_ADDR_WIDTH,
      GC_DATA_WIDTH => GC_DATA_WIDTH
    )
    port map(
      clk   => clk,
      rst   => rst,
      cs    => cs,
      wena  => wena,
      rena  => rena,
      addr  => addr,
      wdata => wdata,
      rdata => rdata,
      ready => ready
    );

  ------------------------------------------------------------------------------
  -- Clock generation
  ------------------------------------------------------------------------------
  p_clk : process
  begin
    while true loop
      clk <= '0';
      wait for C_CLK_PERIOD / 2;
      clk <= '1';
      wait for C_CLK_PERIOD / 2;
    end loop;
  end process;

  ------------------------------------------------------------------------------
  -- Main test process
  ------------------------------------------------------------------------------
  p_main : process
    variable v_addr     : unsigned(GC_ADDR_WIDTH - 1 downto 0);
    variable v_wdata    : std_logic_vector(GC_DATA_WIDTH - 1 downto 0);
    variable v_exp_data : std_logic_vector(GC_DATA_WIDTH - 1 downto 0);
  begin
    ----------------------------------------------------------------------------
    -- Init
    ----------------------------------------------------------------------------
    cs    <= '0';
    wena  <= '0';
    rena  <= '0';
    addr  <= (others => '0');
    wdata <= (others => '0');
    rst   <= '1';

    wait for 2 * C_CLK_PERIOD;
    wait until falling_edge(clk);
    rst <= '0';

    wait until falling_edge(clk);

    report "TC: " & GC_TESTCASE severity note;

    ----------------------------------------------------------------------------
    -- Testcases
    ----------------------------------------------------------------------------
    if GC_TESTCASE = "read_empty" then
      -- Read all addresses after reset, expect zero
      for idx in 0 to (2**GC_ADDR_WIDTH - 1) loop
        v_addr := to_unsigned(idx, v_addr'length);
        v_exp_data := (others => '0');

        wait until falling_edge(clk);
        addr <= v_addr;
        cs   <= '1';
        rena <= '1';
        wena <= '0';

        wait for 1 ns;

        assert rdata = v_exp_data
          report "read_empty failed at addr=" & integer'image(idx)
          severity failure;

        wait until falling_edge(clk);
        cs   <= '0';
        rena <= '0';
      end loop;

    elsif GC_TESTCASE = "write_and_overwrite" then
      v_addr := to_unsigned(5, v_addr'length);

      -- Write first value
      wait until falling_edge(clk);
      addr  <= v_addr;
      wdata <= x"AAAA5555";
      cs    <= '1';
      wena  <= '1';
      rena  <= '0';

      wait until rising_edge(clk);

      wait until falling_edge(clk);
      cs   <= '0';
      wena <= '0';

      -- Read and check first value
      wait until falling_edge(clk);
      addr <= v_addr;
      cs   <= '1';
      rena <= '1';
      wena <= '0';

      wait for 1 ns;

      assert rdata = x"AAAA5555"
        report "write_and_overwrite failed on first readback"
        severity failure;

      wait until falling_edge(clk);
      cs   <= '0';
      rena <= '0';

      -- Overwrite value
      wait until falling_edge(clk);
      addr  <= v_addr;
      wdata <= x"12345678";
      cs    <= '1';
      wena  <= '1';
      rena  <= '0';

      wait until rising_edge(clk);

      wait until falling_edge(clk);
      cs   <= '0';
      wena <= '0';

      -- Read and check overwritten value
      wait until falling_edge(clk);
      addr <= v_addr;
      cs   <= '1';
      rena <= '1';
      wena <= '0';

      wait for 1 ns;

      assert rdata = x"12345678"
        report "write_and_overwrite failed on overwrite readback"
        severity failure;

      wait until falling_edge(clk);
      cs   <= '0';
      rena <= '0';

    elsif GC_TESTCASE = "write_to_all_addresses" then
      -- Write unique data to all addresses
      for idx in 0 to (2**GC_ADDR_WIDTH - 1) loop
        v_addr := to_unsigned(idx, v_addr'length);
        v_wdata := std_logic_vector(to_unsigned(idx * 3 + 7, v_wdata'length));

        wait until falling_edge(clk);
        addr  <= v_addr;
        wdata <= v_wdata;
        cs    <= '1';
        wena  <= '1';
        rena  <= '0';

        wait until rising_edge(clk);

        wait until falling_edge(clk);
        cs   <= '0';
        wena <= '0';
      end loop;

      -- Read back and check
      for idx in 0 to (2**GC_ADDR_WIDTH - 1) loop
        v_addr := to_unsigned(idx, v_addr'length);
        v_exp_data := std_logic_vector(to_unsigned(idx * 3 + 7, v_exp_data'length));

        wait until falling_edge(clk);
        addr <= v_addr;
        cs   <= '1';
        rena <= '1';
        wena <= '0';

        wait for 1 ns;

        assert rdata = v_exp_data
          report "write_to_all_addresses failed at addr=" & integer'image(idx)
          severity failure;

        wait until falling_edge(clk);
        cs   <= '0';
        rena <= '0';
      end loop;

    elsif GC_TESTCASE = "write_max_and_min" then
      -- Write min
      v_addr := to_unsigned(0, v_addr'length);

      wait until falling_edge(clk);
      addr  <= v_addr;
      wdata <= x"00000000";
      cs    <= '1';
      wena  <= '1';
      rena  <= '0';

      wait until rising_edge(clk);

      wait until falling_edge(clk);
      cs   <= '0';
      wena <= '0';

      -- Check min
      wait until falling_edge(clk);
      addr <= v_addr;
      cs   <= '1';
      rena <= '1';
      wena <= '0';

      wait for 1 ns;

      assert rdata = x"00000000"
        report "write_max_and_min failed on min value"
        severity failure;

      wait until falling_edge(clk);
      cs   <= '0';
      rena <= '0';

      -- Write max
      v_addr := to_unsigned(1, v_addr'length);

      wait until falling_edge(clk);
      addr  <= v_addr;
      wdata <= x"FFFFFFFF";
      cs    <= '1';
      wena  <= '1';
      rena  <= '0';

      wait until rising_edge(clk);

      wait until falling_edge(clk);
      cs   <= '0';
      wena <= '0';

      -- Check max
      wait until falling_edge(clk);
      addr <= v_addr;
      cs   <= '1';
      rena <= '1';
      wena <= '0';

      wait for 1 ns;

      assert rdata = x"FFFFFFFF"
        report "write_max_and_min failed on max value"
        severity failure;

      wait until falling_edge(clk);
      cs   <= '0';
      rena <= '0';

    elsif GC_TESTCASE = "edge_addresses" then
      -- First address
      v_addr := to_unsigned(0, v_addr'length);

      wait until falling_edge(clk);
      addr  <= v_addr;
      wdata <= x"DEADBEEF";
      cs    <= '1';
      wena  <= '1';
      rena  <= '0';

      wait until rising_edge(clk);

      wait until falling_edge(clk);
      cs   <= '0';
      wena <= '0';

      wait until falling_edge(clk);
      addr <= v_addr;
      cs   <= '1';
      rena <= '1';
      wena <= '0';

      wait for 1 ns;

      assert rdata = x"DEADBEEF"
        report "edge_addresses failed on first address"
        severity failure;

      wait until falling_edge(clk);
      cs   <= '0';
      rena <= '0';

      -- Last address
      v_addr := to_unsigned((2**GC_ADDR_WIDTH) - 1, v_addr'length);

      wait until falling_edge(clk);
      addr  <= v_addr;
      wdata <= x"CAFEBABE";
      cs    <= '1';
      wena  <= '1';
      rena  <= '0';

      wait until rising_edge(clk);

      wait until falling_edge(clk);
      cs   <= '0';
      wena <= '0';

      wait until falling_edge(clk);
      addr <= v_addr;
      cs   <= '1';
      rena <= '1';
      wena <= '0';

      wait for 1 ns;

      assert rdata = x"CAFEBABE"
        report "edge_addresses failed on last address"
        severity failure;

      wait until falling_edge(clk);
      cs   <= '0';
      rena <= '0';

    elsif GC_TESTCASE = "random_write_and_read" then
      for idx in 1 to 5 loop
        v_wdata := std_logic_vector(to_unsigned(idx * 101 + 17, v_wdata'length));
        v_addr  := to_unsigned((idx * 7) mod (2**GC_ADDR_WIDTH), v_addr'length);

        -- Write
        wait until falling_edge(clk);
        addr  <= v_addr;
        wdata <= v_wdata;
        cs    <= '1';
        wena  <= '1';
        rena  <= '0';

        wait until rising_edge(clk);

        wait until falling_edge(clk);
        cs   <= '0';
        wena <= '0';

        -- Read back
        wait until falling_edge(clk);
        addr <= v_addr;
        cs   <= '1';
        rena <= '1';
        wena <= '0';

        wait for 1 ns;

        assert rdata = v_wdata
          report "random_write_and_read failed at iteration=" &
                 integer'image(idx)
          severity failure;

        wait until falling_edge(clk);
        cs   <= '0';
        rena <= '0';
      end loop;

    elsif GC_TESTCASE = "fast_back_to_back_access" then
      v_addr := to_unsigned(3, v_addr'length);

      for idx in 0 to 4 loop
        v_wdata := std_logic_vector(to_unsigned(idx * 11, v_wdata'length));

        -- Write
        wait until falling_edge(clk);
        addr  <= v_addr;
        wdata <= v_wdata;
        cs    <= '1';
        wena  <= '1';
        rena  <= '0';

        wait until rising_edge(clk);

        wait until falling_edge(clk);
        cs   <= '0';
        wena <= '0';

        -- Read
        wait until falling_edge(clk);
        addr <= v_addr;
        cs   <= '1';
        rena <= '1';
        wena <= '0';

        wait for 1 ns;

        assert rdata = v_wdata
          report "fast_back_to_back_access failed at iteration=" &
                 integer'image(idx)
          severity failure;

        wait until falling_edge(clk);
        cs   <= '0';
        rena <= '0';
      end loop;

    else
      assert false
        report "Unknown TC: " & GC_TESTCASE
        severity failure;
    end if;

    report "SIMULATION COMPLETED" severity note;
    std.env.finish;
    wait;
  end process;

end architecture tb_arch;