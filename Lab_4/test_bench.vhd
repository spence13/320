library ieee;
use ieee.std_logic_1164.all;
use std.TextIO.all;
use ieee.std_logic_textio.all; -- write, hwrite

----------------------------------------------------------------------
--
-- This testbench is used to test the functionality of
-- the seven segment display controller.
--
-- Author: Mike Wirthlin
--
-- Version: 1.4
--
----------------------------------------------------------------------
entity tb_seven_segment_control is
  -- No ports needed for this testbench
end tb_seven_segment_control;


architecture testbench of tb_seven_segment_control is
  signal data : std_logic_Vector(15 downto 0);
  signal tb_clk : std_logic := '0';
  signal dp : std_logic_vector(3 downto 0);
  signal segments : std_logic_vector(6 downto 0);
  signal dp_out : std_logic;
  signal t_an_out : std_logic_Vector(3 downto 0);
  signal tb_blank : std_logic_vector(3 downto 0);
  
  constant CLK_PERIOD : Time := 20 ns;
  constant HALF_CLK_PERIOD : Time := CLK_PERIOD / 2;
  constant DISPLAY_COUNTER_BITS : Integer := 15;
  -- 20 ns x 2^13 = 163.8us
  constant ANODE_ON_TIME : Time := CLK_PERIOD * (2**(DISPLAY_COUNTER_BITS-2));

  -- Component instantiation
  --
  -- Your entity must have the same component name and ports
  -- for this testbench to work properly.
  component seven_segment_control
    generic(
      COUNTER_BITS : Natural := 15
      );
    port(
      clk : in std_logic;
      data_in : in std_logic_vector(15 downto 0);
      dp_in : in std_logic_vector(3 downto 0);
      blank : in std_logic_vector(3 downto 0);
      seg : out std_logic_Vector(6 downto 0);
      dp : out std_logic;
      an : out std_logic_vector(3 downto 0)
      );
  end component;

  ----------------------------------------------------------------------
  -- This function looks at the inputs to the seven segment
  -- controller and makes sure that the appropriate segment
  -- signals and dp signals are asserted.
  ----------------------------------------------------------------------
  function check_segments(anode : std_logic_vector(3 downto 0);
                          segments : std_logic_vector(6 downto 0);
                          dp : std_logic;
                          dp_data : std_logic_Vector(3 downto 0);
                          display_data : std_logic_vector(15 downto 0))
    return boolean is

    variable L : line;
    variable data_to_segments : std_logic_vector(3 downto 0);
    variable data_to_dp : std_logic;
    variable correct_segments : std_logic_vector(6 downto 0);
	 variable valid_input : boolean := true;
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

    -- Determine what should be inputs to the decoder
    valid_input := true;
    case anode is
      when "0111" =>
        data_to_segments := display_data(15 downto 12);
        data_to_dp := dp_data(3);
      when "1011" =>
        data_to_segments := display_data(11 downto 8);
        data_to_dp := dp_data(2);
      when "1101" =>
        data_to_segments := display_data(7 downto 4);
        data_to_dp := dp_data(1);
      when "1110" =>
        data_to_segments := display_data(3 downto 0);
        data_to_dp := dp_data(0);
      when others =>
        valid_input := false;
    end case;

    -- check to see if segments is correct
    case data_to_segments is
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
      when "1111" => correct_segments := SEGMENT_F;
      when others => 
			valid_input := false;
    end case;

    if (valid_input and correct_Segments /= segments) then
      write(L, string'("Incorrect segments on display.  Expecting="));
      write(L, correct_segments);
      write(L, string'("  Received="));
      write(L, segments);
      write(L, string'("  Data to segments="));
      write(L, data_to_segments);
      write(L, string'("  at time:"));
      write(L, NOW);
      writeline(output, L);
    end if;

    -- check to see if DP is correct
    if (valid_input and (dp /= not data_to_dp)) then
      write(L, string'("Incorrect digit point.  Expecting="));
      write(L, not data_to_dp);
      write(L, string'("  Received="));
      write(L, dp);
      write(L, string'("  at time:"));
      write(L, NOW);
      writeline(output, L);
    end if;

    return TRUE;
  end;

  ----------------------------------------------------------------------
  -- This procedure will check the anode signal to make sure that
  -- one and only one anode is asserted at a time. It will also
  -- compare the anode against a "mask" that remembers which anodes
  -- have been asserted. If an anode is asserted again, an error
  -- message is generated. It also updates this mask.
  ----------------------------------------------------------------------
  procedure check_anode_mask(anode : in std_logic_vector(3 downto 0);
                             anode_mask : inout std_logic_vector(3 downto 0);
                             time_stamp : out time) is
    variable L : line;

  begin

    -- make sure only one anode is asserted
    assert (anode = "1110" or anode = "1101" or anode = "1011" or
            anode = "0111") report "More than one anode asserted";
    
    -- make sure that the asserted anode has not been
    -- asserted before (i.e., only once per cycle of 4)
    assert (anode_mask and (not (anode))) = "0000"
      report "Anode signal has been asserted before";
    -- Update mask (initial anode)
    anode_mask := anode_mask or (not (anode));

    --time_stamp := now;
    --write(L, string'("Anode "));
    --write(L, anode);
    --write(L, string'(" asserted at time:"));
    --write(L, now);
    --writeline(output, L);
                                              
  end;

  ----------------------------------------------------------------------
  -- Measures the amount of time since the last anode event and
  -- compares it against a known correct value. It displays the
  -- anode value and the amount of time the previous anode was
  -- asserted.
  ----------------------------------------------------------------------
  procedure check_anode_assert_time(anode : std_logic_vector(3 downto 0);
                            start_time : time;
                            ANODE_ON_TIME : time) is

    variable anode_assert_time : Time;
    variable L : line;
    
  begin

    anode_assert_time := NOW - start_time;
    assert anode_assert_time = ANODE_ON_TIME report "Invalid anode assertion time";
    if (anode_assert_time /= ANODE_ON_TIME) then
      write(L, string'("  Assertion time ="));
      write(L, anode_assert_time);
      write(L, string'(" Expecting:"));
      write(L, ANODE_ON_TIME);
      writeline(output, L);
    end if;
    
  end;

  
begin

  -------------------------------------------------------------------------
  -- seven segment display component instantiation
  --
  -- You may need to modify this to match your component
  -------------------------------------------------------------------------
  U1 : seven_segment_control
    generic map (
      COUNTER_BITS => DISPLAY_COUNTER_BITS
      )
    port map (
      clk => tb_clk,
      data_in => data,
      dp_in => dp,
      blank => tb_blank,
      seg => segments,
      dp => dp_out,
      an => t_an_out
    );

  -- clock generator
  tb_clk <= not tb_clk after HALF_CLK_PERIOD;
  

  -- Stimulus process
  process
    variable time_stamp : TIME;
    variable anode_assert_time : Time;
    variable L : line;
    variable anode_mask : std_logic_vector(3 downto 0) := "0000";
    variable temp_bool : boolean;
  begin

    write(L, string'("----- Start of Simulation -----"));
    writeline(output, L);

    --------------------------------------------------
    -- Begin with uninitalized inputs
    --------------------------------------------------
    dp <= (others => 'U');
    data <= (others => 'U');
    tb_blank <= (others => 'U');
    wait for 200 ns;

    --------------------------------------------------
    -- Test #1 - Measure the anode assertion time and make sure
    --           each anode is displayed for the correct amount of time
    --------------------------------------------------
    write(L, string'("Test #1 - Measure time of anode assertion and make sure all anodes asserted"));
    writeline(output, L);
    dp <= "0000";
    data <= X"8888";
    tb_blank <= (others => '0');

    -- Wait for the end of the current anode cycle. This cycle will be ignored.
    wait until t_an_out'event;
    
    -- Wait for anode event #1
    wait until t_an_out'event;
    check_anode_mask(t_an_out, anode_mask, time_stamp);
    time_stamp := NOW;
    
    -- Wait for anode event #2
    wait until t_an_out'event;
    check_anode_assert_time(t_an_out,time_stamp, ANODE_ON_TIME);
    check_anode_mask(t_an_out, anode_mask, time_stamp);
    time_stamp := NOW;

    -- wait for anode event #3
    wait until t_an_out'event;
    check_anode_assert_time(t_an_out,time_stamp, ANODE_ON_TIME);
    check_anode_mask(t_an_out, anode_mask, time_stamp);
    time_stamp := NOW;

    -- wait for anode event #4
    wait until t_an_out'event;
    check_anode_assert_time(t_an_out,time_stamp, ANODE_ON_TIME);
    check_anode_mask(t_an_out, anode_mask, time_stamp);
    time_stamp := NOW;

    -- wait for end of anode event #4
    wait until t_an_out'event;
    check_anode_assert_time(t_an_out,time_stamp, ANODE_ON_TIME);

    -- Check mask
    if (anode_mask = "1111") then
      write(L, string'("All anodes asserted Properly. End of test #1"));
      writeline(output, L);
    else
      write(L, string'("Not all anodes asserted: End of test #1"));
      write(L, anode_mask);
      writeline(output,L);
    end if;
      
    assert (anode_mask = "1111")
      report "Not all anodes were asserted in cycle";

    --------------------------------------------------
    -- Test #2 - Check all segment values
    --------------------------------------------------
    write(L, string'("Test #2 - Checking Segment Values"));
    writeline(output, L);
 
    -- Test 2a
    dp <= "0001";
    data <= X"0123";
    wait for ANODE_ON_TIME * 4;
    
    -- Test 2b
    dp <= "0010";
    data <= X"4567";
    wait for ANODE_ON_TIME * 4;

    -- Test 2c
    dp <= "0100";
    data <= X"89AB";
    wait for ANODE_ON_TIME * 4;

    -- Test 2d
    dp <= "1000";
    data <= X"CDEF";
    wait for ANODE_ON_TIME * 4;

    --------------------------------------------------
    -- Test #3 - Check for blanking
    --------------------------------------------------
    write(L, string'("Test #3 - Check for blanking"));
    writeline(output, L);

    for i in 0 to 3 loop
      for j in 0 to 3 loop
        if j=i then
          tb_blank(j) <= '1';
        else
          tb_blank(j) <= '0';
        end if;
      end loop;
      -- wait for a full cycle of digit display
      wait for ANODE_ON_TIME * 4;
      
    end loop;

    data <= X"FFFF";
    tb_blank <= "0000";
    
    --------------------------------------------------
    -- Test #3 - Done with test
    --------------------------------------------------
    write(L, string'("Done with simulation at time:"));
    write(L, NOW);
    writeline(output, L);
    wait;
    
  end process;    


  --------------------------------------------------
  -- Process to test segments on display
  --------------------------------------------------
  process
	variable temp_bool : boolean;
  begin
    wait until t_an_out'event;
    wait for CLK_PERIOD;
    temp_bool := check_segments(t_an_out, segments, dp_out, dp, data);
  end process;

  --------------------------------------------------
  -- Process to test blanking
  --------------------------------------------------
  process
    variable temp_bool : boolean;
    variable L : line;
  begin
    wait until tb_blank'event or t_an_out'event;
    wait for CLK_PERIOD;
    for i in 0 to 3 loop
      if (tb_blank(i) = '1' and t_an_out(i) = '0') then
        write(L, string'("Error: blank signal asserted and anode signal asserted at time:"));
        write(L, NOW);
        writeline(output, L);
      end if;
    end loop;
    
  end process;
  
  
end testbench;    
    