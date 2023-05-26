library IEEE; use IEEE.STD_LOGIC_1164.ALL; USE ieee.numeric_std.ALL; 
USE ieee.std_logic_unsigned.ALL;

entity Tb_Calculator is
end Tb_Calculator;

architecture Behavioral of Tb_Calculator is

    component lab_design_top 
    Port (  reset_pin : in STD_LOGIC; clock_pin : in STD_LOGIC;
            serialDataIn_pin : in STD_LOGIC; serialDataOut_pin : out STD_LOGIC;
            LED_hi_pin : out STD_LOGIC; LED_lo_pin : out STD_LOGIC;
            DIP_pins : in STD_LOGIC_VECTOR (3 downto 0)
            
            -- calc vals
--            in1_calc : in STD_LOGIC_VECTOR(7 downto 0);
--            in2_calc : in STD_LOGIC_VECTOR (7 downto 0);
--            op_calc : in STD_LOGIC_VECTOR (7 downto 0)
    );
    end component;

    -- top design signals
    signal reset_pin : STD_LOGIC:= '0'; signal clock_pin : STD_LOGIC := '0';
    signal serialDataIn_pin : STD_LOGIC; signal serialDataOut_pin : STD_LOGIC;
    signal LED_hi_pin : STD_LOGIC; signal LED_lo_pin : STD_LOGIC;
    signal DIP_pins : STD_LOGIC_VECTOR (3 downto 0);
    signal in1_calc_sig : STD_LOGIC_VECTOR (7 downto 0);
    signal in2_calc_sig : STD_LOGIC_VECTOR (7 downto 0);
    signal op_calc_sig : STD_LOGIC_VECTOR (7 downto 0);
    
    constant period : time := 10 ns; constant BIT_period : time := 8680 ns; 
    signal RxData : STD_LOGIC_VECTOR (7 downto 0) := x"35";
    signal RxData2 : STD_LOGIC_VECTOR (7 downto 0) := x"33"; 
    signal RxData_op : STD_LOGIC_VECTOR (7 downto 0) := x"2B"; -- 2A = *, 2B = +, 2D = -, 2F = /, 5E = ^
    -- + , 32,33 | -, 6E, 35 | *, 0A, 0B | /, 6E, 37 or 02 | ^, 0A, 02
    -- 39, 32 (9+2)
    
    -- calc signals
    signal clk : STD_LOGIC := '0';
    signal input1 : STD_LOGIC_VECTOR (7 downto 0); signal input2 : STD_LOGIC_VECTOR (7 downto 0);
    signal operator : STD_LOGIC_VECTOR (7 downto 0);
    signal output_result : STD_LOGIC_VECTOR (7 downto 0):= (others=>'U'); 
    signal done : STD_LOGIC := '0'; 
    signal send_character_from_dec : STD_LOGIC := '0'; 
    signal send_character : STD_LOGIC := '0'; 
    
    signal in1 : STD_LOGIC_VECTOR (7 downto 0);
    signal in2 : STD_LOGIC_VECTOR (7 downto 0);
    signal in3 : STD_LOGIC_VECTOR (7 downto 0);
    
    
begin
------ rst, clk, uut ---------------------------------------------------------------  
    rst: process (clock_pin,reset_pin) -- if rst not = 1, make data out = in
    begin
            -- transmitter has reset condition
            if reset_pin = '1' then
--                serialDataOut_pin <= '0';
                
--            elsif rising_edge(clock_pin) and done = '1' then
--                    serialDataOut_pin <= serialDataIn_pin; 
--            end if; 
            
            elsif rising_edge(clock_pin) then
--                serialDataOut_pin <= serialDataIn_pin;
            end if; 
    end process;

    CLK_P: process  -- clk start = 0
    begin
            clock_pin <= not clock_pin; -- turn clk on/off repeat
            wait for (period/2);
    end process;
   
    UUT: entity work.lab_design_top -- map pins to signal 
    port map (
        reset_pin=>reset_pin, clock_pin=>clock_pin,
        serialDataIn_pin=>serialDataIn_pin, serialDataOut_pin=>serialDataOut_pin,
        LED_hi_pin=>LED_hi_pin, LED_lo_pin=>LED_lo_pin, DIP_pins=>DIP_pins
         -- signal into in_calc
    );
   
    DIP_pins <= "0000"; 
 
    process begin   
------ receive 1 -----------------------------------------------------------------------
        reset_pin <= '1'; wait for 50 ns;
        reset_pin <= '0'; wait for 50 ns;
        
--        serialDataIn_pin <= '1'; -- idle state
--        wait for BIT_period; 
        serialDataIn_pin <= '0'; -- start bit 
        wait for BIT_period; 
        
        for i in 0 to 7 loop -- loop send bits 1 by 1 in a bit period
            serialDataIn_pin <= RxData(i); -- increment 
            wait for BIT_period;
        end loop;
        
        serialDataIn_pin <= '1'; -- stop bit
        wait for BIT_period;
        
        wait until rising_edge(clock_pin); 
        wait for 0 ns;
        
------ receive 2 -----------------------------------------------------------------------
        serialDataIn_pin <= '0'; -- start bit 
        wait for BIT_period; 
        
        for i in 0 to 7 loop
            serialDataIn_pin <= RxData_op(i);
            wait for BIT_period;
        end loop;
        
        serialDataIn_pin <= '1'; -- stop bit
        wait for BIT_period;
        
        wait until rising_edge(clock_pin); 
        wait for 0 ns;

        done <= '0';
 
------ receive 3 -----------------------------------------------------------------------

        serialDataIn_pin <= '0'; -- start bit 
        wait for BIT_period; 
        
        for i in 0 to 7 loop
            serialDataIn_pin <= RxData2(i);
            wait for BIT_period;
        end loop;
        
        serialDataIn_pin <= '1'; -- stop bit
        wait for BIT_period;
        
        wait until rising_edge(clock_pin); 
--        wait for 0 ns;
        
        done <= '1';
        
--------- transmit ----------------------------------------------------------------- 
--        wait until serialDataOut_pin = '0'; --tests, of the serial high to low, need wait until serialin is low, not clk pin
--        assert serialDataOut_pin = '0' 
--            report "Start bit error" severity warning;
            
--        wait for BIT_period; -- wait until find first data bit
----        for i in 0 to 7 loop
----            Tx_Test(i) <= serialDataOut_pin; -- 0th bit to last
----            --serialDataOut_pin <= serialDataIn_pin;
----            wait for BIT_period;
----        end loop;
         
--        wait for BIT_period; -- wait until stop bit
        
--        wait for 0 ns;        
--        assert serialDataOut_pin = '1'
--            report "Stop bit error" severity warning;
       
--       wait for BIT_period; -- wait until stop bit

    end process;
end Behavioral;
