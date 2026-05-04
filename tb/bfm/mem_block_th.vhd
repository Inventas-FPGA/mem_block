library ieee;
use ieee.std_logic_1164.all;

library bitvis_vip_sbi;
use bitvis_vip_sbi.sbi_bfm_pkg.all;

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


end architecture th_arch;
