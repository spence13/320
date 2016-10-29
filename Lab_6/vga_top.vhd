LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;


entity top is
	generic(
			COUNTER_BITS: natural :=16
			);
	port(
			top_clk: in std_logic;
			btn: in std_logic_vector(3 downto 0);
			sw: in std_logic_vector(7 downto 0);
			
			Hsync: out std_logic;
			Vsync: out std_logic;
			vgaRed: out std_logic_vector(2 downto 0);
			vgaGreen: out std_logic_vector(2 downto 0);
			vgaBlue: out std_logic_vector(1 downto 0);
			
			seg: out std_logic_vector(6 downto 0);
			dp: out std_logic;
			an: out std_logic_vector(3 downto 0)
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
	signal flash: std_logic;
	
	signal frame_counter: unsigned(COUNTER_BITS-1 downto 0) := (others => '0');
	
	signal red_disp: std_logic_vector(2 downto 0);
	signal green_disp: std_logic_vector(2 downto 0);
	signal blue_disp: std_logic_vector(1 downto 0);
	
	signal nobtn_red: std_logic_vector(2 downto 0);
	signal nobtn_green: std_logic_vector(2 downto 0);
	signal nobtn_blue: std_logic_vector(1 downto 0);
	
	signal btn1_red: std_logic_vector(2 downto 0);
	signal btn1_green: std_logic_vector(2 downto 0);
	signal btn1_blue: std_logic_vector(1 downto 0);
	
	signal btn0_red: std_logic_vector(2 downto 0);
	signal btn0_green: std_logic_vector(2 downto 0);
	signal btn0_blue: std_logic_vector(1 downto 0);
	
	signal control: std_logic_vector(35 downto 0);
	signal trigger: std_logic_vector(31 downto 0);
	
	
	
	component chipscope_icon
    port (
      CONTROL0 : inout std_logic_vector(35 downto 0)
    );
   end component;
  
   component chipscope_ila
    port (
      CONTROL	: inout std_logic_vector(35 downto 0);
      CLK	:  in  std_logic;
      TRIG0	:  in std_logic_vector(31 downto 0)
      );
   end component;
	
begin

--counter------------------
process(top_clk)
begin
	if (top_clk'event and top_clk='1') then
		if(tmp_last_column='1' and tmp_last_row='1') then
			frame_counter <= 	frame_counter + 1;
		if(frame_counter mod 64 < 30) then
			flash <= not(flash);
		end if;

		end if;
	Hsync <= tmp_HS;
	Vsync <= tmp_VS;
	vgaRed <= red_disp;
	vgaGreen <= green_disp;
	vgaBlue <= blue_disp;
	end if;
end process;

		  red_disp <= "000" when tmp_blank = '1' else 
				btn0_red when btn(0) = '1' else 
				btn1_red when btn(1) = '1' else 
				sw(7 downto 5) when btn(2) = '1' else
				nobtn_red	when btn = "0000" else
			   "000";
				
green_disp <= "000" when tmp_blank = '1' else
				  btn0_green when btn(0) = '1' else 
				  btn1_green when btn(1) = '1' else 
				  sw(4 downto 2) when btn(2) = '1' else 
				  nobtn_green when btn = "0000" else
				  "000";
				  
blue_disp <= "00" when tmp_blank = '1' else 
				 btn0_blue when btn(0) = '1' else
				 btn1_blue when btn(1) = '1' else 
				 sw(1 downto 0) when btn(2) = '1' else 
				 nobtn_blue when btn= "0000" else				 
				 "00";
				 
				
btn0_red <= "000" when (unsigned(tmp_pixel_x) > 399 and unsigned(tmp_pixel_x) < 501) and (unsigned(tmp_pixel_y) > 99 and unsigned(tmp_pixel_y) < 201) else --green square
				"111";

btn0_green <= "000" when (unsigned(tmp_pixel_x) > 179 and unsigned(tmp_pixel_x) < 281) and (unsigned(tmp_pixel_y) > 99 and unsigned(tmp_pixel_y) < 201) else --red square
				  "000" when (unsigned(tmp_pixel_x) > 399 and unsigned(tmp_pixel_x) < 501) and (unsigned(tmp_pixel_y) > 299 and unsigned(tmp_pixel_y) < 401) else --magenta		 				 
			  	  "111";

btn0_blue <= "00" when (unsigned(tmp_pixel_x) > 179 and unsigned(tmp_pixel_x) < 281) and (unsigned(tmp_pixel_y) > 99 and unsigned(tmp_pixel_y) < 201) else --red square
				 "00" when (unsigned(tmp_pixel_x) > 399 and unsigned(tmp_pixel_x) < 501) and (unsigned(tmp_pixel_y) > 99 and unsigned(tmp_pixel_y) < 201) else --green square
				 "00" when (unsigned(tmp_pixel_x) > 179 and unsigned(tmp_pixel_x) < 281) and (unsigned(tmp_pixel_y) > 299 and unsigned(tmp_pixel_y) < 401) else --yellow square
				 "11";	
				 


btn1_red <= "000";

btn1_green <= "111" when unsigned(tmp_pixel_x) < unsigned(tmp_pixel_y) else 
				  "000";

btn1_blue <= "11" when (unsigned(tmp_pixel_x) > 179 and unsigned(tmp_pixel_x) < 281) and (unsigned(tmp_pixel_y) > 299 and unsigned(tmp_pixel_y) < 401) else
				 "00";	
				 
				 
				 
nobtn_red <= "000" when (unsigned(tmp_pixel_x) > 0  and unsigned(tmp_pixel_x) < 320) else
				 "111";

nobtn_green <= "000" when (unsigned(tmp_pixel_x) > 0   and unsigned(tmp_pixel_x) < 160) 
							  or (unsigned(tmp_pixel_x) > 319 and unsigned(tmp_pixel_x) < 480) else
					"111";

nobtn_blue <=	"00" when (unsigned(tmp_pixel_x) > 0   and unsigned(tmp_pixel_x) < 80) 
							 or (unsigned(tmp_pixel_x) > 159 and unsigned(tmp_pixel_x) < 240)
							 or (unsigned(tmp_pixel_x) > 319 and unsigned(tmp_pixel_x) < 400) 
							 or (unsigned(tmp_pixel_x) > 479 and unsigned(tmp_pixel_x) < 560) else
					"11";		 
				 
				
				 
				 
		 
				 


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
								  
								  
seven_seg_one	: entity work.seven_segment_control(ssc_arch) 
				     port map (clk => top_clk,

							 	   data_in => std_logic_vector(frame_counter),
								   dp_in => "1111",
								   blank => "0000",
									
									seg => seg,
									dp => dp,								
									an => an
								  );
trigger <= '0' & tmp_blank & tmp_HS & tmp_VS & tmp_pixel_x & tmp_pixel_y 
					& red_disp & green_disp & blue_disp;							  
								  
icon: chipscope_icon port map (CONTROL0 => control);
ila: chipscope_ila port map (CONTROL => control, CLK => top_clk, TRIG0 => trigger);

								  


end top_arch;

