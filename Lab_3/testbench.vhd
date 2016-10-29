library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.TextIO.all;

----------------------------------------------------------------------
-- Seven Segment Decode Testbench
--
-- This simple testbench is used to test the funcionality of
-- the seven segment decoder. This testbench will provide
-- a variety of inputs to see if your seven segment decoder
-- operates as specified by the laboratory instructions.
-- 
----------------------------------------------------------------------
entity seven_seg_decode_testbench is
  -- No ports needed for this testbench
end seven_seg_decode_testbench;

architecture testbench of seven_seg_decode_testbench is

  -- Declare intermediate signals to hook up to the component
  signal t_switches : std_logic_vector(7 downto 0) := (others => 'U');
  signal t_buttons : std_logic_vector(3 downto 0) := (others => 'U');
  signal t_segments : std_logic_vector(6 downto 0);
  signal t_dp_out : std_logic;
  signal t_an_out : std_logic_vector(3 downto 0);

  -- Constant time for each test case
  constant TEST_CASE_TIME : TIME := 200 ns;

  -- Component instantiation
  component seven_seg_decode
    port(
    sw : in std_logic_vector(7 downto 0);
    btn : in std_logic_vector(3 downto 0);
    seg : out std_logic_Vector(6 downto 0);
    dp : out std_logic;
    an : out std_logic_vector(3 downto 0)
    );
  end component;


  -- Procedure for checking the inputs (switches and buttons) and
  -- checking the outputs. This procedure will produce a message
  -- if the expected output is different from the actual output.
  procedure check_output(switches : in std_logic_vector(7 downto 0);
                         buttons : in std_logic_vector(3 downto 0);
                         segments : in std_logic_vector(6 downto 0);
                         dp : in std_logic;
                         anode : in std_logic_vector(3 downto 0)
								 ) is
    variable L : line;
	 variable expected_data_to_display : std_logic_vector(3 downto 0);
	 variable correct_segments : std_logic_vector(6 downto 0);
	 variable check_segments : boolean;
    variable expected_anode : std_logic_vector(3 downto 0);
	 variable expected_dp : std_logic;
	 variable printed_error : boolean;
	 
    -- Constants that indicate what the segments should be
    constant SEGMENT_0 : std_logic_vector(6 downto 0) := "1000000";
    constant SEGMENT_1 : std_logic_vector(6 downto 0) := "1111001";
    constant SEGMENT_2 : std_logic_vector(6 downto 0) := "0100100";
    constant SEGMENT_3 : std_logic_vector(6 downto 0) := "0110000";
    constant SEGMENT_4 : std_logic_vector(6 downto 0) := "0011001";
    constant SEGMENT_5 : std_logic_vector(6 downto 0) := "0010010";
    constant SEGMENT_6 : std_logic_vector(6 downto 0) := "0000010";
    constant SEGMENT_7 : std_logic_vector(6 downto 0) := "1111000";
    constant SEGMENT_8 : std_logic_vector(6 downto 0) := "0000000";
    constant SEGMENT_9 : std_logic_vector(6 downto 0) := "0010000";
    constant SEGMENT_A : std_logic_vector(6 downto 0) := "0001000";
    constant SEGMENT_B : std_logic_vector(6 downto 0) := "0000011";
    constant SEGMENT_C : std_logic_vector(6 downto 0) := "1000110";
    constant SEGMENT_D : std_logic_vector(6 downto 0) := "0100001";
    constant SEGMENT_E : std_logic_vector(6 downto 0) := "0000110";
    constant SEGMENT_F : std_logic_vector(6 downto 0) := "0001110";

  begin
	 check_segments := true;
	 printed_error := false;
	 
    if buttons(3) = '1' then
		expected_data_to_display := "1000"; -- 8
		expected_anode := "0000";  -- all anodes displayed
		expected_dp := '0';        -- assert dp
    elsif buttons(2) = '1' then
      check_segments := false; -- no need to check the display
		expected_anode := "1111";  -- all off
    else
	   expected_dp := '1';
		case buttons(1 downto 0) is
		  when "00" =>
			 expected_anode := "1110";
			 expected_data_to_display := switches(3 downto 0);
		  when "01" =>
			 expected_anode := "1101";
			 expected_data_to_display := switches(7 downto 4);
		  when "10" =>
			 expected_anode := "1011";
			 expected_data_to_display := switches(3 downto 0) xor switches(7 downto 4);
		  when others => -- "11"
			 expected_anode := "0111";
			 expected_data_to_display := switches(1 downto 0) & switches(3 downto 2);
		end case;
    end if;


    -- check to see if segments is correct
    case expected_data_to_display is
      when "0000" => correct_segments := SEGMENT_0;
      when "0001" => correct_segments := SEGMENT_1;
      when "0010" => correct_segments := SEGMENT_2;
      when "0011" => correct_segments := SEGMENT_3;
      when "0100" => correct_segments := SEGMENT_4;
      when "0101" => correct_segments := SEGMENT_5;
      when "0110" => correct_segments := SEGMENT_6;
      when "0111" => correct_segments := SEGMENT_7;
      when "1000" => correct_segments := SEGMENT_8;
      when "1001" => correct_segments := SEGMENT_9;
      when "1010" => correct_segments := SEGMENT_A;
      when "1011" => correct_segments := SEGMENT_B;
      when "1100" => correct_segments := SEGMENT_C;
      when "1101" => correct_segments := SEGMENT_D;
      when "1110" => correct_segments := SEGMENT_E;
      when others => correct_segments := SEGMENT_F;
    end case;

    if (anode /= expected_anode) then
      write(L, string'("ERROR: expecting ANODE="));
      write(L, to_bitvector(expected_anode));
      write(L, string'(" actual="));
      write(L, to_bitvector(anode));
		printed_error := true;
    end if;

    if (check_segments and correct_segments /= segments) then
      write(L, string'("ERROR: expecting SEGMENTS="));
      write(L, to_bitvector(correct_segments));
      write(L, string'(" actual="));
      write(L, to_bitvector(segments));
		printed_error := true;
    end if;

    if (check_segments and expected_dp /= dp) then
      write(L, string'("ERROR: expecting DP="));
      write(L, to_bit(expected_dp));
      write(L, string'(" actual="));
      write(L, to_bit(dp));
		printed_error := true;
    end if;

    if (printed_error) then
      write(L, string'(" at time="));
      write(L, NOW);
      writeline(output, L);
    end if;

	 	 
  end;

  
begin


  -- instance the component
  uut: seven_seg_decode
         port map( sw => t_switches,
                   btn => t_buttons,
                   seg => t_segments,
                   dp => t_dp_out,
                   an => t_an_out
                   );

  -- testbench Test cases
  process
    variable L : line;            -- declare a 'line' for output
  begin

    -- Uninitialized case
    wait for TEST_CASE_TIME;

    --------------------------------------------------
    -- Test Button 3 being pressed
	 --------------------------------------------------
    write(L, string'("--- Test Button 3 at time: "));
    write(L, NOW);
    writeline(output, L);
    t_buttons <= "1000";      -- Button 3 by itself
    t_switches <= "10101010";
    wait for TEST_CASE_TIME;
	 check_output(t_switches, t_buttons, t_segments, t_dp_out, t_an_out);
    wait for TEST_CASE_TIME;
    t_buttons <= "1100";
    t_switches <= "01010101";
    wait for TEST_CASE_TIME;
	 check_output(t_switches, t_buttons, t_segments, t_dp_out, t_an_out);
    wait for TEST_CASE_TIME;
    t_buttons <= "1110";		-- Button 3 & 2 & 1
    t_switches <= "00111100";
    wait for TEST_CASE_TIME;
	 check_output(t_switches, t_buttons, t_segments, t_dp_out, t_an_out);
    wait for TEST_CASE_TIME;
    t_buttons <= "1111";		-- All buttons being pressed
    t_switches <= "11000011";
    wait for TEST_CASE_TIME;
	 check_output(t_switches, t_buttons, t_segments, t_dp_out, t_an_out);
    wait for TEST_CASE_TIME;
	
    --------------------------------------------------
    -- Test Button 2 being pressed
	 --------------------------------------------------
    write(L, string'("--- Test Button 2 at time: "));
    write(L, NOW);
    writeline(output, L);
    
	 t_buttons <= "0100";
    t_switches <= "11111111";
    wait for TEST_CASE_TIME;
	 check_output(t_switches, t_buttons, t_segments, t_dp_out, t_an_out);

	 wait for TEST_CASE_TIME;
    t_buttons <= "1100";
    t_switches <= "00001111";
    wait for TEST_CASE_TIME;
	 check_output(t_switches, t_buttons, t_segments, t_dp_out, t_an_out);

    wait for TEST_CASE_TIME;
    t_buttons <= "1110";
    t_switches <= "11110000";
    wait for TEST_CASE_TIME;
	 check_output(t_switches, t_buttons, t_segments, t_dp_out, t_an_out);
    
    --------------------------------------------------
    -- Test Buttons 1&0 being pressed
	 --------------------------------------------------
    write(L, string'("--- Test segments with no buttons pressed at time: "));
    write(L, NOW);
    writeline(output, L);
    t_buttons <= "0000";
    wait for TEST_CASE_TIME;
	 -- Iterate through 32 different values of the switches (to cover all 16 cases of display)
	 for i in 0 to 31 loop
      t_switches <= std_logic_vector(to_unsigned(i,8));
      wait for TEST_CASE_TIME;
	   check_output(t_switches, t_buttons, t_segments, t_dp_out, t_an_out);
      wait for TEST_CASE_TIME;
	 end loop;

    write(L, string'("--- Test segments with button 0 pressed at time: "));
    write(L, NOW);
    writeline(output, L);
    t_buttons <= "0001";
    wait for TEST_CASE_TIME;
	 for i in 0 to 31 loop
      t_switches <= std_logic_vector(to_unsigned(i, 5)) & "110";
      wait for TEST_CASE_TIME;
	   check_output(t_switches, t_buttons, t_segments, t_dp_out, t_an_out);
      wait for TEST_CASE_TIME;
	 end loop;

    write(L, string'("--- Test segments with button 1 pressed at time: "));
    write(L, NOW);
    writeline(output, L);
    t_buttons <= "0010";
    wait for TEST_CASE_TIME;
	 for i in 0 to 15 loop
      t_switches <= std_logic_vector(to_unsigned(i, 4)) & std_logic_vector(to_unsigned((15-i), 4));
      wait for TEST_CASE_TIME;
	   check_output(t_switches, t_buttons, t_segments, t_dp_out, t_an_out);
      wait for TEST_CASE_TIME;
	 end loop;

    write(L, string'("--- Test segments with button 1 and button 0 pressed at time: "));
    write(L, NOW);
    writeline(output, L);
    t_buttons <= "0011";
    wait for TEST_CASE_TIME;
	 for i in 0 to 15 loop
      t_switches <= std_logic_vector(to_unsigned(i, 4)) & std_logic_vector(to_unsigned(i, 4));
      wait for TEST_CASE_TIME;
	   check_output(t_switches, t_buttons, t_segments, t_dp_out, t_an_out);
      wait for TEST_CASE_TIME;
	 end loop;
	 
    --------------------------------------------------
    -- Done!
    --------------------------------------------------
    write(L, string'("Simuation Done at time: "));
	 write(L, NOW);
    writeline(output, L);
    
    -- end the test sequence
    wait;

  end process;
  
  
end testbench;