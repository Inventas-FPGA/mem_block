library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;

library bitvis_vip_sbi;
use bitvis_vip_sbi.sbi_bfm_pkg.all;

library design_lib;

library test_lib;
use test_lib.mem_block_tb_pkg.all;

--hdlregression:tb
entity mem_block_tb is
  generic(
    GC_TESTCASE   : string  := "read_empty";
    GC_ADDR_WIDTH : natural := 8;
    GC_DATA_WIDTH : natural := 32
  );
end entity;

architecture tb_arch of mem_block_tb is
  constant C_SCOPE : string := "tb_seq";

  constant C_DATA_AAAA5555 : std_logic_vector(GC_DATA_WIDTH - 1 downto 0) := x"AAAA5555";
  constant C_DATA_12345678 : std_logic_vector(GC_DATA_WIDTH - 1 downto 0) := x"12345678";
  constant C_DATA_00000000 : std_logic_vector(GC_DATA_WIDTH - 1 downto 0) := x"00000000";
  constant C_DATA_FFFFFFFF : std_logic_vector(GC_DATA_WIDTH - 1 downto 0) := x"FFFFFFFF";
  constant C_DATA_DEADBEEF : std_logic_vector(GC_DATA_WIDTH - 1 downto 0) := x"DEADBEEF";
  constant C_DATA_CAFEBABE : std_logic_vector(GC_DATA_WIDTH - 1 downto 0) := x"CAFEBABE";

  signal clk : std_logic := '0';
  signal rst : std_logic := '0';

  signal sbi_if : t_sbi_if(
    addr(GC_ADDR_WIDTH - 1 downto 0),
    wdata(GC_DATA_WIDTH - 1 downto 0),
    rdata(GC_DATA_WIDTH - 1 downto 0)
  ) := init_sbi_if_signals(GC_ADDR_WIDTH, GC_DATA_WIDTH);

