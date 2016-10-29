library ieee;
use ieee.std_logic_1164.all;
use std.TextIO.all;

----------------------------------------------------------------------
-- Nexys2 Testbench
--
-- This simple testbench is used to test the funcionality of
-- your circuit for the nexys2 lab.
-- 
-- Author: Mike Wirthlin, BYU
----------------------------------------------------------------------
entity nexys2_testbench is
  -- No ports needed for this testbench
end nexys2_testbench;

architecture testbench of nexys2_testbench is

  -- Declare intermediate signals to hook up to the component
  signal t_switches : std_logic_vector(7 downto 0) := (others => 'U');
  signal t_buttons : std_logic_vector(3 downto 0) := (others => 'U');
  signal t_leds : std_logic_vector(7 downto 0);

  -- Constant time for each test case
  constant INITIAL_WAIT_TIME : TIME := 100 ns;
  constant TEST_CASE_TIME : TIME := 200 ns;
  constant PROPAGATE_TIME : TIME := 1 ns;

  -- Helper procedure for checking output of circuit
  procedure check_output(switches : in std_logic_vector(7 downto 0);
                         buttons : in std_logic_vector(3 downto 0);
                         leds : in std_logic_vector(7 downto 0)) is
    variable L : line;
    variable expecting : std_logic_vector(7 downto 0);
  begin
    if buttons(0) = '1' then
      expecting := switches(0) & switches(7 downto 1);
    elsif buttons(1) = '1' then
      expecting := (not switches);
    elsif buttons(2) = '1' then
      expecting := switches(0) & switches(1) & switches(2) & switches(3) &
                   switches(4) & switches(5) & switches(6) & switches(7);
    elsif buttons(3) = '1' then
      expecting := switches(3 downto 0) & switches(7 downto 4); 
    else
      expecting := switches;
    end if;
    if (leds /= expecting) then
      write(L, string'("ERROR: expecting LED="));
      write(L, to_bitvector(expecting));
      write(L, string'(" actual="));
      write(L, to_bitvector(leds));
      write(L, string'(" at time="));
      write(L, NOW);
      writeline(output, L);
    end if;
  end;
  
  -- component declaration of top-level design.
  component nexys2 
	 port (
		sw : in  std_logic_vector(7 downto 0);
		btn : in  std_logic_vector(3 downto 0);
		led : out std_logic_vector(7 downto 0)
	);
	end component;

begin

  -- instance the component
  -- NOTE: if you did not use the same entity name or signal names in your
  -- nexys2.vhd file, you will need to modify this component
  -- declaration to match your names.
  uut: nexys2
         port map( sw => t_switches,
                   btn => t_buttons,
                   led => t_leds
                   );

  -- testbench Test cases
  process
    variable L : line;     -- declare a 'line' for output
  begin

    -- Uninitialized case
    wait for INITIAL_WAIT_TIME;

    --------------------------------------------------
    t_switches <= "00000000";
    t_buttons <= "0000";
    wait for PROPAGATE_TIME;
    check_output(t_switches, t_buttons, t_leds);
    wait for TEST_CASE_TIME;

    --------------------------------------------------
    t_switches <= "10101010";
    t_buttons <= "0000";
    wait for PROPAGATE_TIME;
    check_output(t_switches, t_buttons, t_leds);
    wait for TEST_CASE_TIME;

    --------------------------------------------------
    t_switches <= "10101010";
    t_buttons <= "0001";
    wait for PROPAGATE_TIME;
    check_output(t_switches, t_buttons, t_leds);
    wait for TEST_CASE_TIME;

    --------------------------------------------------
    t_switches <= "00001111";
    t_buttons <= "0001";
    wait for PROPAGATE_TIME;
    check_output(t_switches, t_buttons, t_leds);
    wait for TEST_CASE_TIME;
    
    --------------------------------------------------
    t_switches <= "00001111";
    t_buttons <= "0010";
    wait for PROPAGATE_TIME;
    check_output(t_switches, t_buttons, t_leds);
    wait for TEST_CASE_TIME;

    --------------------------------------------------
    t_switches <= "10101010";
    t_buttons <= "0011";
    wait for PROPAGATE_TIME;
    check_output(t_switches, t_buttons, t_leds);
    wait for TEST_CASE_TIME;

    --------------------------------------------------
    t_switches <= "10100000";
    t_buttons <= "0100";
    wait for PROPAGATE_TIME;
    check_output(t_switches, t_buttons, t_leds);
    wait for TEST_CASE_TIME;

    --------------------------------------------------
    t_switches <= "10100000";
    t_buttons <= "0101";
    wait for PROPAGATE_TIME;
    check_output(t_switches, t_buttons, t_leds);
    wait for TEST_CASE_TIME;

    --------------------------------------------------
    t_switches <= "00111100";
    t_buttons <= "0110";
    wait for PROPAGATE_TIME;
    check_output(t_switches, t_buttons, t_leds);
    wait for TEST_CASE_TIME;

    --------------------------------------------------
    t_switches <= "00111100";
    t_buttons <= "0111";
    wait for PROPAGATE_TIME;
    check_output(t_switches, t_buttons, t_leds);
    wait for TEST_CASE_TIME;

    --------------------------------------------------
    t_switches <= "01101001";
    t_buttons <= "1000";
    wait for PROPAGATE_TIME;
    check_output(t_switches, t_buttons, t_leds);
    wait for TEST_CASE_TIME;

    --------------------------------------------------
    t_switches <= "01101001";
    t_buttons <= "1001";
    wait for PROPAGATE_TIME;
    check_output(t_switches, t_buttons, t_leds);
    wait for TEST_CASE_TIME;

    --------------------------------------------------
    t_switches <= "10110110";
    t_buttons <= "1010";
    wait for PROPAGATE_TIME;
    check_output(t_switches, t_buttons, t_leds);
    wait for TEST_CASE_TIME;

    --------------------------------------------------
    t_switches <= "00101101";
    t_buttons <= "1011";
    wait for PROPAGATE_TIME;
    check_output(t_switches, t_buttons, t_leds);
    wait for TEST_CASE_TIME;

    --------------------------------------------------
    t_switches <= "00101101";
    t_buttons <= "1100";
    wait for PROPAGATE_TIME;
    check_output(t_switches, t_buttons, t_leds);
    wait for TEST_CASE_TIME;

    --------------------------------------------------
    t_switches <= "11010111";
    t_buttons <= "1100";
    wait for PROPAGATE_TIME;
    check_output(t_switches, t_buttons, t_leds);
    wait for TEST_CASE_TIME;

    --------------------------------------------------
    t_switches <= "11010111";
    t_buttons <= "1101";
    wait for PROPAGATE_TIME;
    check_output(t_switches, t_buttons, t_leds);
    wait for TEST_CASE_TIME;

    --------------------------------------------------
    t_switches <= "11010111";
    t_buttons <= "1110";
    wait for PROPAGATE_TIME;
    check_output(t_switches, t_buttons, t_leds);
    wait for TEST_CASE_TIME;

    --------------------------------------------------
    t_switches <= "00000000";
    t_buttons <= "1111";
    wait for PROPAGATE_TIME;
    check_output(t_switches, t_buttons, t_leds);
    wait for TEST_CASE_TIME;

    --------------------------------------------------
 
	    t_switches <= "11101000";
    t_buttons <= "1010";
    wait for PROPAGATE_TIME;
    check_output(t_switches, t_buttons, t_leds);
    wait for TEST_CASE_TIME;
    --------------------------------------------------
    -- Done!
    --------------------------------------------------
    write(L, string'("Simuation Done at time "));
    write(L, NOW);
    writeline(output, L);
     
    -- end the test sequence
    wait;
  end process;
  
  
end testbench;