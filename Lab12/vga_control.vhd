library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vga_timing is
	generic(
		H_SYNC : integer := 799;
		H_DISP : integer := 639;
		H_FP : integer := 655;
		H_PW : integer := 751;
		H_BP : integer := 799;
		
		V_SYNC : integer := 520;
		V_DISP : integer := 479;
		V_FP : integer := 489;
		V_PW : integer := 491;
		V_BP : integer := 520
	);

	port(
		clk : in std_logic;
		rst : in std_logic;
		
		HS : out std_logic;
		VS : out std_logic;
		
		pixel_x : out std_logic_vector(9 downto 0);
		pixel_y : out std_logic_vector(9 downto 0);
		last_column : out std_logic;
		last_row : out std_logic;
		blank : out std_logic
	);
end vga_timing;

architecture VGAC_arch_1 of vga_timing is
	signal pixel_en : std_logic := '0';
	
	signal h_reg, h_next : integer := 0;
	signal h_pulse : std_logic := '0';
	
	signal v_reg, v_next : integer := 0;
	
begin
	-- PIXEL_EN (clk divider)
	process(clk)
	begin
		if clk'event and clk = '1' then
			pixel_en <= not(pixel_en);
		end if;
	end process;
	
	-- HORIZONTAL PIXEL COUNTER
	-- horizontal counter next state logic
	h_next <= h_reg + 1 when h_reg < H_SYNC else 0;
	-- horizontal counter register
	process(clk, pixel_en, rst)
	begin
		if clk'event and clk = '1' then
			if rst = '1' then
				h_reg <= 0;
			elsif pixel_en = '1' then
				h_reg <= h_next;
				if h_next = H_SYNC then
					h_pulse <= '1';
				else
					h_pulse <= '0';
				end if;
			end if;
		end if;
	end process;
	-- HS output decoder (high except during pulse phase)
	HS <= '0' when (h_reg > H_FP) and (h_reg <= H_PW) else '1';
	-- last_column pulse
	last_column <= '1' when h_reg = H_DISP else '0';
	
	-- VERTICAL LINE COUNTER
	-- horizontal counter next state logic
	v_next <= v_reg + 1 when v_reg < V_SYNC else 0;
	-- horizontal counter register
	process(clk, pixel_en, h_pulse, rst)
	begin
		if clk'event and clk = '1' then
			if rst = '1' then
				v_reg <= 0;
			elsif pixel_en = '1' and h_pulse = '1' then
				v_reg <= v_next;
			end if;
		end if;
	end process;
	VS <= '0' when (v_reg > V_FP) and (v_reg <= V_PW) else '1';
	-- last row pulse
	last_row <= '1' when v_reg = V_DISP else '0';
	
	-- BLANK LOGIC
	blank <= '1' when h_reg > H_DISP or v_reg > V_DISP else '0';
	
	-- OUTPUT LOGIC
	pixel_x <= std_logic_vector(to_unsigned(h_reg, 10));
	pixel_y <= std_logic_vector(to_unsigned(v_reg, 10));
end VGAC_arch_1;