begin

  dut_inst : entity design_lib.mem_block
    generic map(
      GC_ADDR_WIDTH => GC_ADDR_WIDTH,
      GC_DATA_WIDTH => GC_DATA_WIDTH
    )
    port map(
      clk   => clk,
      rst   => rst,
      cs    => sbi_if.cs,
      wena  => sbi_if.wena,
      rena  => sbi_if.rena,
      addr  => sbi_if.addr,
      wdata => sbi_if.wdata,
      rdata => sbi_if.rdata,
      ready => sbi_if.ready
    );

  p_clk : process
  begin
    while true loop
      clk <= '0';
      wait for C_CLK_PERIOD / 2;
      clk <= '1';
      wait for C_CLK_PERIOD / 2;
    end loop;
  end process;

  p_main_seq : process
    variable v_addr     : unsigned(GC_ADDR_WIDTH - 1 downto 0);
    variable v_wdata    : std_logic_vector(GC_DATA_WIDTH - 1 downto 0);
    variable v_exp_data : std_logic_vector(GC_DATA_WIDTH - 1 downto 0);
  begin
    rst <= '1';
    wait for 2 * C_CLK_PERIOD;
    rst <= '0';
    wait for 2 * C_CLK_PERIOD;

    log(ID_LOG_HDR, "TC: " & GC_TESTCASE, C_SCOPE);

    if GC_TESTCASE = "read_empty" then
      for idx in 0 to (2**GC_ADDR_WIDTH - 1) loop
        v_addr := to_unsigned(idx, v_addr'length);
        v_exp_data := (others => '0');

        sbi_check(
          addr_value   => v_addr,
          data_exp     => v_exp_data,
          msg          => "Check empty mem",
          clk          => clk,
          sbi_if       => sbi_if,
          alert_level  => ERROR,
          scope        => C_SCOPE,
          msg_id_panel => shared_msg_id_panel,
          config       => C_SBI_BFM_CONFIG
        );
      end loop;

    elsif GC_TESTCASE = "write_and_overwrite" then
      v_addr := to_unsigned(5, v_addr'length);

      sbi_write(
        addr_value   => v_addr,
        data_value   => C_DATA_AAAA5555,
        msg          => "Write first value",
        clk          => clk,
        sbi_if       => sbi_if,
        scope        => C_SCOPE,
        msg_id_panel => shared_msg_id_panel,
        config       => C_SBI_BFM_CONFIG
      );

      sbi_check(
        addr_value   => v_addr,
        data_exp     => C_DATA_AAAA5555,
        msg          => "Check first value",
        clk          => clk,
        sbi_if       => sbi_if,
        alert_level  => ERROR,
        scope        => C_SCOPE,
        msg_id_panel => shared_msg_id_panel,
        config       => C_SBI_BFM_CONFIG
      );

      sbi_write(
        addr_value   => v_addr,
        data_value   => C_DATA_12345678,
        msg          => "Overwrite value",
        clk          => clk,
        sbi_if       => sbi_if,
        scope        => C_SCOPE,
        msg_id_panel => shared_msg_id_panel,
        config       => C_SBI_BFM_CONFIG
      );

      sbi_check(
        addr_value   => v_addr,
        data_exp     => C_DATA_12345678,
        msg          => "Check overwritten value",
        clk          => clk,
        sbi_if       => sbi_if,
        alert_level  => ERROR,
        scope        => C_SCOPE,
        msg_id_panel => shared_msg_id_panel,
        config       => C_SBI_BFM_CONFIG
      );

    elsif GC_TESTCASE = "write_to_all_addresses" then
      for idx in 0 to (2**GC_ADDR_WIDTH - 1) loop
        v_addr := to_unsigned(idx, v_addr'length);
        v_wdata := std_logic_vector(to_unsigned(idx * 3 + 7, v_wdata'length));

        sbi_write(
          addr_value   => v_addr,
          data_value   => v_wdata,
          msg          => "Write to all",
          clk          => clk,
          sbi_if       => sbi_if,
          scope        => C_SCOPE,
          msg_id_panel => shared_msg_id_panel,
          config       => C_SBI_BFM_CONFIG
        );
      end loop;

      for idx in 0 to (2**GC_ADDR_WIDTH - 1) loop
        v_addr := to_unsigned(idx, v_addr'length);
        v_exp_data := std_logic_vector(to_unsigned(idx * 3 + 7, v_exp_data'length));

        sbi_check(
          addr_value   => v_addr,
          data_exp     => v_exp_data,
          msg          => "Check all",
          clk          => clk,
          sbi_if       => sbi_if,
          alert_level  => ERROR,
          scope        => C_SCOPE,
          msg_id_panel => shared_msg_id_panel,
          config       => C_SBI_BFM_CONFIG
        );
      end loop;

    elsif GC_TESTCASE = "write_max_and_min" then
      v_addr := to_unsigned(0, v_addr'length);

      sbi_write(
        addr_value   => v_addr,
        data_value   => C_DATA_00000000,
        msg          => "Write min",
        clk          => clk,
        sbi_if       => sbi_if,
        scope        => C_SCOPE,
        msg_id_panel => shared_msg_id_panel,
        config       => C_SBI_BFM_CONFIG
      );

      sbi_check(
        addr_value   => v_addr,
        data_exp     => C_DATA_00000000,
        msg          => "Check min",
        clk          => clk,
        sbi_if       => sbi_if,
        alert_level  => ERROR,
        scope        => C_SCOPE,
        msg_id_panel => shared_msg_id_panel,
        config       => C_SBI_BFM_CONFIG
      );

      v_addr := to_unsigned(1, v_addr'length);

      sbi_write(
        addr_value   => v_addr,
        data_value   => C_DATA_FFFFFFFF,
        msg          => "Write max",
        clk          => clk,
        sbi_if       => sbi_if,
        scope        => C_SCOPE,
        msg_id_panel => shared_msg_id_panel,
        config       => C_SBI_BFM_CONFIG
      );

      sbi_check(
        addr_value   => v_addr,
        data_exp     => C_DATA_FFFFFFFF,
        msg          => "Check max",
        clk          => clk,
        sbi_if       => sbi_if,
        alert_level  => ERROR,
        scope        => C_SCOPE,
        msg_id_panel => shared_msg_id_panel,
        config       => C_SBI_BFM_CONFIG
      );

    elsif GC_TESTCASE = "edge_addresses" then
      v_addr := to_unsigned(0, v_addr'length);

      sbi_write(
        addr_value   => v_addr,
        data_value   => C_DATA_DEADBEEF,
        msg          => "Write first addr",
        clk          => clk,
        sbi_if       => sbi_if,
        scope        => C_SCOPE,
        msg_id_panel => shared_msg_id_panel,
        config       => C_SBI_BFM_CONFIG
      );

      sbi_check(
        addr_value   => v_addr,
        data_exp     => C_DATA_DEADBEEF,
        msg          => "Check first addr",
        clk          => clk,
        sbi_if       => sbi_if,
        alert_level  => ERROR,
        scope        => C_SCOPE,
        msg_id_panel => shared_msg_id_panel,
        config       => C_SBI_BFM_CONFIG
      );

      v_addr := to_unsigned((2**GC_ADDR_WIDTH) - 1, v_addr'length);

      sbi_write(
        addr_value   => v_addr,
        data_value   => C_DATA_CAFEBABE,
        msg          => "Write last addr",
        clk          => clk,
        sbi_if       => sbi_if,
        scope        => C_SCOPE,
        msg_id_panel => shared_msg_id_panel,
        config       => C_SBI_BFM_CONFIG
      );

      sbi_check(
        addr_value   => v_addr,
        data_exp     => C_DATA_CAFEBABE,
        msg          => "Check last addr",
        clk          => clk,
        sbi_if       => sbi_if,
        alert_level  => ERROR,
        scope        => C_SCOPE,
        msg_id_panel => shared_msg_id_panel,
        config       => C_SBI_BFM_CONFIG
      );

    elsif GC_TESTCASE = "random_write_and_read" then
      for idx in 1 to 5 loop
        v_wdata := random(GC_DATA_WIDTH);
        v_addr  := unsigned(random(GC_ADDR_WIDTH));

        sbi_write(
          addr_value   => v_addr,
          data_value   => v_wdata,
          msg          => "Write random",
          clk          => clk,
          sbi_if       => sbi_if,
          scope        => C_SCOPE,
          msg_id_panel => shared_msg_id_panel,
          config       => C_SBI_BFM_CONFIG
        );

        sbi_check(
          addr_value   => v_addr,
          data_exp     => v_wdata,
          msg          => "Check random",
          clk          => clk,
          sbi_if       => sbi_if,
          alert_level  => ERROR,
          scope        => C_SCOPE,
          msg_id_panel => shared_msg_id_panel,
          config       => C_SBI_BFM_CONFIG
        );
      end loop;

    elsif GC_TESTCASE = "fast_back_to_back_access" then
      v_addr := to_unsigned(3, v_addr'length);

      for idx in 0 to 4 loop
        v_wdata := std_logic_vector(to_unsigned(idx * 11, v_wdata'length));

        sbi_write(
          addr_value   => v_addr,
          data_value   => v_wdata,
          msg          => "Write fast",
          clk          => clk,
          sbi_if       => sbi_if,
          scope        => C_SCOPE,
          msg_id_panel => shared_msg_id_panel,
          config       => C_SBI_BFM_CONFIG
        );

        sbi_check(
          addr_value   => v_addr,
          data_exp     => v_wdata,
          msg          => "Check fast",
          clk          => clk,
          sbi_if       => sbi_if,
          alert_level  => ERROR,
          scope        => C_SCOPE,
          msg_id_panel => shared_msg_id_panel,
          config       => C_SBI_BFM_CONFIG
        );
      end loop;

    else
      alert(TB_ERROR, "Unknown TC: " & GC_TESTCASE);
    end if;

    wait for 1000 ns;
    report_alert_counters(FINAL);
    log(ID_LOG_HDR, "SIMULATION COMPLETED", C_SCOPE);
    std.env.finish;
    wait;
  end process p_main_seq;

end architecture tb_arch;