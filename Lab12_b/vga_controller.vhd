
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--entity declaration===================================================
entity vga_timing is
	generic(
			COUNTER_BITS: natural :=10
			);
	port(
		clk: 		in std_logic;
		rst: 		in std_logic;
		HS:   	out std_logic;
		VS: 		out std_logic;
		pixel_x: out std_logic_vector(9 downto 0);
		pixel_y: out std_logic_vector(9 downto 0);
		last_column: out std_logic;
		last_row: 	 out std_logic;
		blank: 		 out std_logic
	);
end vga_timing;


--architecture body==================================================
architecture arch_vga of vga_timing is
	signal pixel_en: std_logic;
	signal column_counter: unsigned(COUNTER_BITS-1 downto 0) := (others => '0');
	signal row_counter: unsigned(COUNTER_BITS-1 downto 0) := (others => '0');
	signal reg_next: unsigned(COUNTER_BITS-1 downto 0) := (others => '0');
begin


--BOARD CLOCK==============================
process(clk,rst)
begin
		if(rst='1') then
			pixel_en <= '0';
		elsif (clk'event and clk='1') then
			pixel_en <= not(pixel_en);
		end if;
end process;--=============================





--COLUMN COUNTER==================================
process(clk,rst)
begin
		if(rst='1') then
			column_counter <= (others => '0');
		elsif (clk'event and clk='1' and pixel_en='1') then
			if(column_counter=799) then
				column_counter <= (others => '0');
			else
			column_counter <= column_counter + 1;
			end if;
		end if;
end process;--===========

pixel_x <= std_logic_vector(column_counter);

HS <= '1' when (column_counter<656) or (column_counter> 751) else
		'0';


last_column <= '1' when column_counter=639 else
					'0';
--=======================================================





--ROW COUNTER==================================
process(clk,rst)
begin
		if(rst='1') then
			row_counter <= (others => '0');
		elsif (clk'event and clk='1' and pixel_en='1') then
			if(row_counter=520 and column_counter=799) then
				row_counter <= (others => '0');
			else
			row_counter <= reg_next;
			end if;
		end if;
end process;--===============

reg_next <= row_counter + 1 when column_counter=799 else
				row_counter;

pixel_y <= std_logic_vector(row_counter);

VS <= '1' when (row_counter<490) or (row_counter>491) else
		'0';

last_row <= '1' when row_counter=479 else
				'0';
--=======================================================


blank <= '1' when (column_counter > 639) or (row_counter > 479) else
			'0';

	

end arch_vga;

















