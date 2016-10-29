-------------------------------------------------------------------------------
-- Filename:        tx_testbench.vhd
--
-- Description:     Simple testbench for tx.vhd
-- 
-- Author:          Mike Wirthlin
--
-- Revision:        1.4
--
-- Description:
--
--  Provides a simple testbench to test the primary features of the
--  UART transmitter lab.
--
-------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use std.TextIO.all;
use ieee.std_logic_textio.all;

entity tx_testbench is
end tx_testbench;

architecture behavioral of tx_testbench is
  
  -- Global system clock
  signal t_clk : std_logic;
  signal t_rst : std_logic;
  signal t_send_character, t_serial_out, t_tx_busy : std_logic;
  signal t_data_in : std_logic_vector(7 downto 0);
  
  -- constants
  constant CLOCK_RATE : Natural := 50_000_000;
  constant BAUD_RATE : Natural := 19_200;
  constant BAUD_PERIOD : time := 1000 ms / BAUD_RATE;
  constant HALF_BAUD_PERIOD : time := BAUD_PERIOD / 2;
  constant BAUD_PERIOD_SLACK : time := BAUD_PERIOD / 20; 
  constant CLK_PERIOD : time := 20 ns;
  constant CLK_HALF_PERIOD : time := CLK_PERIOD / 2;
  constant UNINIT_STARTUP_TIME : time := 200 ns;
  
  constant CLOCK_INIT_TIME : time := 500 ns;
  constant UNINITIALIZED_TIME : time := 500 ns;
    
  constant CLOCK_PERIOD : time := 20 ns;
  constant HALF_CLOCK_PERIOD : time := CLOCK_PERIOD / 2;
  constant RESET_RELEASE_TIME : time := CLOCK_INIT_TIME + 500 ns;

  -- internal signal states to manage state of clock
  signal clk_undefined : boolean := false;
  signal clock_startup : boolean := false;

  -- Helper procedure for writing a string to stdout 
  procedure write_string(str : in String) is
    variable L : line;
  begin
    write(L, str);
    write(L, string'(":"));
    write(L, NOW);
    writeline(output, L);
  end;
  
    
begin  -- behavioral

  -- tx component
  utx: entity work.tx
    generic map (
      CLK_RATE => CLOCK_RATE,
      BAUD_RATE => BAUD_RATE
      )
    port map (
      clk => t_clk,
      data_in => t_data_in,
      send_character => t_send_character,
      rst => t_rst,
      tx_out => t_serial_out,
      tx_busy => t_tx_busy
    );

  -- Clock generation process
  t_clk <= not t_clk after HALF_CLOCK_PERIOD when clock_startup else
           'U' when clk_undefined else
           '0';
    
  --------------------------------------------------
  -- Main testbench process:
  --------------------------------------------------

  process
    variable L : line;
    variable time_stamp : time;
    variable time_measure : time;
    type data_array_type is array (3 downto 0) of std_logic_vector(7 downto 0);
    variable data_to_transfer : data_array_type :=
      ("10101010", "01101001", "11111111", "00000000");
    variable r_data : std_logic_vector(7 downto 0);
    variable last_byte_to_send : std_logic_Vector(7 downto 0) := "11110000";
  begin

    -- Should I check the t_serial_out to see if it was properly
    -- intialized?
    
    -- if t_serial_out /= '1' then
    
    --------------------------------------------------
    -- This first set of stimulus should really mess
    -- up the circuit: uninitialized inputs, clocking,
    -- etc. This is done to see if the reset will properly
    -- restore the circuit to a good and working state.
    --------------------------------------------------

    --write_string("--- Begin with all signals uninitialized ---");
    t_rst <= 'U';
    clk_undefined <= true;
    clock_startup <= false;
    t_data_in <= (others => 'U');
    t_send_character <= 'U';
    wait for UNINITIALIZED_TIME;
    
    --write_string("--- Start the clock, other signals uninitialized ---");
    -- force clock to '0'
    clk_undefined <= false;
    clock_startup <= false;
    wait for CLOCK_INIT_TIME;
    -- Start toggling clock
    clk_undefined <= false;
    clock_startup <= true;
    wait for CLOCK_INIT_TIME;
    wait for CLOCK_INIT_TIME;

    -- At this point, the clock should have messed up the internal
    -- state of the transmitter. Issue a reset to return the
    -- transmitter to a known state.
    --write_string("--- Issue Reset ---");
    -- assert reset
    t_rst <= '1';
    wait for RESET_RELEASE_TIME;
    
    -- set values of signals before releasing reset
    t_data_in <= (others => '0');
    t_send_character <= '0';
    wait for RESET_RELEASE_TIME;

    -- deassert reset
    t_rst <= '0';
    wait for RESET_RELEASE_TIME;
    
    -- send a '55' so we can measure each bit period (a transition for each bit)
    wait until t_clk'event and t_clk='0'; 
    t_data_in <= "01010101";
    t_send_Character <= '1';
    -- Clock signal on positive edge of clock
    wait until t_clk'event and t_clk='1';
    -- Keep send_character = '1' for another postive clock edge (should not do anything)
    wait until t_clk'event and t_clk='1';
    -- Wait until negative clock edge before releasing send_character signal
    wait until t_clk'event and t_clk='0';
    t_send_character <= '0';
    t_data_in <= "00000000";
    
    -- Check tx out (should be zero for start bit)
    if (t_serial_out /= '0') then
      write_string("TX should be '0' during start bit");
    end if;
    if (t_tx_busy /= '1') then
      write_string("tx_busy should be '1' while transmitter is transmitting");
    end if;

    -- Measure 9 baud periods to make sure they are within spec.
    -- This will also issue an error if there is a glitch on serial_out
    for i in 1 to 9 loop
      time_stamp := now;
      wait until t_serial_out'event;
      time_measure := now - time_stamp;
      if (time_measure > (BAUD_PERIOD + BAUD_PERIOD_SLACK) or
          time_measure < (BAUD_PERIOD - BAUD_PERIOD_SLACK)
          ) then
        write(L, string'("Incorrect Baud period. Measured "));
        write(L, time_measure);
        write(L, string'(" expecting "));
        write(L, BAUD_PERIOD);
        write(L, string'(" at time:"));
        write(L, NOW);
        writeline(output, L);
      end if;
    end loop;
    
    wait until t_tx_busy = '0';
    wait for 4*BAUD_PERIOD;

    -- Measure the tx_busy signal: make sure it is ~9 BAUD periods
    --write_String("--- Transmit several bytes ---");
    for i in data_to_transfer'range loop
      -- Issue command to transfer data
      t_data_in <= data_to_transfer(i);
      t_send_character <= '1';
      
      -- wait 1.5 baud periods
      wait for BAUD_PERIOD;
      wait for HALF_BAUD_PERIOD;
      t_data_in <= (others => '0');
      t_send_character <= '0';
      
      -- loop over 8 bits
      for i in 0 to 7 loop
        r_Data(i) := t_serial_out;
        wait for BAUD_PERIOD;
      end loop;
      -- Check for stop bit
      wait for BAUD_PERIOD;
      
      if (t_serial_out /= '1') then
        write(L, string'("Stop bit is not '1' at time "));
        write(L, NOW);
        writeline(output, L);
      end if;
      
      -- Print character out
      if (r_data = data_to_transfer(i)) then
        write(L, string'("Successfully transmitted the following byte:"));
        write(L, r_data);
      else
        write(L, string'("Failed transmission. Expecting:"));
        write(L, data_to_transfer(i));
        write(L, string'(" but received:"));
        write(L, r_data);
      end if;
      write(L, string'(" at time "));
      write(L, NOW);
      writeline(output, L);

      -- Delay between next transfer
      wait for 2*BAUD_PERIOD;

    end loop;

    
    -- Test the return state. Make sure the transmitter does not
    -- initiate another transfer until send_character goes low
    --write_String("--- Test return state waiting for send_character going low  ---");
    -- Issue a new character but do not release send_character
    wait for 20*BAUD_PERIOD;
    t_data_in <= "01111010";
    t_send_character <= '1';
    wait until t_tx_busy = '1';
    
    -- wait for enough time for the transfer to complete
    -- (10 baud periods)
    -- The state machine should be in the "RETRN" state
    -- and waiting for send_character to go low.
    wait for 10*BAUD_PERIOD;
    
    -- Wait for a few baud periods. Check to see if the
    -- serial out has changed in this time.
    wait for 10*BAUD_PERIOD;
    if (t_serial_out'LAST_EVENT < 10*BAUD_PERIOD) then
      write(L, string'("Error: The tx signal changed at time "));
      write(L, (NOW-t_serial_out'LAST_EVENT));
      writeline(output, L);
      write(L, string'("send_character has not gone low yet - no new character shoudl be transmitted"));
      writeline(output, L);
    end if;
    
    t_send_character <= '0';
    
    -- Send one last character
    wait for 2*BAUD_PERIOD;
    
      -- Issue command to transfer data
    t_data_in <= last_byte_to_send;
    t_send_character <= '1';
      
    -- wait for a stop bit
    wait until t_serial_out'event and t_serial_out = '0';
    t_data_in <= (others => '0');
    wait until t_clk'event and t_clk = '0';
    t_send_character <= '0';

    -- wait 1.5 baud periods
    wait for BAUD_PERIOD;
    wait for HALF_BAUD_PERIOD;
    -- loop over 8 bits
    for i in 0 to 7 loop
      r_Data(i) := t_serial_out;
      wait for BAUD_PERIOD;
    end loop;
    -- Check for stop bit
    wait for BAUD_PERIOD;
    assert t_serial_out = '1' report "Stop bit is missing";
    
    -- Print character out
    if (r_data = last_byte_to_send) then
      write(L, string'("Successfully transmitted the following byte:"));
      write(L, r_data);
      writeline(output, L);
    else
      write(L, string'("Failed transmission. Expecting:"));
      write(L, last_byte_to_send);
      write(L, string'(" but received:"));
      write(L, r_data);
      writeline(output, L);
    end if;

    write_string("--- Test Done ---");

    wait;

    
  end process;
  

  
  --------------------------------------------------
  -- Reset signal checking process
  --
  --  Checks to see if the two outputs are at the correct
  --  value when reset is asserted.
  --------------------------------------------------
  process
  begin

    wait until t_rst'stable(1 ns);

    if (t_rst = '1') then

      -- make sure tx_busy is not asserted during a reset
      if (t_tx_busy /= '0') then
        write_string("Error: tx_busy should be '0' during a reset (tx_busy='1')");
      end if;
      -- make sure the t_serial_out is '1' during a reset
      if (t_serial_out /= '1') then
        write_string("Error: TX should be '1' during a reset (TX='0' when reset asserted)");
      end if;
    end if;

  end process;
    
  
end behavioral;