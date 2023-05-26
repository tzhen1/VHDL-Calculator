library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
USE ieee.numeric_std.ALL;

entity UART_receiver is
    Port (  reset : in STD_LOGIC;
            clock : in STD_LOGIC;
            baudRateEnable_x16 : in STD_LOGIC;
            serialDataIn : in STD_LOGIC;
            parallelDataOut : out STD_LOGIC_VECTOR (7 downto 0); -- o/p from PC
            dataValid : out STD_LOGIC
    );
end entity UART_receiver;

architecture Behavioral of UART_receiver is
    type legalStates is (IDLE, RCV_START_BIT, RCV_DATA_BITS, RCV_STOP_BIT); --receive bits
    signal rxState : legalStates := IDLE;
    signal countEnable : std_logic := '0';
    signal countDone : std_logic := '0';
    signal countValue : integer range 0 to 31 := 0;
    signal countLoad : std_logic := '0';
    signal lineDown : std_logic := '0';
    
    function stateToString(s : legalStates) return String is
    
        begin
            whichState: case (s) is
                when IDLE => return "IDLE";
                when RCV_START_BIT => return "RCV_START_BIT";
                when RCV_DATA_BITS => return "RCV_DATA_BITS";
                when RCV_STOP_BIT => return "RCV_STOP_BIT";
            end case whichState;
        end function stateToString;

begin
    rx_sm: process (clock)
        variable bitsReceived : integer range 0 to 7 := 0;
        variable lastState : legalStates := RCV_STOP_BIT;
    begin
        syncEvents: if rising_edge(clock) then
            resetRun: if (reset = '1') then
                rxState <= IDLE;
                dataValid <= '0';
                countLoad <= '0';
                countEnable <= '0';
                lineDown <= '0';
            else
                countLoad <= '0';
                dataValid <= '0';
                smEnabled: if (baudRateEnable_x16 = '1') then
                    lastState := rxState;
                    
                    -- state machine
                    sm: case (rxState) is
                        when IDLE =>
                            countEnable <= '0';
                            startDetect: if (serialDataIn = '0') then -- send 0 to start
                                bitsReceived:= 0;
                                countValue <= 7; -- give counter 7 to count down
                                countEnable <= '1';
                                countLoad <= '1'; -- load counter with 7 counts
                                rxState <= RCV_START_BIT;
                            end if startDetect;

                        when RCV_START_BIT =>
                            isHalfWay: if (countDone = '1') then -- middle of start bit
                                stillStartBit: if (serialDataIn = '0') then -- if still '0'
                                    countValue <= 15;
                                    countLoad <= '1';
                                    rxState <= RCV_DATA_BITS; -- start rcv data
                                else
                                    rxState <= IDLE;
                                end if stillStartBit;
                            end if isHalfWay;

                        when RCV_DATA_BITS =>
                            countEnable <= '1';
                            collectingOrDone: if (countDone = '1') then
                                parallelDataOut(bitsReceived) <= serialDataIn; -- receive bits
                                if (bitsReceived = 7) then
                                    rxState <= RCV_STOP_BIT;
                                else
                                    bitsReceived := bitsReceived + 1;
                                end if;
                                countLoad <= '1';
                            end if collectingOrDone;

                        when RCV_STOP_BIT =>
                            sampleStopBit: if (countDone = '1') then
                                countEnable <= '0';
                                isStopBit: if (serialDataIn = '1') then
                                    dataValid <= '1';
                                    rxState <= IDLE;
                                else
                                    lineDown <= '1';
                                end if isStopBit;
                            end if sampleStopBit;

                            isLineDown: if (lineDown = '1') then
                                checkLineLevel: if (serialDataIn = '1') then
                                    lineDown <= '0';
                                    rxState <= IDLE;
                                end if checkLineLevel;
                            end if isLineDown;
                        end case sm;
                    end if smEnabled;
                end if resetRun;
            end if syncEvents;
        end process rx_sm;

counter: process (clock)
    variable internalCountValue : integer range 0 to 31 := 0;
begin
    syncEvents: if rising_edge(clock) then
        resetRun: if (reset = '1') then
            internalCountValue := 0;
            countDone <= '0';
    else
    isLoadingOrEnabled: if (countLoad = '1') then
        internalCountValue := countValue;
        countDone <= '0';
    elsif (baudRateEnable_x16 = '1') AND (countEnable = '1') then -- count enable from IDLE
        countDone <= '0';
        if (internalCountValue = 1) then
        countDone <= '1';
    else
        internalCountValue := internalCountValue - 1;
    end if;
    end if isLoadingOrEnabled;
    end if resetRun;
    end if;
end process counter;

end Behavioral;