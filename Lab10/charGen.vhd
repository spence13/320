library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--entity declaration===================================================
entity charGen is

	port(
		clk: in std_logic;
		char_we: in std_logic;
		char_value: in std_logic_vector(7 downto 0);
		char_addr: in std_logic_vector(11 downto 0);
		pixel_x: in std_logic_vector(9 downto 0);
		pixel_y: in std_logic_vector(9 downto 0);
		
		pixel_out: out std_logic

	);
end charGen;



architecture arch_charGen of charGen is
signal char_read_addr: std_logic_vector(11 downto 0);
signal char_read_value: std_logic_vector(7 downto 0);
signal font_rom_addr: std_logic_vector(10 downto 0);
signal data: std_logic_vector(7 downto 0);
signal pixel_x_d: std_logic_vector(2 downto 0);
signal pixel_x_dd: std_logic_vector(2 downto 0);


begin



--Character Memory===============================
--to determine the character cell location
-- the top 5 bits are the Y and the lower 7 bits are the X
char_read_addr <= pixel_y(8 downto 4) & pixel_x(9 downto 3);

Character_memory	: entity work.char_mem(arch) 
				     port map (clk => clk,
									char_read_addr => char_read_addr,
									char_write_addr => char_addr,
									char_we => char_we,
									char_write_value => char_value,
									
									char_read_value => char_read_value

								  );
			

--Font ROM===============================			
--address from where you find one of the 128 characters
font_rom_addr <= char_read_value(6 downto 0) & pixel_y(3 downto 0);
								  
Font_rom1	: entity work.font_rom(arch) 
				     port map (clk => clk,
									addr => font_rom_addr,
									
									data => data
								  );	


process(clk)
begin
	if(clk'event and clk='1') then
		pixel_x_d <= pixel_x(2 downto 0);
		pixel_x_dd <= pixel_x_d;
	end if;
end process;


pixel_out <= data(7) when pixel_x_dd = "000" else
				 data(6) when pixel_x_dd = "001" else
				 data(5) when pixel_x_dd = "010" else
				 data(4) when pixel_x_dd = "011" else
				 data(3) when pixel_x_dd = "100" else
				 data(2) when pixel_x_dd = "101" else
				 data(1) when pixel_x_dd = "110" else
				 data(0) when pixel_x_dd = "111";			 



end arch_charGen;


