
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


--entity declaration===================================================
entity tx is
	generic(
			CLK_RATE: natural := 50_000_000;
			BAUD_RATE: natural := 19200
			);
	port(
		clk: in std_logic;
		rst: in std_logic;
		data_in: in std_logic_vector(7 downto 0);
		send_character: in std_logic;
		tx_out: out std_logic;
		tx_busy: out std_logic
	);
end tx;



--architecture body==================================================
architecture arch_tx of tx is
	function log2c(n: integer) return integer is
		variable m, p: integer;
	begin
		m := 0;
		p := 1;
		while p < n loop
			m := m + 1;
			p := p + 2;
		end loop;
		return m;
	end log2c;

constant BIT_COUNTER_MAX_VAL : Natural := CLK_RATE / BAUD_RATE - 1;
constant BIT_COUNTER_BITS : Natural := 12;--log2c(BIT_COUNTER_MAX_VAL);
signal BIT_TIMER : unsigned(BIT_COUNTER_BITS-1 downto 0);
signal shift: std_logic;
signal load: std_logic;
signal stop: std_logic;
signal start: std_logic;
signal shift_data: std_logic_vector(7 downto 0);
signal tx_bit: std_logic;
signal clrTimer: std_logic;

type mc_state_type is
	(idle, strt, B0, B1, B2, B3, B4, B5, B6, B7, STP, RETRN);
signal trans_reg, trans_next: mc_state_type;
begin

--bit Timer==========================
process(clk,rst)
begin
	if (clk'event and clk='1') then
		if(rst='1') then
			BIT_TIMER <= (others => '0');
		elsif(clrTimer='1') then
			BIT_TIMER <= (others => '0');
		elsif(BIT_TIMER = 2603) then
			tx_bit <= '1';
			BIT_TIMER <= (others => '0');
		elsif(BIT_TIMER=0) then
			tx_bit <= '0';
			BIT_TIMER <= BIT_TIMER + 1;
		else
			BIT_TIMER <= BIT_TIMER + 1;
		end if;
	end if;
end process;
--=============================



--shift Register========================
process(clk,rst)
begin
	if (rst='1') then
		shift_data(0) <= '1';
	elsif (clk'event and clk='1') then
		if(load='1') then
			shift_data <= data_in;
		elsif(shift='1') then
			shift_data <= shift_data(0) & shift_data(7 downto 1);			 
		end if;
	end if;
end process;
--=============================


--Transmit Out ================================
process(clk,rst)
begin
	if (rst='1') then
		tx_out <= '1';
	elsif (clk'event and clk='1') then
		if(start='1') then
			tx_out <= '0';
		elsif(stop='1') then
			tx_out <= '1';
		else
			tx_out <= (shift_data(0));
		end if;
	end if;
end process;
--===================================

--FSM======================================
	process(clk,rst)
	begin
		if(rst='1') then
			trans_reg <= IDLE; 
		elsif(clk'event and clk='1') then
			trans_reg <= trans_next;
		end if;
	end process;
	
	--next state======================
	process(trans_reg, send_character, tx_bit)
	begin		
		case trans_reg is
			when IDLE => 
				if(send_character='1') then
					trans_next <= STRT;
				else
					trans_next <= IDLE;
				end if;
			when STRT =>
				if(tx_bit='1') then
					trans_next <= B0;
				else
					trans_next <= STRT;
				end if;
			when B0 =>
				if(tx_bit='0') then
					trans_next <= B0;
				else
					trans_next <= B1;	
				end if;		
			when B1 =>
				if(tx_bit='0') then
					trans_next <= B1;
				else
					trans_next <= B2;	
				end if;		
			when B2 =>
				if(tx_bit='0') then
					trans_next <= B2;
				else
					trans_next <= B3;	
				end if;		
			when B3 =>
				if(tx_bit='0') then
					trans_next <= B3;
				else
					trans_next <= B4;	
				end if;		
			when B4 =>
				if(tx_bit='0') then
					trans_next <= B4;
				else
					trans_next <= B5;	
				end if;		
			when B5 =>
				if(tx_bit='0') then
					trans_next <= B5;
				else
					trans_next <= B6;	
				end if;		
			when B6 =>
				if(tx_bit='0') then
					trans_next <= B6;
				else
					trans_next <= B7;	
				end if;		
			when B7 =>
				if(tx_bit='0') then
					trans_next <= B7;
				else
					trans_next <= STP;
				end if;			
			when STP =>
				if(tx_bit='0') then
					trans_next <= STP;
				else
					trans_next <= RETRN;	
				end if;		
			when RETRN =>
				if(send_character='1') then
					trans_next <= RETRN;
				else
					trans_next <= IDLE;	
				end if;			
		end case;
	end process;
	
	
	--moore outputs=================
	process(trans_reg)
	begin
		tx_busy <= '1';
		stop <= '0';
		start <= '0';
		clrTimer <= '0';
		case trans_reg is
			when IDLE =>
				tx_busy <= '0';
				stop <= '1';
				clrTimer <= '1';				
			when STRT =>
				start <= '1';				
			when STP =>
				stop <= '1';
			when RETRN =>
				stop <= '1';
			when others =>
--				tx_busy <= '1';
--				stop <= '0';
--				start <= '0';
--				clrTimer <= '0';			
		end case;
	end process;
	
	
--Mealy Outputs=========================
	process(trans_reg, send_character, tx_bit)
	begin
		load <= '0';
		shift <= '0';
		case trans_reg is
			when IDLE =>
				if(send_character='1') then
					load <= '1';
				end if;
			when B0 =>
				if(tx_bit='1') then
					shift <= '1';
				end if;			
			when B1 =>
				if(tx_bit='1') then
					shift <= '1';
				end if;
			when B2 =>
				if(tx_bit='1') then
					shift <= '1';
				end if;			
			when B3 =>
				if(tx_bit='1') then
					shift <= '1';
				end if;			
			when B4 =>
				if(tx_bit='1') then
					shift <= '1';
				end if;			
			when B5 =>
				if(tx_bit='1') then
					shift <= '1';
				end if;			
			when B6 =>
				if(tx_bit='1') then
					shift <= '1';
				end if;			
			when B7 =>
				if(tx_bit='1') then
					shift <= '1';
				end if;
			when others =>
--				load <= '0';
--				shift <= '0';			
		end case;
	end process;





end arch_tx;