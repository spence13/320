----------------------------------------------------------
-- Chip scope example
--
-- Version 1.0
--
-- Professor Mike Wirthlin
--
----------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity chipscope_example is
  port (
    clk : in std_logic
    );
end chipscope_example;

architecture sample_arch of chipscope_example is

  ---------------------------------------------------------------------
  -- Component instantionation for the ChipScope Controller (ICON)
  ---------------------------------------------------------------------
  component chipscope_icon
    port (
      CONTROL0 : inout std_logic_vector(35 downto 0)
    );
  end component;

  ---------------------------------------------------------------------
  -- Component instantionation for the ChipScope Internal Logic Analyzer
  ---------------------------------------------------------------------
  component chipscope_ila
    port (
      CONTROL	: inout std_logic_vector(35 downto 0);
      CLK	:  in  std_logic;
      TRIG0	:  in std_logic_vector(31 downto 0)
      );
  end component;

  --  Local Signals
  signal control : std_logic_vector(35 downto 0);
  signal counter : unsigned(31 downto 0) := (others => '0');
 
begin

  -------------------------------------------------------------------
  -- Sample Counter
  -------------------------------------------------------------------
  process(clk)
  begin
    if clk'event and clk='1' then
      counter <= counter + 1;
    end if;
  end process;

  -------------------------------------------------------------------
  --  ICON core instance
  -------------------------------------------------------------------
  ICON_inst:  chipscope_icon
    port map (
      CONTROL0 => control
    );
  
  -------------------------------------------------------------------
  --  ILA core instance
  -------------------------------------------------------------------
  ILA_inst : chipscope_ila
    port map (
      CONTROL	=> control,
      CLK	=> clk,	
      TRIG0	=> std_logic_vector(counter)
      );

end sample_arch;
