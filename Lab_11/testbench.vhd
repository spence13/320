--------------------------------------------
--
-- Testbench for SRAM controller lab
--
--------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library std;
use std.textio.all;

entity tb_frameBuffer is
end tb_frameBuffer;

architecture tb of tb_frameBuffer is
  signal sram_ce, sram_we, sram_oe, sram_ub, sram_lb, sram_adv,
     sram_cre, sram_clk: std_logic;
  signal clk : std_logic := '0';
  signal tb_hs, tb_vs : std_logic;
  signal tb_btn0 : std_logic; --std_logic_vector(3 downto 0);
  signal tb_sw : std_logic_vector(4 downto 0); --(7 downto 0);
  signal tb_vgared, tb_vgagreen : std_logic_vector(2 downto 0);
  signal tb_vgablue : std_logic_vector(1 downto 0);
  signal tb_color : std_logic_vector(7 downto 0);
  signal sram_addr : std_logic_vector(22 downto 0);
  signal sram_data : std_logic_vector(15 downto 0);
  
  -- Memory Test Cases
  type MEMORY_TEST_TYPE is record
    addr : std_logic_vector(22 downto 0);
    data : std_logic_vector(15 downto 0);
  end record;
  type MEMORY_TESTS_TYPE is array(natural range <>) of MEMORY_TEST_TYPE;

  constant CLK_RATE : natural := 50_000_000;
  constant CLK_PERIOD : time := 1000 ms / CLK_RATE;
  constant HALF_CLOCK_PERIOD : time := CLK_PERIOD / 2;
  
begin

  -- clock generator
  clk <= not clk after HALF_CLOCK_PERIOD;

  -- Test process. This process will call the read_mem and write_mem
  -- functions to perform a number of reads and writes on the sram.
  process
    variable pass_tests : boolean := true;
    variable L : LINE;
  begin

    -- Initial wait
    wait for 100 ns; 

    tb_btn0 <= '1';
    tb_sw <= (others => '0');
    write(L, string'("Press button 0 - issue reset"));
    writeline(output, L);

    wait for 100 ns; 

    tb_btn0 <= '0';
    wait for 100 ns;

    write(L, string'("Testbench will simulate a full VGA frame at image 0"));
    writeline(output, L);

    wait until tb_vs'event and tb_vs = '0';

    write(L, string'("Testbench will simulate a full VGA frame at image 1"));
    write(L, NOW);
    writeline(output, L);
    tb_sw <= "00001";
    
    
    wait;
    
  end process;

  tb_color <= tb_vgaRed & tb_vgaGreen & tb_vgaBlue;
  
  -- Instance sram controller  
  fb : entity work.frameBuffer
    port map(
      clk => clk,
      btn0 => tb_btn0,
      sw => tb_sw,
      Hsync => tb_hs,
      Vsync => tb_vs,
      vgaRed => tb_vgaRed,
      vgaBlue => tb_vgaBlue,
      vgaGreen => tb_vgaGreen,
      MemAdr => sram_addr,
      RamCS => sram_ce,
      MemWR => sram_we,
      MemOE => sram_oe,
      RamUB => sram_ub,
      RamLB => sram_lb,
      MemDB => sram_data,
      RamADV => sram_adv,
      RamCRE => sram_cre,
      RamCLK => sram_clk
      );

  -- instance memory model
  memModel : entity work.cellram_checker
  port map (
    clk => sram_clk,
    adv_n => sram_adv,
    cre => sram_cre, 
    o_wait => open,
    ce_n => sram_ce,
    oe_n => sram_oe,
    we_n => sram_we,
    lb_n => sram_lb,
    ub_n => sram_ub,
    addr => sram_addr,
    dq => sram_data
    );
  
end tb;