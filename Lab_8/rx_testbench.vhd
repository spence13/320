-------------------------------------------------------------------------------
-- Filename:        rx_testbench.vhd
--
-- Description:     Simple testbench for tx.vhd
-- 
-- Author:          Mike Wirthlin
--
-- Revision:        1.1
--
-- Description:
--
-------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use std.TextIO.all;
use ieee.std_logic_textio.all;

entity rx_testbench is
end rx_testbench;

architecture behavioral of rx_testbench is
  
  -- Global system clock
  signal t_clk : std_logic;
  signal t_rst : std_logic;
  signal t_rx_in : std_logic;
  signal t_data_out : std_logic_vector(7 downto 0);
  signal t_data_strobe, t_rx_busy : std_logic;

  signal data_strobe_time : time;
  
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
  signal start_transfer : std_logic := '0';
  signal data_to_transfer : std_logic_vector(7 downto 0);

  signal data_strobe_d : std_logic;
  
  -- Helper procedure for writing a string to stdout 
  procedure write_string(str : in String) is
    variable L : line;
  begin
    write(L, str);
    write(L, string'(" at "));
    write(L, NOW);
    writeline(output, L);
  end;

begin  -- behavioral

  -- rx
  urx: entity work.rx
    generic map (
      CLK_RATE => CLOCK_RATE,
      BAUD_RATE => BAUD_RATE
      )
    port map (
      clk => t_clk,
      rst => t_rst,
      rx_in => t_rx_in,
      data_out => t_data_out,
      data_strobe => t_data_strobe,
      rx_busy => t_rx_busy
    );

  --------------------------------------------------
  -- Main testbench process:
  --------------------------------------------------

  process
    variable L : line;
    variable time_stamp : time;
    variable time_measure : time;
    type data_array_type is array (3 downto 0) of std_logic_vector(7 downto 0);
    variable data_to_transfer_list : data_array_type :=
      ("01010101", "10101010", "11111111", "00000000");
    variable r_data : std_logic_vector(7 downto 0);
  begin

    --------------------------------------------------
    -- This first set of stimulus should really mess
    -- up the circuit: uninitialized inputs, clocking,
    -- etc. This is done to see if the reset will properly
    -- restore the circuit to a good and working state.
    --------------------------------------------------

    write_string("--- Begin with all signals uninitialized ---");
    t_rst <= 'U';
    t_rx_in <= 'U';
    clk_undefined <= true;
    clock_startup <= false;
    wait for UNINITIALIZED_TIME;

    write_string("--- Start the clock, other signals uninitialized ---");
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
    t_rx_in <= '1';
    wait for RESET_RELEASE_TIME;

    write_String("--- Release Reset ---");
    -- deassert reset
    t_rst <= '0';
    wait for RESET_RELEASE_TIME;

    write_String("--- Test #1 ---");
    for j in data_to_transfer_list'range loop

      data_to_transfer <= data_to_transfer_list(j);

      -- Issue start bit
      t_rx_in <= '0';
      wait for BAUD_PERIOD;
      
      -- loop over 8 bits
      for i in 0 to 7 loop
        t_rx_in <= data_to_transfer(i);
        wait for BAUD_PERIOD;
      end loop;

      -- send stop bit
      t_rx_in <= '1';
      wait until t_clk'event and t_clk='0' and t_data_strobe = '1';
		
      r_data := t_data_out;
      
      -- Print character out
      if (r_data = data_to_transfer) then
        write(L, string'("Successfully received the following byte:"));
        write(L, r_data);
        writeline(output, L);
      else
        write(L, string'("Failed receiver. Expecting:"));
        write(L, data_to_transfer);
        write(L, string'(" but received:"));
        write(L, r_data);
        writeline(output, L);
      end if;

      wait for 3*BAUD_PERIOD;

    end loop;
    
    -- Test #3: Send a well formatted character but assert rx_d during
    -- stop bit. Make sure it is not accepted.
    -- Issue start bit
    write_String("--- Test #3 ---");
    wait for 3*BAUD_PERIOD;
    data_to_transfer <= "11010111";
    t_rx_in <= '0';
    wait for BAUD_PERIOD;

    -- loop over 8 bits
    for i in 0 to 7 loop
      t_rx_in <= data_to_transfer(i);
      wait for BAUD_PERIOD;
    end loop;

    -- send bogus stop bit
    t_rx_in <= '0';
    wait for 3*BAUD_PERIOD;             -- send 3 stop bits
    -- see if the data strobe is asserted (it shouldn't be)
    assert data_strobe_d'stable(4*BAUD_PERIOD)
      report "Data Strobe should not be asserted when the stop bit is zero";
    t_rx_in <= '1';
    wait for 2*BAUD_PERIOD;
    
    -- Test #4: Assert rx_d at start-up and make sure the receiver doesn't
    -- view this as a character
    write_String("--- Test #4 ---");
    wait for 3*BAUD_PERIOD;
    t_rst <= '1';
    wait for 1 us;
    t_rx_in <= '0';
    wait for 1 us;
    t_rst <= '0';
    -- Wait for 9 baud periods (act like this is "all zeros")
    wait for 9*BAUD_PERIOD;
    -- provide a stop bit
    t_rx_in <= '1';
    wait for BAUD_PERIOD;
    -- check to see if a character was accepted (it should be)
    assert t_data_strobe'stable(10*BAUD_PERIOD)
      report "Data Strobe should not be asserted when the rx_in is low when reset is asserted"; 
    
    -- Test busy signal. Make sure it
    write_String("--- Test #5 ---");
    data_to_transfer <= "00000000";
    t_rx_in <= '0';
    -- Wait for several clock cycles so the rx_in propagates through the
    -- synchronizers
    wait until t_clk'event and t_clk='1';
    wait until t_clk'event and t_clk='1';
    wait until t_clk'event and t_clk='1';
    wait until t_clk'event and t_clk='1';
    assert t_rx_busy = '1' report "rx_busy should be asserted once the start bit as been received";
    wait for BAUD_PERIOD;

    -- loop over 8 bits
    for i in 0 to 7 loop
      t_rx_in <= data_to_transfer(i);
      wait for BAUD_PERIOD;
    end loop;

    -- send good stop bit
    assert t_rx_busy'stable(8*BAUD_PERIOD)
      report "rx_busy should be asserted during the entire byte transfer";
    t_rx_in <= '1';
    wait for 2*BAUD_PERIOD;

    write_string("--- Test Done ---");

    wait;

    
  end process;
  
  process(t_clk)
  begin
    if (t_clk'event and t_clk = '1') then
      data_strobe_d <= t_data_strobe;
    end if;
  end process;
  
  -- Clock generation process
  t_clk <= not t_clk after HALF_CLOCK_PERIOD when clock_startup else
           'U' when clk_undefined else
           '0';

end behavioral;