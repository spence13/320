
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
		rst: in std_logic;
		switches: in std_logic_vector(7 downto 0);
		--btn: in std_logic_vector(3 downto 0);
		btn_3: in std_logic;
		btn_0: in std_logic;
		send_character: in std_logic;
		tx_out: out std_logic;
		tx_busy: out std_logic;
		
		seg: out std_logic_vector(6 downto 0);
		dp: out std_logic;
		an: out std_logic_vector(3 downto 0)
		
	);
end top;


architecture top_arch of top is

constant count_value : natural := CLK_RATE / SAMPLE_FREQ;
signal counter : unsigned(COUNTER_BITS-1 downto 0):= (others =>'0');
signal debounced: std_logic;

begin



process(clk,rst)
begin
	if(rst='1') then
		counter <= (others => '0');
	elsif (clk'event and clk='1') then
		if(counter = count_value) then 
			debounced <= btn_0;
			counter <= (others => '0');
		elsif(counter < count_value) then
			counter <= counter + 1;
		end if;
	end if;
end process;









tx_one	: entity work.tx(arch_tx) 
				     port map (clk => clk,	
									data_in => switches,
									send_character => debounced,
									rst => btn_3,
									tx_out => tx_out,
									tx_busy => tx_busy
									
								  );
								  
								  
seven_seg_one	: entity work.seven_segment_control(ssc_arch) 
				     port map (clk => clk,
									data_in(15 downto 8) => "00000000",
									data_in(7 downto 0) => switches,
									
									dp_in => "0000",
								   blank => "0000",
									
									seg => seg,
									dp => dp,								
									an => an
								  );

end top_arch;










