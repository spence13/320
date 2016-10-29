library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity top is
	generic(
			CLK_RATE: natural := 50_000_000;
			SAMPLE_FREQ: natural := 10;
			COUNTER_BITS: natural := 24
			);
	port(
		clk: in std_logic;
		reset: in std_logic;
		btn_0: in std_logic;
		switches: in std_logic_vector(7 downto 0);
		
		
		vgaRed: out std_logic_vector(2 downto 0);
		vgaGreen: out std_logic_vector(2 downto 0);
		vgaBlue: out std_logic_vector(1 downto 0);		

		Hsync: out std_logic;
		Vsync: out std_logic;
		
		seg: out std_logic_vector(6 downto 0);
		dp: out std_logic;
		an: out std_logic_vector(3 downto 0)		

	);
end top;


architecture top_arch of top is
signal char_addr: std_logic_vector(11 downto 0);
signal pixel_x: std_logic_vector(9 downto 0);
signal pixel_y: std_logic_vector(9 downto 0);
signal pixel_out: std_logic;
signal data_in: std_logic_vector(15 downto 0);
signal blank: std_logic;
signal HS: std_logic;
signal HS_d: std_logic;
signal VS: std_logic;
signal VS_d: std_logic;
signal char_row: unsigned(4 downto 0);
signal char_col: unsigned(6 downto 0);

constant count_value : natural := CLK_RATE / SAMPLE_FREQ;
signal counter : unsigned(COUNTER_BITS-1 downto 0):= (others =>'0');
signal btn_0_debounced: std_logic;

begin

process(clk,reset)
begin
	if(reset='1') then
		counter <= (others => '0');
		btn_0_debounced <= '0';
	elsif (clk'event and clk='1') then
		if(counter = count_value) then 
			btn_0_debounced <= btn_0;
			counter <= (others => '0');
		elsif(counter < count_value) then
			counter <= counter + 1;
			btn_0_debounced <= '0';
		end if;
	end if;
end process;


process(clk)
begin
	if(clk'event and clk='1') then
		HS_d <= HS;
		Hsync <= HS_d;
		
		VS_d <= VS;
		Vsync <= VS_d;
	end if;
end process;


vgaRed <= "000" when blank = '1' or reset='1' else
			 "111" when pixel_out ='1' else
			 "000" when pixel_out ='0';
			 
vgaGreen <= "000" when blank = '1' or reset='1' else
				"111" when pixel_out ='1' else
				"000" when pixel_out ='0';

vgaBlue <= "00" when blank = '1' or reset='1' else
				"11" when pixel_out ='1' else
				"00" when pixel_out ='0';


process(clk, btn_0_debounced)
begin
	if(clk'event and clk='1') then
		if(btn_0_debounced='1') then
			if(char_row=29 and char_col=79) then
				char_row <= (others => '0');
				char_col <= (others => '0');
			elsif(char_col=79 and char_row<29) then
				char_row <= char_row + 1;
				char_col <= (others => '0');
			else
				char_col <= char_col + 1;
			end if;	
		end if;
	end if;
end process;

char_addr <= std_logic_vector(char_row) & std_logic_vector(char_col);


charGen1	: entity work.charGen(arch_charGen) 
				     port map (clk => clk,
									char_we => btn_0_debounced,
									char_value => switches,
									char_addr => char_addr,
									pixel_x => pixel_x,
									pixel_y => pixel_y,
									
									pixel_out => pixel_out

								  );
								  
vga	: entity work.vga_timing(arch_vga) 
				     port map (clk => clk,
									rst => reset,
									
									HS => HS,
									VS => VS,
									pixel_x => pixel_x,
									pixel_y => pixel_y,
									--last_column => pixel_y,
									--last_row => pixel_y,
									blank => blank

								  );

data_in <= "00000000" & switches;
								  
seven_seg	: entity work.seven_segment_control(ssc_arch) 
				     port map (clk => clk,
									data_in => data_in,	
									dp_in => "0000",
									blank => "1100",
									
									seg => seg,
									dp => dp,
									an => an

								  );								  


end top_arch;


