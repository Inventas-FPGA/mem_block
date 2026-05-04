library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package mem_block_tb_pkg is
	-- Shared constants for testbench and testcases
    constant C_CLK_PERIOD      : time    := 10 ns;
    constant C_SBI_VVC_IDX     : natural := 1;
    constant C_CLK_GEN_VVC_IDX : natural := 1;

	-- Add shared types, functions, or procedures here if needed

end package mem_block_tb_pkg;
