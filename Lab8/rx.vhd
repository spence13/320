library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


--entity declaration===================================================
entity rx is
	generic(
			CLK_RATE: natural := 50_000_000;
			BAUD_RATE: natural := 19_200
			);
	port(
		clk: in std_logic;
		rst: in std_logic;
		rx_in: in std_logic;
		
		data_out: out std_logic_vector(7 downto 0);
		data_strobe: out std_logic;
		rx_busy: out std_logic
	);
end rx;


--architecture body==================================================
architecture rx_arch of rx is

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
	
constant BIT_COUNTER_MAX_VAL : Natural := CLK_RATE / BAUD_RATE - 1;
constant BIT_COUNTER_BITS : Natural := 12;--log2c(BIT_COUNTER_MAX_VAL);
signal BIT_TIMER : unsigned(BIT_COUNTER_BITS-1 downto 0):= (others=>'0');

signal bit_number: unsigned(3 downto 0) := (others => '0');
signal bit_number_next: unsigned(3 downto 0) := (others => '0');
signal shift: std_logic;
signal rx_bit: std_logic;
signal rx_bit_half: std_logic;
signal rx_bit_start: std_logic;
signal clrTimer: std_logic;
signal shift_data: std_logic_vector(7 downto 0):= "00000000";

type rx_state_type is
	(POWERUP, IDLE, START, DATA, STOP);
signal rx_reg, rx_next: rx_state_type;

begin

--BIT TIMER==========================
process(clk,rst)
begin
	if (clk'event and clk='1') then
		if(rst='1') then
			BIT_TIMER <= (others => '0');
			rx_bit_start <= '0';
		elsif(clrTimer='1') then
			BIT_TIMER <= (others => '0');
			rx_bit_start <= '0';
		elsif(BIT_TIMER = 2602/2) then
			rx_bit_half <= '1';
			BIT_TIMER <= BIT_TIMER + 1;
		elsif(BIT_TIMER = 1302) then
			rx_bit_half <= '0';
			BIT_TIMER <= BIT_TIMER + 1;			
		elsif(BIT_TIMER = 2603) then
			rx_bit_start <= '1';
			rx_bit <= '1';
			BIT_TIMER <= (others => '0');
		elsif(BIT_TIMER=0) then
			rx_bit <= '0';
			BIT_TIMER <= BIT_TIMER + 1;
		else
			BIT_TIMER <= BIT_TIMER + 1;
		end if;
	end if;
end process;
--=============================


--SHIFT REGISTER PACKAGING========================
process(clk,rst)
begin
	if (rst='1') then
		shift_data <= "00000000";
	elsif (clk'event and clk='1') then
		if(shift='1') then
			shift_data <= rx_in & shift_data(7 downto 1);			 
		end if;
	end if;
end process;
--=============================

--Transmit Out ================================
process(clk,rst)
begin
	if (rst='1') then
		data_out <= "00000000";
	elsif (clk'event and clk='1') then
		data_out <= shift_data;
	end if;
end process;
--===================================


--FSM============================================

--register======
process(clk,rst)
begin
	if(rst='1') then
		rx_reg <= POWERUP; 
		bit_number <= (others => '0');
	elsif(clk'event and clk='1') then
		rx_reg <= rx_next;
		bit_number <= bit_number_next;
	end if;
end process;

--next state=======
process(rx_reg, rx_bit, rx_bit_half, rx_in, rx_bit_start, bit_number)
begin		
	rx_next <= rx_reg;
	case rx_reg is	
		when POWERUP => 
			if(rx_in='1') then
				rx_next <= IDLE;
			else
				rx_next <= POWERUP;
			end if;			
		when IDLE => 
			if(rx_in='0') then
				rx_next <= START;
			else
				rx_next <= IDLE;
			end if;		
		when START =>
			if(rx_bit_half='1') then
				if(rx_bit_start='1') then
					rx_next <= DATA;
				else
					rx_next <= START;
				end if;
			else
				rx_next <= START;
			end if;		
		when DATA =>
			if(bit_number=8) then
				rx_next <= STOP;
			else
				rx_next <= DATA;	
			end if;			
		when STOP =>
			if(rx_in='1') then
				rx_next <= IDLE;
			else
				rx_next <= STOP;	
			end if;
	end case;
end process;





--mealy outputs==============
process(rx_reg, rx_bit, rx_bit_half, rx_in, rx_bit_start, bit_number)
begin		

	shift <= '0';
	data_strobe <= '0';
	clrTimer <='0';
	rx_busy <= '1';
	bit_number_next <= bit_number;
	
	case rx_reg is
	
		when POWERUP => 
		rx_busy <= '0';
		
		when IDLE => 
		clrTimer <='1'; --moore output
		rx_busy <= '0';
			if(rx_in='0') then
				rx_busy <= '1';
			end if;
			
		when START =>
			if(rx_bit_half='1') then
				if(rx_bit_start='1') then
					shift <= '1';
				end if;
			end if;
			
		when DATA =>
			if(bit_number=8) then
				bit_number_next <= (others => '0');	
			elsif(rx_bit_half='1') then
				if(bit_number=7) then
					shift <= '0';
					bit_number_next <= bit_number + 1;	
				else
					shift <= '1';
					bit_number_next <= bit_number + 1;
				end if;
			end if;	
			
		when STOP =>
			if(rx_in='1') then
				data_strobe <= '1';
			end if;		
		
	end case;
end process;

--=======================================





end rx_arch;