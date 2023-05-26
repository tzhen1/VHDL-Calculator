library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
USE ieee.numeric_std.ALL;

entity lab_design_top is
    Port (  reset_pin : in STD_LOGIC;
            clock_pin : in STD_LOGIC;
            serialDataIn_pin : in STD_LOGIC;
            serialDataOut_pin : out STD_LOGIC;
            LED_hi_pin : out STD_LOGIC;
            LED_lo_pin : out STD_LOGIC;
            DIP_pins : in STD_LOGIC_VECTOR (3 downto 0)
            
--            -- inputs to calc, change in uart tb
--            in1_calc : in STD_LOGIC_VECTOR(7 downto 0);
--            in2_calc : in STD_LOGIC_VECTOR (7 downto 0);
--            op_calc : in STD_LOGIC_VECTOR (7 downto 0)
            
    );
end lab_design_top;

architecture structural of lab_design_top is use work.uart_components.all;
    signal parallelDataOut : std_logic_vector(7 downto 0) := (others=>'U');
    signal dataValid : std_logic := '0';
    signal parallelDataIn : std_logic_vector(7 downto 0) := (others=>'U');
    signal transmitRequest : std_logic := '0';
    signal tx_ready : std_logic := '0'; 
    signal send_character : std_logic := '0';
    signal character_to_send : std_logic_vector(7 downto 0) := (others=>'0'); -- holding data to send
    signal DIP_debounced : std_logic_vector(3 downto 0) := (others=>'0');
    signal gnd : std_logic := '0';
    
    -- calc sig
    signal character_to_send_calc : std_logic_vector(7 downto 0) := (others=>'0'); 
    signal send_character_calc : std_logic := '0';
    signal Data_to_calc : std_logic_vector(7 downto 0) := (others=>'U');
    
    component calculator 
    Port(   clk: in STD_LOGIC;
            reset: in STD_LOGIC;
            input1: in std_logic_vector(7 downto 0);
            output_result: out std_logic_vector(7 downto 0);
            dataValid_uart : in STD_LOGIC;
            send_character : out STD_LOGIC

    );
    end component;
    
    -- signals from dec to calc
    signal dec_to_calc : std_logic_vector(7 downto 0) := (others=>'0'); -- input to calc
    -- signals from calc to enc
    signal calc_to_enc : std_logic_vector(7 downto 0) := (others=>'0');
    
begin
    make_UART: UART -- rx, tx
        generic map (BAUD_RATE => 115200, -- 9600
            CLOCK_RATE => 50000000) -- 40MHz, change to 50 MHz for FPGA from 100MHz
        port map(reset => reset_pin,
            clock => clock_pin,
            serialDataIn => serialDataIn_pin,
            parallelDataOut => parallelDataOut, -- from rcvr, tooutput serial data out, 1 bits
            dataValid => dataValid, -- useful, useful data
            parallelDataIn => parallelDataIn,
            transmitRequest => transmitRequest,
            txIsReady => tx_ready,
            serialDataOut => serialDataOut_pin
        );
            
    -- receive ascii from uart, decode into hex to 
    -- std_logic, lect 8, next state logic, reg to hold state,clk trig

    decoder: character_decoder 
    generic map (CLOCK_FREQUENCY => 50_000_000) -- 40MHz
    port map(clk => clock_pin,
        charFromUART_valid => dataValid, -- puts uart valid result into datavalid signal
        charFromUART => parallelDataOut, -- received from uart, parallelDataOut, if use calc_to_enc, straight through
        LED_hi => LED_hi_pin,
        LED_lo => LED_lo_pin,
        send_character => send_character_calc, -- when finish decode, ready to send = 1
        character_to_send => Data_to_calc -- send to calc, not working?
    );
        
    calc: calculator -- map calc sigs together
    port map (   
        clk=>clock_pin, reset=>reset_pin,
        input1=>parallelDataOut, -- inputs
        output_result=>calc_to_enc, -- send result from module to sig
        dataValid_uart => dataValid,
        send_character => send_character -- when finish decode, ready to send = 1
    );
    
    encoder: character_encoder
        port map(clk => clock_pin,
            character_decoded => send_character,
            character_to_send => calc_to_enc, -- character_to_send, o/p from calc, i/p to encoder
            tx_ready => tx_ready,
            parallelDataIn => parallelDataIn, -- i/p to transmitter to transmit
            transmitRequest => transmitRequest,
            DIP_dbncd => DIP_debounced
        );
            
    DIP_debouncers: for i in 0 to 3 generate -- 3 dncr
        dbncr: debouncer
            generic map (DELAY_VALUE => 100) -- 4,000,000
            port map(clk => clock_pin,
                    signal_in => DIP_pins(i),
                    signal_out => DIP_debounced(i)
            );           
    end generate DIP_debouncers;
    
end structural;
