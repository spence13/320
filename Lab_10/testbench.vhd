-------------------------------------------------------------------------------
--
-- Filename: tb_chargen.vhd
--
--
-- This testbench will test the ability of the character generator
-- to store characters and display the proper pixel values. This
-- testbench does NOT simulate the behavior of the VGA timing controller.
--
-- Author: Mike Wirthlin, BYU
-- 
-- Version 1.5
--
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.TextIO.all;
use ieee.std_logic_textio.all;

entity tb_chargen is
end tb_chargen;

architecture testbench of tb_chargen is

  -----------------------------------------------------------------------------
  -- CONSTANTS
  --
  -----------------------------------------------------------------------------
  constant CLK_RATE : natural := 50_000_000;
  constant CLK_PERIOD : time := 1000 ms / CLK_RATE;
  constant HALF_CLOCK_PERIOD : time := CLK_PERIOD / 2;
  
  -----------------------------------------------------------------------------
  -- COMPONENT SIGNALS
  -----------------------------------------------------------------------------
  signal tb_clk, clk50Mhz : std_logic := '0';
  signal tb_char_we : std_logic;
  signal tb_char_value : std_logic_vector(7 downto 0);
  signal tb_char_addr : std_logic_Vector(11 downto 0);
  signal tb_pixel_x : std_logic_vector(9 downto 0);
  signal tb_pixel_y : std_logic_vector(9 downto 0);
  signal tb_pixel_out : std_logic;

  type CLOCK_STATE_TYPE is (uninitialized, zero, running);
  signal clock_state : CLOCK_STATE_TYPE;

  -- types and values for the character tests
  type character_test_record is
    record
      char_to_send : std_logic_vector(7 downto 0);
      x_char_addr : Integer;
      y_char_addr : Integer;
    end record;
  type char_test_array is array(0 to 4) of character_test_record;
  signal char_tests : char_test_array :=
    (
      -- Write the character 'A' at location 0,1
      (X"41", 0, 1),
      -- Write the character '0' at location 44,13
      (X"30", 44,13),
      -- Write the character 'Y' at location 79,31
      (X"59", 79,31),
      -- Write the character 'z' at location 13,27 
      (X"7A",13,27), 
     -- Write the character '.' at location 55,2 
      (X"2E",55,2)
     );
  signal x_char_addr : std_logic_vector(6 downto 0);
  signal y_char_addr : std_logic_vector(4 downto 0);
  signal font_rom_clk : std_logic := '0';
  signal font_rom_addr : std_logic_vector(10 downto 0) := (others => '0');
  signal font_rom_data : std_logic_vector(7 downto 0);
  signal expected_line : std_logic_vector(8 downto 0);
  signal expected_mask : std_logic_vector(8 downto 0);

  component charGen
   port(
     clk : in std_logic;
     char_we : in std_logic;
     char_value : in std_logic_vector(7 downto 0);
     char_addr : in std_logic_Vector(11 downto 0);
     pixel_x : in std_logic_vector(9 downto 0);
     pixel_y : in std_logic_vector(9 downto 0);
     pixel_out : out std_logic
    );
  end component;
  
  -- Helper procedure for writing a string to stdout 
  procedure write_string(str : in String) is
    variable L : line;
  begin
    write(L, str);
    writeline(output, L);
  end;
  

