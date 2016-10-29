library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.util_pkg.all;

entity sramController is
	generic(
		CLK_RATE 	: natural := 50_000_000
	);
	
	port(
		-- TO/FROM MEMORY
		clk 			: in std_logic;
		rst 			: in std_logic;
		addr 			: in std_logic_vector(22 downto 0);
		data_m2s 	: in std_logic_vector(15 downto 0);
		mem 			: in std_logic;
		rw 			: in std_logic;
		data_s2m		: out std_logic_vector(15 downto 0);
		data_valid	: out std_logic;
		
		-- TO/FROM SRAM
		ready			: out std_logic;
		MemAdr		: out std_logic_vector(22 downto 0);
		MemOE			: out std_logic;
		MemWR			: out std_logic;
		RamCS			: out std_logic := '1';
		RamLB			: out std_logic := '0';
		RamUB			: out std_logic := '0';
		RamCLK		: out std_logic := '0';
		RamADV		: out std_logic := '1';
		RamCRE		: out std_logic := '1';
		MemDB			: inout std_logic_vector(15 downto 0)
	);
end sramController;

architecture asynch_sram of sramController is
	signal Raddr 		: std_logic_vector(MemAdr'range) := (others => '0');
	signal Rm2s 		: std_logic_vector(data_m2s'range) := (others => '0');
	signal Rs2m 		: std_logic_vector(data_s2m'range) := (others => '0');
	signal tri_en 		: std_logic;
	
	type control_path_states is (power_up, idle, r1, r2, r3, r4, w1, w2, w3, w4);
		-- from preliminary questions, read takes 4 clocks and we should be low asserted for 3 clocks to achieve a write
	signal state_reg	: control_path_states;
	signal state_next : control_path_states;
	
	constant PU_FREQ  : natural := 6666;
	constant PU_MAX	: natural := CLK_RATE / PU_FREQ;
	constant PU_BITS 	: natural := log2c(PU_MAX);
	signal pu_count	: unsigned(PU_BITS-1 downto 0) := (others => '0');
	signal pu_en		: std_logic := '0';
begin
	-- CONTROL PATH
	-- state next logic
	state_next <= idle when state_reg = power_up and pu_count = PU_MAX else
		idle when state_reg = idle and mem /= '0' else
		r1 when (state_reg = idle or state_reg = r4) and mem = '0' and rw = '1' else
		r2 when state_reg = r1 else
		r3 when state_reg = r2 else
		r4 when state_reg = r3 else
		idle when state_reg = r4 else
		w1 when state_reg = idle and mem = '0' and rw = '0' else
		w2 when state_reg = w1 else
		w3 when state_reg = w2 else
		w4 when state_reg = w3 else
		idle when state_reg = w4 else
		power_up;
	
	-- power up counter
	process(clk, pu_en)
	begin
		if clk'event and clk = '1' then
			if pu_en = '1' then
				pu_count <= pu_count + 1;
			end if;
		end if;
	end process;
	
	-- outputs
	pu_en <= '1' when state_reg = power_up else '0';
	data_s2m <= Rs2m;
	data_valid <= '1' when state_reg = r4 else '0';
	ready <= '1' when state_reg = idle else '0';
	MemAdr <= Raddr;
	MemOE <= '0' when state_reg = r1 or state_reg = r2 or state_reg = r3 or state_reg = r4 else '1';
	MemWR <= '0' when state_reg = w2 or state_reg = w3 or state_reg = w4 else '1';
	RamCS <= '1' when state_reg = power_up else '0';
	RamLB <= '0';
	RamUB <= '0';
	RamCLK <= '0';
	RamADV <= '0';
	RamCRE <= '0';
	tri_en <= '1' when state_reg = w3 or state_reg = w4 else '0';
		
	-- STATE REGISTER
	process(clk, rst, state_next)
	begin
		if rst = '1' then
			if state_next /= power_up then
				state_reg <= idle;
			end if;
		else
			if clk'event and clk = '1' then
				state_reg <= state_next;
			end if;
		end if;
	end process;
	
	-- DATA/ADDR REGISTERS
	process(clk, rst, state_reg, mem, rw, addr, data_m2s, MemDB)
	begin
		if rst = '1' then
			Raddr <= (others => '0');
			Rm2s <= (others => '0');
			Rs2m <= (others => '0');
		else
			if clk'event and clk = '1' then
				if state_reg = idle and mem = '0' then
					Raddr <= addr;
					if rw = '0' then
						Rm2s <= data_m2s;
					end if;
				elsif state_reg = r4 then
					Rs2m <= MemDB;
					if mem = '0' and rw = '1' then
						Raddr <= addr;
					end if;
				end if;
			end if;
		end if;
	end process;
	
	-- TRI-STATE DRIVER
	MemDB <= Rm2s when tri_en = '1' else (others => 'Z');
end asynch_sram;