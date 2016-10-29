library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.util_pkg.all;

entity rx is
	generic(
		CLK_RATE : Natural := 50_000_000;
		BAUD_RATE : Natural := 19_200
	);

	port(
		clk : in std_logic;
		rst : in std_logic := '0';
		rx_in : in std_logic;
		
		data_out : out std_logic_vector(7 downto 0) := (others => '0');
		data_strobe : out std_logic;
		rx_busy : out std_logic
	);
end rx;

architecture uar of rx is
	constant BIT_COUNTER_MAX_VAL : Natural := CLK_RATE / BAUD_RATE - 1;
	constant HALF_BIT_COUNTER_MAX_VAL : Natural := BIT_COUNTER_MAX_VAL/2;
	constant BIT_COUNTER_BITS : Natural := log2c(BIT_COUNTER_MAX_VAL);
	
	signal clrTimer, rx_bit : std_logic;
	signal ctr_reg, ctr_next : unsigned(BIT_COUNTER_BITS-1 downto 0) := (others => '0');
	
	signal shift_en : std_logic;
	signal data_reg, data_next : std_logic_vector(7 downto 0) := (others => '0');
	
	type fsm_states is (idle, strt, reading, stp, valid, power_up);
	signal state_reg, state_next : fsm_states := power_up;
	signal n : unsigned(2 downto 0) := (others => '0');
	
begin
	-- BAUD COUNTER
	-- register
	process(clk, rst, clrTimer, ctr_next, state_reg)
	begin
		if rst = '1' then
			ctr_reg <= (others => '0');
		else
			if clk'event and clk = '1' then
				rx_bit <= '0';
				if clrTimer = '1' then
					ctr_reg <= (others => '0');
				else
					if ctr_next = HALF_BIT_COUNTER_MAX_VAL and state_reg = strt then
						rx_bit <= '1';
					elsif ctr_next = BIT_COUNTER_MAX_VAL then
						rx_bit <= '1';
					end if;
					ctr_reg <= ctr_next;
				end if;
			end if;
		end if;
	end process;
	-- counter next logic
	ctr_next <= ctr_reg + 1 when state_reg = strt and ctr_reg < HALF_BIT_COUNTER_MAX_VAL else
					ctr_reg + 1 when state_reg = reading and ctr_reg < BIT_COUNTER_MAX_VAL else
					ctr_reg + 1 when state_reg = stp and ctr_reg < BIT_COUNTER_MAX_VAL else
					(others => '0');
	clrTimer <= '0' when state_reg = strt or state_reg = reading or state_reg = stp else '1';
					
	-- READ COUNTER
	-- register
	process(clk, rst, state_reg)
	begin
		if rst = '1' then
			n <= (others => '0');
		else
			if clk'event and clk = '1' then
				if state_reg = reading then
					if rx_bit = '1' then
						if n < 7 then
							n <= n + 1;
						else
							n <= (others => '0');
						end if;
					end if;
				end if;
			end if;
		end if;
	end process;
	
	-- SHIFT REGISTER
	-- register
	process(clk, shift_en, rst, data_next)
	begin
		if rst = '1' then
			data_reg <= (others => '0');
		else
			if clk'event and clk = '1' then
				if shift_en = '1' then
					data_reg <= data_next;
				end if;
			end if;
		end if;
	end process;
	-- data next logic
	data_next <= rx_in & data_reg(7 downto 1);
	-- shift enable logic
	shift_en <= '1' when state_reg = reading and rx_bit = '1' else '0';
	
	-- RECEIVER FSM
	-- next state logic
	process(clk, rst, rx_in, rx_bit, state_reg, n)
	begin
		if rst = '1' then
			state_next <= power_up;
		else
			if state_reg = idle then
				state_next <= idle;
				if rx_in = '0' then
					state_next <= strt;
				end if;
			elsif state_reg = strt then
				state_next <= strt;
				if rx_bit = '1' then
					state_next <= reading;
				end if;
			elsif state_reg = reading then
				state_next <= reading;
				if rx_bit = '1' and n = 7 then
					state_next <= stp;
				end if;
			elsif state_reg = stp then
				state_next <= stp;
				if rx_bit = '1' then
					state_next <= valid;
				end if;
			elsif state_reg = valid then
				state_next <= power_up;
			elsif state_reg = power_up then
				state_next <= power_up;
				if rx_in = '1' then
					state_next <= idle;
				end if;
			else
				state_next <= idle;
			end if;
		end if;
	end process;
	
	-- RECEIVER STATE REGISTER
	process(clk)
	begin
		if clk'event and clk = '1' then
			state_reg <= state_next;
		end if;
	end process;
	
	-- RECEIVER OUTPUTS
	rx_busy <= '0' when state_reg = idle else '1';
	data_strobe <= '0' when rst = '1' else
						'1' when state_reg = valid and rx_in = '1' else
						'0';
	data_out <= data_reg;
end uar;