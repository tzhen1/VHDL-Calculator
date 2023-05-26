library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
USE ieee.numeric_std.ALL;

entity UART_baudRateGenerator is
    generic (BAUD_RATE : integer := 115200; -- 19200 before, 19200
             CLOCK_RATE : integer := 50000000); --100MHz clock freq
             
    port ( reset : in STD_LOGIC;
           clock : in STD_LOGIC;
           baudRateEnable : out STD_LOGIC;
           baudRateEnable_x16 : out STD_LOGIC -- oversampling 16x, to detect middle of bits
    );
end entity UART_baudRateGenerator;

architecture BEHAVIORAL of UART_baudRateGenerator is
    constant nCountsPerBaud : integer := CLOCK_RATE / BAUD_RATE; -- 100MHz / 115200
    constant nCountsPerBaud_X16 : integer := nCountsPerBaud / 16;
begin

    make_x16en: process (clock) -- samples 16x
        variable clockCount : integer range 0 to nCountsPerBaud_X16 := 0;
    begin
        syncEvents: if rising_edge(clock) then
            baudRateEnable_x16 <= '0';
            clockCount := clockCount + 1; -- count until right baud rate reached 
            isCountDone: if (clockCount = nCountsPerBaud_X16) then
                baudRateEnable_x16 <= '1'; -- ready
                clockCount := 0; -- flag 0, baud rate synchronised
            end if isCountDone;
        end if syncEvents;
    end process make_x16en;
    
    make_baudEn: process (clock)
        variable clockCount : integer range 0 to nCountsPerBaud := 0;
    begin
        syncEvents: if rising_edge(clock) then
            baudRateEnable <= '0';
            clockCount := clockCount + 1;
            isCountDone: if (clockCount = nCountsPerBaud) then
                baudRateEnable <= '1';
                clockCount := 0;
            end if isCountDone;
       end if syncEvents;
    end process make_baudEn;

end architecture BEHAVIORAL;