begin

  -----------------------------------------------------------------------------
  -- Instance Character Generator
  -----------------------------------------------------------------------------

  u1 : charGen
    port map (
      clk => tb_clk,
      char_we => tb_char_we,
      char_value => tb_char_value,
      char_addr => tb_char_addr,
      pixel_x => tb_pixel_x,
      pixel_y => tb_pixel_y,
      pixel_out => tb_pixel_out
      );

  -----------------------------------------------------------------------------
  -- Instance Font ROM (used to check values of character generato)
  -----------------------------------------------------------------------------
  font : entity WORK.Font_rom
    port map (
      clk => font_rom_clk,
      addr => font_rom_addr,
      data => font_rom_data
      );

  --------------------------------------------------
  -- Main testbench process:
  --------------------------------------------------
  main : process
    variable char_row : unsigned(3 downto 0);
    variable char_column : unsigned(3 downto 0);
    variable char_test : character_test_record;
    variable char_to_print : character;
    variable cur_test : Integer;
    variable L : line;
  begin

    -- Set all inputs to uninitialized
    clock_State <= uninitialized;
    tb_char_we <= 'U';
    tb_char_value <= (others => 'U');
    tb_char_addr <= (others => 'U');

    tb_pixel_x <= (others => 'U');
    tb_pixel_y <= (others => 'U');
    x_char_addr <= (others => 'U');
    y_char_addr <= (others => 'U');
    wait for 200 ns;
    
    -- Set clock and char_we to zero
    --report "--- Start Clock and initialize inputs ---";
    clock_State <= zero;
    tb_char_we <= '0';
    tb_char_value <= (others => '0');
    tb_char_addr <= (others => '0');
    tb_pixel_x <= (others => '0');
    tb_pixel_y <= (others => '0');
    x_char_addr <= (others => '0');
    y_char_addr <= (others => '0');
    wait for 200 ns;

    -- Start clock
    clock_state <= running;
    wait for 200 ns;

    -- Write all zeros into the character memory to make sure there
    -- is nothing there (need to put memory in known state)
    wait until tb_clk'event and tb_clk = '0';
    write(L, string'("Writing zeros to all memories of character generator"));
    writeline(output, L);
    for i in 0 to 29 loop
      y_char_addr <= std_logic_vector(to_unsigned(i,5));
      for j in 0 to 79 loop
        x_char_addr <= std_logic_vector(to_unsigned(j,7));

        tb_char_addr <= y_char_addr & x_char_addr;
        -- write the data
        tb_char_value <= (others => '0');
        tb_char_we <= '1';
        wait until tb_clk'event and tb_clk = '0';
        tb_char_we <= '0';
        wait until tb_clk'event and tb_clk = '0';
      end loop;
    end loop;

    
    -- Place the test character values into the character memory
    for  i in char_tests'range loop
      char_test := char_tests(i);

      -- wait until negative edge of clk
      wait until tb_clk'event and tb_clk = '0';
      -- Set the write address
      x_char_addr <= std_logic_vector(to_unsigned(char_test.x_char_addr,7));
      y_char_addr <= std_logic_vector(to_unsigned(char_test.y_char_addr,5));
      wait until tb_clk'event and tb_clk = '0';
      
      tb_char_addr <= y_char_addr & x_char_addr;
      wait until tb_clk'event and tb_clk = '0';
      -- write the data
      tb_char_value <= char_test.char_to_send;
      tb_char_we <= '1';
      wait until tb_clk'event and tb_clk = '1';
      write(L, string'("Writing character "));
      write(L, char_test.char_to_send);
      write(L, string'(" ('"));
      char_to_print := character'val(to_integer(unsigned(char_test.char_to_send)));
      write(L, char_to_print);
      write(L, string'("') to location ("));
      write(L, char_test.x_char_addr);
      write(L, string'(","));
      write(L, char_test.y_char_addr);
      write(L, string'(")"));
      writeline(output, L);
      
      wait until tb_clk'event and tb_clk = '0';
      -- Deassert the write
      tb_char_we <= '0';
      tb_char_value <= (others => '0');
      tb_char_addr <= (others => '0');

      wait for 1 us;
      
      wait until tb_clk'event and tb_clk = '0';
      
    end loop;

    wait for 10 us;
    
    wait until tb_clk'event and tb_clk = '1';
    wait for 1 ns;

    -- Cycle through an entire VGA cycle
    for row in 0 to 529 loop
      tb_pixel_y <= std_logic_vector(to_unsigned(row,10));
      
      for column in 0 to 799 loop
        tb_pixel_x <= std_logic_vector(to_unsigned(column,10));
        wait for 1 ns;
        
        -- See if the current pixel is associated with the first column of 
        -- a character of one of the test cases. If so, save the pixel information that should
        -- be displayed for checking.
        for testcase in 0 to char_tests'length-1 loop
          -- See if the current column aligns with the first column of
          -- one of the test cases AND the row falls within the character
          -- (i.e., the first column of the character and any row of the character)
          if column = char_tests(testcase).x_char_addr * 8 and
            row >= char_tests(testcase).y_char_addr * 16 and
            row < (char_tests(testcase).y_char_addr+1) * 16 then
            -- Look up the font rom to find the row of pixels that should be displayed
            -- for this row of the character. Setting this signal will drive the internal
            -- FONT rom that is used to find out what the row should be.
            font_rom_addr <= char_tests(testcase).char_to_send(6 downto 0) &
                           tb_pixel_y(3 downto 0);
            -- Save index of test case that matches with the current character
            cur_test := testcase;
            wait for 1 ns;
            -- Clock the font rom to get the data we want to check
            font_rom_clk <= '1';
            wait for 1 ns;
            font_rom_clk <= '0';
            -- Save the expected data and initialize the mask for the check
            expected_line <= '0' & font_rom_data;
            expected_mask <= "011111111";
            wait for 1 ns;
            
          end if;
        end loop;
        
        wait until tb_clk'event and tb_clk = '1';

        -- check bit
        if expected_mask(8) = '1' then
          if expected_line(8) /= tb_pixel_out then
            write(L, string'("Error: incorrect bit on pixel ("));
            write(L, (column-1));
            write(L, string'(","));
            write(L, row);
            write(L, string'(") for character '"));
            char_to_print :=
              character'val(to_integer(unsigned(char_tests(cur_test).char_to_send)));
            write(L,char_to_print);
            write(L, string'("' expecting "));
            write(L, expected_line(8));
            write(L, string'(" received "));
            write(L, tb_pixel_out);
            write(L, string'(" at time "));
            write(L, NOW);
            writeline(output, L);
          --else
          --write(L, string'("Good bit"));
          --  writeline(output, L);
          end if;
        end if;

        wait until tb_clk'event and tb_clk = '1';
        expected_mask <= expected_mask(7 downto 0) & '0';
        expected_line <= expected_line(7 downto 0) & '0';
        wait for 1 ns;
        
      end loop;
    end loop;
    
    tb_pixel_y <= (others => '0');
    tb_pixel_x <= (others => '0');

    report "--- Done  ---";
    wait;
    
  end process;

  
  --------------------------------------------------
  -- Clock generation statement
  --------------------------------------------------
  with clock_state select
    tb_clk <= 'U' when uninitialized,
        '0' when zero,
         clk50MHz when others;
  clk50MHz <= not clk50MHz after HALF_CLOCK_PERIOD;
  
end testbench;