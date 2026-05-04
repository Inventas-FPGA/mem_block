library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mem_block is
  generic (
    GC_ADDR_WIDTH : natural := 8;
    GC_DATA_WIDTH : natural := 32
  );
  port (
    clk   : in  std_logic;
    rst   : in  std_logic;
    cs    : in  std_logic;
    wena  : in  std_logic;
    rena  : in std_logic;
    addr  : in  unsigned(GC_ADDR_WIDTH-1 downto 0);
    wdata : in  std_logic_vector(GC_DATA_WIDTH-1 downto 0);
    rdata : out std_logic_vector(GC_DATA_WIDTH-1 downto 0);
    ready : out std_logic
  );
end entity;

architecture rtl of mem_block is
  type mem_type is array (0 to 255) of std_logic_vector(31 downto 0);
  signal mem : mem_type := (others => (others => '0'));

  begin

    p_write : process(rst, clk) is
  begin
    if rst = '1' then
      mem <= (others => (others => '0'));
    elsif rising_edge(clk) then
      if cs = '1' and wena = '1' then
          mem(to_integer(unsigned(addr))) <= wdata; 
      end if;
    end if;
  end process p_write;

  p_read : process(rst, cs, rena) is
  begin
    if rst = '1' then
      rdata <= (others => '0');
    else
      if cs = '1' and rena = '1' then
          rdata <= mem(to_integer(unsigned(addr)));
      end if;
    end if;
  end process p_read;

  ready <= '1';

  end architecture;
