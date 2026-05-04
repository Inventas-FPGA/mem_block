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
entity mem_block_ent_tb is
    generic(
        GC_TESTCASE   : string  := "UVVM";
        GC_ADDR_WIDTH : natural := 8;
        GC_DATA_WIDTH : natural := 32
    );
end entity mem_block_ent_tb;