library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
USE ieee.numeric_std.ALL;

entity UART_transmitter is
Port (  reset : in STD_LOGIC;
        clock : in STD_LOGIC;
        baudRateEnable : in STD_LOGIC; -- enable baud rate, so ready to start
        parallelDataIn : in STD_LOGIC_VECTOR (7 downto 0); -- data send
        transmitRequest : in STD_LOGIC; 
        ready : out STD_LOGIC;
        serialDataOut : out STD_LOGIC
        );
end entity UART_transmitter;

architecture Behavioral of UART_transmitter is
    type legalStates is (IDLE, SEND_START_BIT, SEND_DATA_BITS, SEND_STOP_BIT);
    signal txState : legalStates := IDLE;
begin

    tx_sm: process (clock)
        variable dataToTX : std_logic_vector(7 downto 0); -- send data
        variable bitToSend : integer range 0 to 7 := 0;
        variable go : std_logic := '0';
    begin
        syncEvents: if rising_edge(clock) then
            resetRun: if (reset = '1') then
                txState <= IDLE;
                ready <= '0';
                go := '0';
                serialDataOut <= '1';
                
    else
        catchStart: if (transmitRequest = '1') then -- from encode
            go := '1';
            dataToTx := parallelDataIn; -- parallel data sent out from user
        end if catchStart;
    
        smEnabled: if (baudRateEnable = '1') then -- baud enable when correct rate
            sm: case (txState) is
                when IDLE =>
                    ready <= '1';
                    serialDataOut <= '1';
                    timeToStart: 
                        if (go = '1') then -- tranmit request high, go is high
                            go := '0';
                            bitToSend:= 0;
                            ready <= '0';
                            txState <= SEND_START_BIT;
                        end if timeToStart;
                    
                when SEND_START_BIT =>
                    serialDataOut <= '0';
                    txState <= SEND_DATA_BITS;
                    
                when SEND_DATA_BITS =>
                    serialDataOut <= dataToTx(bitToSend);
                    whenDone: 
                        if (bitToSend = 7) then
                            txState <= SEND_STOP_BIT;
                        else
                            bitToSend := bitToSend + 1;
                        end if whenDone;
                    
                when SEND_STOP_BIT =>
                    serialDataOut <= '1';
                    if (transmitRequest = '0') then
                        txState <= IDLE;
                    end if;
                end case sm;
        
            end if smEnabled;
         end if resetRun;
        end if syncEvents;
    end process tx_sm;
    
end architecture Behavioral;