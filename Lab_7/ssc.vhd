

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--entity declaration===================================================
entity seven_segment_control is
	generic(
			COUNTER_BITS: natural :=15
			);
	port(
		clk: in std_logic;
		data_in: in std_logic_vector(15 downto 0);
		dp_in: in std_logic_vector(3 downto 0);
		blank: in std_logic_vector(3 downto 0);
		seg: out std_logic_vector(6 downto 0);
		dp: out std_logic;
		an: out std_logic_vector(3 downto 0)
	);
end seven_segment_control;
		
		
--architecture body==================================================
architecture ssc_arch of seven_segment_control is
	signal counter: unsigned(COUNTER_BITS-1 downto 0) := (others => '0');
	signal anode_select: std_logic_vector(1 downto 0);
	signal tmp:std_logic_vector(COUNTER_BITS-1 downto 0);
	signal seven_seg_in : std_logic_vector(3 downto 0);
begin

--counter------------------
process(clk)
begin
	if (clk'event and clk='1') then
		counter <= counter + 1;
		tmp <= std_logic_vector(counter);
		anode_select <= tmp(COUNTER_BITS-1 downto COUNTER_BITS-2);
	end if;
end process;


an <= "1111" when anode_select="00"  and blank(0)='1' else
		"1110" when anode_select="00" else
		"1111" when anode_select="01"  and blank(1)='1' else
		"1101" when anode_select="01"  else
		"1111" when anode_select="10"  and blank(2)='1' else
	   "1011" when anode_select="10"  else
		"1111" when anode_select="11"  and blank(3)='1' else
      "0111" when anode_select="11"  else
	   "1111";


seven_seg_in <= data_in(3 downto 0) when anode_select="00" else
					 data_in(7 downto 4) when anode_select="01" else
				 	 data_in(11 downto 8) when anode_select="10" else
					 data_in(15 downto 12);
					 				 
with seven_seg_in select seg <=
    "1000000" when "0000",
    "1111001" when "0001",
    "0100100" when "0010",
    "0110000" when "0011",
	 "0011001" when "0100",
	 "0010010" when "0101",
	 "0000010" when "0110",
	 "1111000" when "0111",
	 "0000000" when "1000",
	 "0010000" when "1001",
	 "0001000" when "1010",
	 "0000011" when "1011",
	 "1000110" when "1100",
	 "0100001" when "1101",
	 "0000110" when "1110",
	 "0001110" when others;

dp <= not(dp_in(0)) when anode_select="00" else
	   not(dp_in(1)) when anode_select="01" else
		not(dp_in(2)) when anode_select="10" else
		not(dp_in(3));

end ssc_arch;