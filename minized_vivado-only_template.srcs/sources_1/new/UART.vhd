library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
USE ieee.numeric_std.ALL;

entity UART is
generic(BAUD_RATE : integer := 115200; --9600
        CLOCK_RATE : integer := 50000000); --25MHz, change to 100MHz
        
port (  reset : in STD_LOGIC;
        clock : in STD_LOGIC;
        serialDataIn : in STD_LOGIC;
        parallelDataOut : out STD_LOGIC_VECTOR (7 downto 0); -- output from trans to pc
        dataValid : out STD_LOGIC;
        parallelDataIn : in STD_LOGIC_VECTOR (7 downto 0);
        transmitRequest : in STD_LOGIC;
        txIsReady : out STD_LOGIC;
        serialDataOut : out STD_LOGIC
    );
    
end entity UART;

architecture Behavioral of UART is use work.uart_components.all;
    signal baudRateEnable : std_logic := '0';
    signal baudRateEnable_x16 : std_logic := '0'; -- uninitialised, U

begin

    rateGen: UART_baudRateGenerator 
        generic map (BAUD_RATE => BAUD_RATE,
                     CLOCK_RATE => CLOCK_RATE)
        port map(
            reset => reset,
            clock => clock,
            baudRateEnable => baudRateEnable,
            baudRateEnable_x16 => baudRateEnable_x16 --16x oversampling, detect middle of bit period
        );
    
    xmit: UART_transmitter 
        port map(
            reset => reset,
            clock => clock,
            baudRateEnable => baudRateEnable,
            parallelDataIn => parallelDataIn,
            transmitRequest => transmitRequest,
            ready => txIsReady,
            serialDataOut => serialDataOut
        );
    rcvr: UART_receiver 
        port map(
            reset => reset,
            clock => clock,
            baudRateEnable_x16 => baudRateEnable_x16,
            serialDataIn => serialDataIn,
            parallelDataOut => parallelDataOut,
            dataValid => dataValid
        );
end architecture Behavioral;