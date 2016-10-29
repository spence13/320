

library ieee;
use ieee.std_logic_1164.all;

--entity declaration
entity seven_seg_decode is
	port(
		sw: in std_logic_vector(7 downto 0);
		btn: in std_logic_vector(3 downto 0);
		seg: out std_logic_vector(6 downto 0);
		dp: out std_logic;
		an: out std_logic_vector(3 downto 0)
	);
end seven_seg_decode;
		
		
--architecture body
architecture ssd_arch of seven_seg_decode is
	signal seven_seg_in : std_logic_vector(3 downto 0);
begin

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

dp <= '0' when btn(3) = '1' else
	   '1' when btn(2) = '1' else
		'1';

seven_seg_in <= "1000" when btn(3) = '1' else
					 sw(3)&sw(2)&sw(1)&sw(0) when btn(1)='0' and btn(0)='0' else
					 sw(7)&sw(6)&sw(5)&sw(4) when btn(1)='0' and btn(0)='1' else
					 sw(7)&sw(6)&sw(5)&sw(4) xor sw(3)&sw(2)&sw(1)&sw(0) when btn(1)='1' and btn(0)='0' else
					 sw(1)&sw(0)&sw(3)&sw(2);

an <= "0000" when btn(3)='1' else
		"1111" when btn(2)='1' else
		"1110" when btn(1)='0' and btn(0)='0' else
	   "1101" when btn(1)='0' and btn(0)='1' else
      "1011" when btn(1)='1' and btn(0)='0' else
	   "0111";


end ssd_arch;