library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library bitvis_vip_sbi;
use bitvis_vip_sbi.sbi_bfm_pkg.all;

package mem_block_tb_pkg is
  constant C_CLK_PERIOD     : time := 10 ns;
  constant C_SBI_BFM_CONFIG : t_sbi_bfm_config;
end package mem_block_tb_pkg;


package body mem_block_tb_pkg is

  function init_mem_block_sbi_bfm_config return t_sbi_bfm_config is
    variable v_config : t_sbi_bfm_config := C_SBI_BFM_CONFIG_DEFAULT;
  begin
    v_config.use_ready_signal := false;
    return v_config;
  end function init_mem_block_sbi_bfm_config;

  constant C_SBI_BFM_CONFIG : t_sbi_bfm_config := init_mem_block_sbi_bfm_config;

end package body mem_block_tb_pkg;