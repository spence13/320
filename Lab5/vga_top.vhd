LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;


entity top is
	port(
			top_clk: in std_logic;
			btn: in std_logic_vector(3 downto 0);
			sw: in std_logic_vector(7 downto 0);
			
			Hsync: out std_logic;
			Vsync: out std_logic;
			vgaRed: out std_logic_vector(2 downto 0);
			vgaGreen: out std_logic_vector(2 downto 0);
			vgaBlue: out std_logic_vector(1 downto 0)
		);
	end top;
	

architecture top_arch of top is
	signal tmp_HS: std_logic;
	signal tmp_VS: std_logic;
	signal tmp_pixel_x: std_logic_vector(9 downto 0);
	signal tmp_pixel_y: std_logic_vector(9 downto 0);
	signal tmp_last_column: std_logic;
	signal tmp_last_row: std_logic;
	signal tmp_blank: std_logic;
	
	signal tmp_red: std_logic_vector(2 downto 0);
	signal tmp_green: std_logic_vector(2 downto 0);
	signal tmp_blue: std_logic_vector(1 downto 0);
	
	signal red_disp: std_logic_vector(2 downto 0);
	signal green_disp: std_logic_vector(2 downto 0);
	signal blue_disp: std_logic_vector(1 downto 0);
	
begin

--counter------------------
process(top_clk)
begin
	if (top_clk'event and top_clk='1') then
	Hsync <= tmp_HS;
	Vsync <= tmp_VS;
	vgaRed <= tmp_red;
	vgaGreen <= tmp_green;
	vgaBlue <= tmp_blue;
	end if;
end process;


tmp_red <= red_disp when tmp_blank = '0' else 
		 "000";
tmp_green <= green_disp when tmp_blank = '0' else 
		   "000";
tmp_blue <= blue_disp when tmp_blank = '0' else 
		  "00";
		  
		  red_disp <= "111" when btn(2) = '1' else
			 	"000" when btn(1) = '1' else 
			   "000" when btn(0) = '1' else 
				sw(7 downto 5)	when btn = "0000" else
			   "000";
green_disp <= "000" when btn(2) = '1' else 
			 	  "111" when btn(1) = '1' else 
				  "000" when btn(0) = '1' else 
				  sw(4 downto 2) when btn = "0000" else
				  "000";
blue_disp <= "00" when btn(2) = '1' else 
			 	 "00" when btn(1) = '1' else 
			    "11" when btn(0) = '1' else
				 sw(1 downto 0) when btn= "0000" else				 
				 "00";


timing_one	: entity work.vga_timing(arch_vga) 
				     port map (clk => top_clk,
									rst => btn(3),
									
									HS => tmp_HS,
									VS => tmp_VS,
									pixel_x => tmp_pixel_x,
									pixel_y => tmp_pixel_y,
									last_column => tmp_last_column,
									last_row => tmp_last_row, 
									blank => tmp_blank
									
								  );


end top_arch;

