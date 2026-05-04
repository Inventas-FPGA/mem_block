library ieee;
use ieee.std_logic_1164.all;

library uvvm_vvc_framework;
context uvvm_vvc_framework.vvc_framework_context;

library bitvis_vip_sbi;
context bitvis_vip_sbi.vvc_context;

library bitvis_vip_clock_generator;
context bitvis_vip_clock_generator.vvc_context;

library design_lib;

library test_lib;
use test_lib.mem_block_tb_pkg.all;

entity mem_block_th is
    generic(
        GC_ADDR_WIDTH : natural := 8;
        GC_DATA_WIDTH : natural := 32
    );
    port(
        clk : out std_logic;
        rst : out std_logic;
        sbi_if : out t_sbi_if(addr(GC_ADDR_WIDTH - 1 downto 0),
                             wdata(GC_DATA_WIDTH - 1 downto 0),
                             rdata(GC_DATA_WIDTH - 1 downto 0))
    );
end entity mem_block_th;

architecture th_arch of mem_block_th is

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

end architecture th_arch;
