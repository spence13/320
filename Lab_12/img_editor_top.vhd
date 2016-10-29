
-- FINAL PROJECT

-- Andy Monk - sec 2
-- Spencer Carter - sec 1
-- ECEN 320
-- WINTER 2016

-------------------------------------------------------------------------------------------------------------------------------------------------------
--																																																   RANT
-------------------------------------------------------------------------------------------------------------------------------------------------------
-- I really really really wish that you could collapse blocks of code like you can in other IDEs for other languages.
-- this code gets really annoying to traverse...
-------------------------------------------------------------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity img_editor is
	generic(
		-- generics used in rx, seven_segment_control and sramController
		CLK_RATE				: natural := 50_000_000;
		BAUD_RATE			: natural := 19_200;
		COUNTER_BITS		: natural := 15;
		
		-- generics used in vga_timing
		H_SYNC 				: integer := 799;
		H_DISP 				: integer := 639;
		H_FP 					: integer := 655;
		H_PW 					: integer := 751;
		H_BP 					: integer := 799;
		V_SYNC 				: integer := 520;
		V_DISP 				: integer := 479;
		V_FP 					: integer := 489;
		V_PW 					: integer := 491;
		V_BP 					: integer := 520
	);
	port(
	-- INPUTS
		clk					: in std_logic;
		rx_in					: in std_logic; -- from uart receiver
		btn0					: in std_logic; -- button 0
		
	-- OUTPUTS
		-- just pass through from seven_segment_control
		ssd_seg				: out std_logic_vector(6 downto 0);
		ssd_dp				: out std_logic;
		ssd_an				: out std_logic_vector(3 downto 0);
		
		-- just pass through from vga_timing
		vga_hs				: out std_logic;
		vga_vs				: out std_logic;
		-- if editing_flag is set, then these are (others => '0') otherwise defined by frame buffer
		vga_red				: out std_logic_vector(2 downto 0);
		vga_green			: out std_logic_vector(2 downto 0);
		vga_blue				: out std_logic_vector(1 downto 0);
		
		-- pass through from sram_controller
		MemAdr				: out std_logic_vector(22 downto 0);
		MemOE					: out std_logic;
		MemWR					: out std_logic;
		RamCS					: out std_logic := '1';
		RamLB					: out std_logic := '0';
		RamUB					: out std_logic := '0';
		RamCLK				: out std_logic := '0';
		RamADV				: out std_logic := '1';
		RamCRE				: out std_logic := '1';
		MemDB					: inout std_logic_vector(15 downto 0)
	);
end img_editor;

architecture five_op of img_editor is
-------------------------------------------------------------------------------------------------------------------------------------------------------
--																																															COMPONENTS
-------------------------------------------------------------------------------------------------------------------------------------------------------
-- RX COMPONENT
	component rx
		generic(
			CLK_RATE 			: Natural := 50_000_000;
			BAUD_RATE 			: Natural := 19_200
		);
		port(
			clk 					: in std_logic;
			rst 					: in std_logic := '0';
			rx_in 				: in std_logic;
			data_out 			: out std_logic_vector(7 downto 0) := (others => '0');
			data_strobe 		: out std_logic;
			rx_busy 				: out std_logic
		);
	end component;
	
-- SSD COMPONENT
	component seven_segment_control
		generic(
			COUNTER_BITS 		: natural := 15
		);
		port(
			clk 					: in std_logic;
			data_in 				: in std_logic_vector(15 downto 0);
			dp_in 				: in std_logic_vector(3 downto 0);
			blank 				: in std_logic_vector(3 downto 0);
			seg 					: out std_logic_vector(6 downto 0);
			dp 					: out std_logic;
			an 					: out std_logic_vector(3 downto 0)
		);
	end component;
	
--FRAME BUFFER COMPONENT
	component framebuffer
		port(
			clk 					: in std_logic;
			btn0 					: in std_logic;
			sw 					: in std_logic_vector(4 downto 0);
			
			Hsync 				: out std_logic;
			Vsync 				: out std_logic;
			vgaRed 				: out std_logic_vector(2 downto 0);
			vgaGreen 			: out std_logic_vector(2 downto 0);
			vgaBlue 				: out std_logic_vector(1 downto 0);
			
			MemAdr 				: out std_logic_vector(22 downto 0);
			MemOE 				: out std_logic;
			MemWR 				: out std_logic;
			RamCS 				: out std_logic;
			RamLB 				: out std_logic;
			RamUB 				: out std_logic;
			RamCLK 				: out std_logic;
			RamADV 				: out std_logic;
			RamCRE 				: out std_logic;
			MemDB 				: inout std_logic_vector(15 downto 0)
		);
	end component;
	

	
-------------------------------------------------------------------------------------------------------------------------------------------------------
--																																																SIGNALS
-------------------------------------------------------------------------------------------------------------------------------------------------------
-- NECESSARY SUPPLEMENTARY SIGNALS
-- RX
	signal rx_out				: std_logic_vector(7 downto 0) := (others => '0'); -- byte of data from uart receiver
	signal rx_strobe			: std_logic; -- signal determining when byte of data is ready
-- SSD
	signal ssd_in				: std_logic_vector(15 downto 0); -- pass in edit counter contents
	signal ssd_dp_in			: std_logic_vector(3 downto 0); -- all zeros
	signal ssd_blank			: std_logic_vector(3 downto 0); -- all zeros

