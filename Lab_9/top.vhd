
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


--entity declaration===================================================
entity top is

	port(
		clk: in std_logic;
		btn: in std_logic_vector(3 downto 0);
		switches: in std_logic_vector(7 downto 0);
		
		MemAdr: out std_logic_vector(22 downto 0);
		MemDB: inout std_logic_vector(15 downto 0);	
		MemOE: out std_logic;
		MemWR: out std_logic;--WE
		RamCS: out std_logic;--CE
		RamLB: out std_logic;
		RamUB: out std_logic;
		RamCLK: out std_logic;
		RamADV: out std_logic;
		RamCRE: out std_logic;

		
		seg: out std_logic_vector(6 downto 0);
		dp: out std_logic;
		an: out std_logic_vector(3 downto 0)
		
	);
end top;



--architecture declaration===================================================
architecture top_arch of top is

signal AR: std_logic_vector(7 downto 0);
signal AR_23: std_logic_vector(22 downto 0);
signal IDR: std_logic_vector(7 downto 0);
signal data_m2s: std_logic_vector(15 downto 0);
signal data_s2m: std_logic_vector(15 downto 0);
signal rst: std_logic;
signal mem: std_logic := '1';
signal rw: std_logic;


begin

process(clk,rst,btn)
begin
	if (rst='1') then
		AR <= (others => '0');
	elsif (clk'event and clk='1') then
		if(btn(0)='1') then
			AR <= switches;			 
		end if;
	end if;
	AR_23 <= "000000000000000" & AR;
end process;

process(clk,rst,btn)
begin
	if (rst='1') then
		IDR <= (others => '0');
	elsif (clk'event and clk='1') then
		if(btn(1)='1') then
			IDR <= switches;			 
		end if;
	end if;
	data_m2s <= IDR & IDR;
end process;

rst <= '1' when btn(3)='1' and btn(2)='1' and btn(1)='1' and btn(0)='1' else
		 '0';

mem <= '0' when btn(3)='1' or btn(2)='1' else
		 '1';

rw <= '1' when btn(3)='1' else
		'0';



controller	: entity work.sramController(sram_arch) 
				     port map (	
										clk => clk,
										rst => rst,
										addr => AR_23,
										data_m2s => data_m2s,
										mem => mem,
										rw => rw,
										
										data_s2m => data_s2m,
--										data_valid =>
--										ready =>
										MemAdr => MemAdr,
										MemOE => MemOE,

										MemWR => MemWR,
										RamCS => RamCS,
										RamLB => RamLB,
										RamUB => RamUB,
										RamCLK => RamCLK,
										RamADV => RamADV,
										RamCRE => RamCRE,
										MemDB =>	MemDB	
								  );
			  
								  
seven_seg_one	: entity work.seven_segment_control(ssc_arch) 
				     port map (clk => clk,
									data_in => data_s2m,
									dp_in => "0000",
								   blank => "0000",
									
									seg => seg,
									dp => dp,								
									an => an
								  );

end top_arch;






