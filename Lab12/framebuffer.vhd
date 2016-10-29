library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity framebuffer is
	port(
		clk: 		in std_logic;
		btn0: 	in std_logic;
		sw:   	in std_logic_vector(4 downto 0);
		
		Hsync: out std_logic;
		Vsync: out std_logic;
		vgaRed: out std_logic_vector(2 downto 0);
		vgaGreen: out std_logic_vector(2 downto 0);
		vgaBlue: out std_logic_vector(1 downto 0);
		MemAdr: out std_logic_vector(22 downto 0);
		MemOE: out std_logic;
		MemWR: out std_logic;--WE
		RamCS: out std_logic;--CE
		RamLB: out std_logic;
		RamUB: out std_logic;
		RamCLK: out std_logic;
		RamADV: out std_logic;
		RamCRE: out std_logic;
		MemDB: inout std_logic_vector(15 downto 0)	
	
		);
end framebuffer;


architecture arch_framebuffer of framebuffer is
		signal pixel_x:  std_logic_vector(9 downto 0);
		signal pixel_y:  std_logic_vector(9 downto 0);
		signal addr: std_logic_vector(22 downto 0);
		signal data_s2m: std_logic_vector(15 downto 0);
		signal data_s2m_d: std_logic_vector(15 downto 0);
		signal byte: std_logic_vector(7 downto 0);
		signal blank: std_logic;
		signal data_valid: std_logic;
		signal HSync0: std_logic;
		signal HSync1: std_logic;
		signal HSync2: std_logic;
		signal HSync3: std_logic;
		signal HSync4: std_logic;
		
		signal VSync0: std_logic;
		signal VSync1: std_logic;
		signal VSync2: std_logic;
		signal VSync3: std_logic;
		signal VSync4: std_logic;

begin




--========================================
process(clk,btn0)
begin
	if (btn0='1') then
		data_s2m_d <= (others => '0');
	elsif (clk'event and clk='1') then
		data_s2m_d <= data_s2m;
	end if;
end process;
--========================================

--========================================
process(clk)
begin
	if (clk'event and clk='1') then
		HSync1 <= HSync0;
		HSync2 <= HSync1;
		HSync3 <= HSync2;
		HSync4 <= HSync3;
		HSync <= HSync4;
			
		VSync1 <= VSync0;
		VSync2 <= VSync1;
		VSync3 <= VSync2;
		VSync4 <= VSync3;
		VSync <= VSync4;
	end if;
end process;
--========================================

--=================================================
byte <= data_s2m_d(15 downto 8) when pixel_x(0)='1' else
		  data_s2m_d(7  downto 0) when pixel_x(0)='0';
--=================================================



--=================================================
vgaRed <= "000" when blank = '1' or btn0='1' else
			 byte(7 downto 5); 
			 
vgaGreen <= "000" when blank = '1' or btn0='1' else
				byte(4 downto 2); 

vgaBlue <= "00" when blank = '1' or btn0='1' else
				byte(1 downto 0); 
--=================================================



--=================================================
addr <= sw & pixel_y(8 downto 0) & pixel_x(9 downto 1); 
--=================================================




vga	: entity work.vga_timing(arch_vga) 
				     port map (clk => clk,
									rst => btn0,
									
									HS => HSync0,
									VS => VSync0,
									pixel_x => pixel_x,
									pixel_y => pixel_y,
									--last_column => pixel_y,
									--last_row => pixel_y,
									blank => blank
								  );
								  
								  
sram	: entity work.sramController(sram_arch) 
				     port map (
									clk => clk,
									rst => btn0,
									addr => addr,
									--data_m2s => data_m2s,
									mem => '0',
									rw => '1',
									
									data_s2m => data_s2m,
									data_valid => data_valid,
									--ready => ready,
									MemAdr => MemAdr,
									MemOE => MemOE,
									MemWR => MemWR,
									RamCS => RamCS,
									RamLB => RamLB,
									RamUB => RamUB,
									RamCLK => RamCLK,
									RamADV => RamADV,
									RamCRE => RamCRE,
									MemDB => MemDB	
								  );

end arch_framebuffer;