-- INTERNAL SIGNALS
	signal terminal			: std_logic_vector(95 downto 0):= (others => '0'); -- shift register holding read bytes from putty	
	signal switches 			: std_logic_vector(4 downto 0);
-------------------------------------------------------------------------------------------------------------------------------------------------------
--																																									 BEGINNING OF CIRCUIT DESIGN
-------------------------------------------------------------------------------------------------------------------------------------------------------
begin
-- TERMINAL
	process(clk, btn0, rx_strobe)
	begin
		if btn0 = '1' then
			terminal <= (others => '0');
		elsif clk'event and clk='1' then
				if rx_strobe = '1' then
					if rx_out /= "00001101" then -- check against enter key
						terminal <= terminal(87 downto 0) & rx_out;
					else  -- since commands are of different length, make sure to check commands from longest to shortest
							-- there are 96 dashes (don't care) for each "command" -> 12 characters max per command
						if 	terminal = "011010000110000101110010011100100111100100100000011100000110111101110100011101000110010101110010" or		-- "harry potter"
								terminal = "010010000100000101010010010100100101100100100000010100000100111101010100010101000100010101010010" then	-- "HARRY POTTER"
									switches <= "00111";
						elsif terminal = "----------------01100011011011110110111001110110011001010110111001110100011010010110111101101110" or		-- "convention"
								terminal = "----------------01000011010011110100111001010110010001010100111001010100010010010100111101001110" then	-- "CONVENTION"
									switches <= "00011";
						elsif terminal = "--------------------------------0111011101101001011100100111010001101000011011000110100101101110" or		-- "wirthlin"
								terminal = "--------------------------------0101011101001001010100100101010001001000010011000100100101001110" then	-- "WIRTHLIN"
									switches <= "00001";
						elsif terminal = "------------------------------------------------011011010110000101111010011110100110010101101111" or		-- "mazzeo"
								terminal = "------------------------------------------------010011010100000101011010010110100100010101001111" then	-- "MAZZEO"
									switches <= "00100";
						elsif terminal = "--------------------------------------------------------0111010001110010011101010110110101110000" or		-- "trump"
								terminal = "--------------------------------------------------------0101010001010010010101010100110101010000" then	-- "TRUMP"
									switches <= "01000";
						elsif terminal = "--------------------------------------------------------0111001101101000011010010111001001100101" or		-- "shire"
								terminal = "--------------------------------------------------------0101001101001000010010010101001001000101" then	-- "SHIRE"
									switches <= "00101";
						elsif terminal = "----------------------------------------------------------------01100010011010010111001001100100" or		-- "bird"
								terminal = "----------------------------------------------------------------01000010010010010101001001000100" then	-- "BIRD"
									switches <= "00010";
						elsif terminal = "----------------------------------------------------------------01100010011001010110000101110010" or		-- "bear"
								terminal = "----------------------------------------------------------------01000010010001010100000101010010" then	-- "BEAR"
									switches <= "00110";
						-- enter as many commands as desired
						-- template for new command
						-- elsif terminal = "------------------------------------------------------------------------------------------------" or
						--			terminal = "------------------------------------------------------------------------------------------------" then
						--		op_flag(n) <= '1'; -- n is the order of the operation in the check list and its one hot encoding
						end if;
					end if;
				end if;
		end if;
	end process;
	
	
-------------------------------------------------------------------------------------------------------------------------------------------------------
--																																													  INSTANTIATIONS
-------------------------------------------------------------------------------------------------------------------------------------------------------
-- RX INSTANTIATION
	uartRX : rx
	generic map(
		CLK_RATE 		=> CLK_RATE,
		BAUD_RATE 		=> BAUD_RATE
	)
	port map(
		clk 				=> clk,
		rst 				=> btn0,
		rx_in 			=> rx_in,
		data_out 		=> rx_out,
		data_strobe 	=> rx_strobe,
		rx_busy 			=> open
	);
	
-- SSD INSTANTIATION
	SSD : seven_segment_control
	generic map(
		COUNTER_BITS 	=> COUNTER_BITS
	)
	port map(
		clk 				=> clk,
		data_in 			=> ssd_in,
		dp_in 			=> ssd_dp_in,
		blank 			=> ssd_blank,
		seg 				=> ssd_seg,
		dp 				=> ssd_dp,
		an 				=> ssd_an
	);

-- FRAMEBUFFER INSTANTIATION
	framebuf : framebuffer
	port map(
		clk 				=> clk,
		btn0 				=> btn0,
		sw 				=> switches,
		
		Hsync 			=> vga_hs,
		Vsync 			=> vga_vs,
		vgaRed 			=> vga_red,
		vgaGreen  		=> vga_green,
		vgaBlue 			=> vga_blue,
		
		MemAdr 			=> MemAdr,
		MemOE 			=> MemOE,
		MemWR 			=> MemWR,
		RamCS 			=> RamCS,
		RamLB 			=> RamLB,
		RamUB 			=> RamUB,
		RamCLK 			=> RamCLK,
		RamADV 			=> RamADV,
		RamCRE 			=> RamCRE,
		MemDB 			=> MemDB
	);

end five_op;