LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;


entity top is
	generic(
			TOP_COUNTER_BITS: natural :=32
			);
	port(
			top_clk: in std_logic;
			top_btn: in std_logic_vector(3 downto 0);
			top_sw: in std_logic_vector(7 downto 0);
			top_seg: out std_logic_vector(6 downto 0);
			top_dp: out std_logic;
			top_an: out std_logic_vector(3 downto 0)
		);
	end top;
	

architecture top_arch of top is
	signal top_counter: unsigned(TOP_COUNTER_BITS-1 downto 0) := (others => '0');
	signal top_data_in: std_logic_vector(15 downto 0);
	signal top_dp_in: std_logic_vector(3 downto 0);
	signal top_blank: std_logic_vector(3 downto 0);
	signal tmp_counter: std_logic_vector(TOP_COUNTER_BITS-1 downto 0);
begin

--counter------------------
process(top_clk)
begin
	if (top_clk'event and top_clk='1') then
		top_counter <= top_counter + 1;
		tmp_counter <= std_logic_vector(top_counter);
	end if;
end process;


top_data_in <= "0000000000000000" when top_btn="1000" else
					"1011111011101111" when top_btn="0100" else
				   "00000000" & top_sw(7 downto 4) & top_sw(3 downto 0) when top_btn="0010" else
					tmp_counter(15 downto 0) when top_btn="0001" else
					tmp_counter(31 downto 16) when top_btn="0000";
					
top_dp_in <= "0000" when top_btn="1000" else
				 "0000" when top_btn="0100" else
				 "0010" when top_btn="0010" else
				 "1111" when top_btn="0001" else
				 "1000" when top_btn="0000";



top_blank <= "1111" when top_btn="1000" else
				 "0000" when top_btn="0100" else
				 "1100" when top_btn="0010" else
				 "0000" when top_btn="0001" else
				 "0000" when top_btn="0000" ;




seven_seg_one	: entity work.seven_segment_control(ssc_arch) 
				     port map (clk => top_clk,

									data_in => top_data_in,
									dp_in => top_dp_in,
									blank => top_blank,
									
									seg => top_seg,
									dp => top_dp,								
									an => top_an
								  );


end top_arch;




