
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


--entity declaration===================================================
entity top is
	generic(
			CLK_RATE: natural := 50_000_000;
			SAMPLE_FREQ: natural := 100;
			COUNTER_BITS: natural := 19
			);
	port(
		clk: in std_logic;
		btn_3: in std_logic;
		rx_in: in std_logic;
		
		rx_busy: out std_logic;
		
		seg: out std_logic_vector(6 downto 0);
		dp: out std_logic;
		an: out std_logic_vector(3 downto 0)
		
	);
end top;


architecture top_arch of top is

signal rx_in_d: std_logic;
signal rx_in_dd: std_logic;
signal data_out: std_logic_vector(7 downto 0);
signal disp: std_logic_vector(15 downto 0):= (others => '0');
signal data_strobe:  std_logic;


begin


--SYNCHRONIZERS for RX_IN================================
process(clk)
begin
	if(clk'event and clk='1') then
		rx_in_d <= rx_in;
	end if;
end process;

process(clk)
begin
	if(clk'event and clk='1') then
		rx_in_dd <= rx_in_d;
	end if;
end process;
--======================================

--SEVEN SEG DISP REGULATOR==============================
process(clk,btn_3)
begin
	if(btn_3='1') then
		disp(7 downto 0) <= (others => '0');
		disp(15 downto 8) <= (others => '0');
	elsif(clk'event and clk='1') then
		if(data_strobe='1') then
			disp(7 downto 0) <= data_out;
			disp(15 downto 8) <= disp(7 downto 0);
		end if;
	end if;
end process;






rx_one	: entity work.rx(rx_arch) 
				     port map (clk => clk,	
									rst => btn_3,									
									rx_in => rx_in_dd,				
									
									data_out => data_out,
									data_strobe => data_strobe,
									rx_busy => rx_busy		
								  );
			  
								  
seven_seg_one	: entity work.seven_segment_control(ssc_arch) 
				     port map (clk => clk,
									data_in => disp,
									dp_in => "0000",
								   blank => "0000",
									
									seg => seg,
									dp => dp,								
									an => an
								  );

end top_arch;






