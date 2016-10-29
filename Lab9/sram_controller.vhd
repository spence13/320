library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


--entity declaration===================================================
entity sramController is
	generic(
			CLK_RATE: natural := 50_000_000;
			STARTUP_TIME: natural := 6667
			);
	port(
		clk: in std_logic;
		rst: in std_logic;
		addr: in std_logic_vector(22 downto 0);
		data_m2s: in std_logic_vector(15 downto 0);
		mem: in std_logic;
		rw: in std_logic;
		
		data_s2m: out std_logic_vector(15 downto 0);
		data_valid: out std_logic;
		ready: out std_logic;
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
end sramController;


architecture sram_arch of sramController is

--	function log2c(n: integer) return integer is
--		variable m, p: integer;
--	begin
--		m := 0;
--		p := 1;
--		while p < n loop
--			m := m + 1;
--			p := p + 2;
--		end loop;
--		return m;
--	end log2c;
	
constant BIT_COUNTER_MAX_VAL : Natural := CLK_RATE / STARTUP_TIME;
constant BIT_COUNTER_BITS : Natural := 13;--log2c(BIT_COUNTER_MAX_VAL);
signal BIT_TIMER : unsigned(BIT_COUNTER_BITS-1 downto 0):= (others=>'0');

signal tri_en: std_logic;
signal RaddrEN: std_logic;
signal Rm2sEN: std_logic;
signal Rs2mEN: std_logic;
signal Rm2s:  std_logic_vector(15 downto 0);
signal end_powerup: std_logic;

type sram_state_type is
	(POWERUP, IDLE, R1, R2, R3, R4, W1, W2, W3, W4);
signal sram_reg, sram_next: sram_state_type;

begin

--CONSTANTS===========================================
RamCLK <= '0';
RamADV <= '0';
RamCRE <= '0';
--RamCS <= '0';
RamUB <= '0';
RamLB <= '0';

--BIT TIMER===========================================
process(clk,rst)
begin
	if (clk'event and clk='1') then
		if(rst='1') then
			BIT_TIMER <= (others => '0');		
		elsif(BIT_TIMER = 7500) then
			end_powerup <= '1';
			BIT_TIMER <= (others => '0');
		elsif(BIT_TIMER=0) then
			end_powerup <= '0';
			BIT_TIMER <= BIT_TIMER + 1;
		else
			BIT_TIMER <= BIT_TIMER + 1;
		end if;
	end if;
end process;
--=============================


--Tri-state driver========================================
MemDB <= Rm2s when tri_en = '1' else (others => 'Z');
--========================================


--Address register (Raddr)========================================
process(clk,rst,RaddrEN)
begin
	if (rst='1') then
		MemAdr <= (others => '0');
	elsif (clk'event and clk='1') then
		if(RaddrEN='1') then
			MemAdr <= addr;			 
		end if;
	end if;
end process;
--========================================



--Data out register (Rm2s)========================================
process(clk,rst,Rm2sEN)
begin
	if (rst='1') then
		Rm2s <= (others => '0');
	elsif (clk'event and clk='1') then
		if(Rm2sEN='1') then
			Rm2s <= data_m2s;			 
		end if;
	end if;
end process;
--========================================



--Data in register (Rs2m)========================================
process(clk,rst,Rs2mEN)
begin
	if (rst='1') then
		data_s2m <= (others => '0');
	elsif (clk'event and clk='1') then
		if(Rs2mEN='1') then
			data_s2m <= MemDB;			 
		end if;
	end if;
end process;
--========================================



--Control Path STATE MACHINE========================================
process(clk,rst)
begin
	if(rst='1') then
		sram_reg <= POWERUP; 
	elsif(clk'event and clk='1') then
		sram_reg <= sram_next;
	end if;
end process;

process(sram_reg, end_powerup, mem, rw)
begin		
	
	RamCS <= '0';
	RaddrEN <= '0';
	Rm2sEN <= '0';
	Rs2mEN <= '0';
	data_valid <= '0';
	MemWR <= '1';
	MemOE <= '1';
	tri_en <= '0';
	ready <= '0';

	case sram_reg is	
		when POWERUP => 
			RamCS <= '1';
			ready <= '0';
			if(end_powerup='1') then
				sram_next <= IDLE;
			else
				sram_next <= POWERUP;
			end if;			
		when IDLE => 
			ready <= '1';
			if(mem='0') then
				if(rw='1') then--go to read
					RaddrEN <= '1';
					sram_next <= R1;
				elsif(rw='0') then--go to write
					RaddrEN <= '1';
					Rm2sEN <= '1';
					sram_next <= W1;
				end if;
			else
				sram_next <= IDLE;
			end if;	
			
		when R1 =>
			sram_next <= R2;
		when R2 =>
			MemOE <= '0';
			sram_next <= R3;
		when R3 =>
			MemOE <= '0';
			sram_next <= R4;
		when R4 =>
			MemOE <= '0';
			Rs2mEN <= '1';
			data_valid <= '1';
			sram_next <= IDLE;
			end if;
			
		when W1 =>
			MemWR <= '1';
			sram_next <= W2;
		when W2 =>
			tri_en <= '1';
			MemWR <= '0';
			sram_next <= W3;
		when W3 =>
			tri_en <= '1';
			MemWR <= '0';
			sram_next <= W4;
		when W4 =>
			tri_en <= '1';
			MemWR <= '0';
			sram_next <= IDLE;
		
		
		
	end case;
end process;



end sram_arch;