library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
USE ieee.numeric_std.ALL;
--USE IEEE.STD_LOGIC_ARITH.ALL;
-- if 9 + 2 = 11, send 1 and then 1 in uart, using encoder and decoder
-- figure out ASCII output correct 
-- o/p to transmitter, i/p to decoder

entity character_decoder is
    generic (CLOCK_FREQUENCY : integer := 50_000_000); -- 40 MHz
    port (  clk : in STD_LOGIC;
            charFromUART_valid : in STD_LOGIC;
            charFromUART : in STD_LOGIC_VECTOR(7 downto 0); -- 8bit keyboard i/p, from parallel data out
            LED_hi : out STD_LOGIC;
            LED_lo : out STD_LOGIC;
            send_character : out STD_LOGIC;
            character_to_send : out STD_LOGIC_VECTOR (7 downto 0) -- out
    );
end entity character_decoder;

architecture Behavioral of character_decoder is
    signal start_timer : std_logic := '0';
    signal illuminate : boolean := false; -- illuminate leds 
    signal LED_hi_req : std_logic := '0';
    signal LED_lo_req : std_logic := '0';
    signal send_character_i : std_logic := '0';
    signal new_ASCII_value : integer range 0 to 255 := 0; -- store new ascii, or std_logic_vector
begin
    decoder_table: process (clk)
        variable ASCII_value : integer range 0 to 255 := 0;

    begin
        sync_events: if rising_edge(clk) then
            send_character_i <= '0'; -- reset timer on rising edge clk
            character_to_send <= (others=>'0');
            start_timer <= '0';
            
            data_good: if (charFromUART_valid = '1') then
                whatKind: if ((charFromUART >= X"61") and (charFromUART <= X"7A")) then -- from a,b,c .. to ~
                            LED_lo_req <= '1'; -- plays with LEDs, check board see what it does?
                            LED_hi_req <= '0';
                            ASCII_value := to_integer(unsigned(charFromUART)); -- make it ascii
                            new_ASCII_value <= ASCII_value - 32; -- a to A (97 -32 = 65)
                            character_to_send <=
                            std_logic_vector(to_unsigned(new_ASCII_value,8)); -- make into std_logic_vector
                    
                        elsif ((charFromUART >= X"41") and (charFromUART <= X"5A")) then -- from capital A to Z
                            LED_lo_req <= '1';
                            LED_hi_req <= '0';
                            ASCII_value := to_integer(unsigned(charFromUART));
                            new_ASCII_value <= ASCII_value + 32; -- :=, makes 32 capital to lowercase equiv
                            character_to_send <=
                            std_logic_vector(to_unsigned(new_ASCII_value,8));
                    
                        elsif ((charFromUART >= X"30") and (charFromUART <= X"39")) then -- numbers 0 to 9
                            LED_lo_req <= '0';
                            LED_hi_req <= '1';
                            character_to_send <= charFromUART; -- send asci to uart, numbers, ascii!!!
                            
                        else
                            LED_lo_req <= '1';
                            LED_hi_req <= '1';
                            character_to_send <= charFromUART;
                        end if whatKind;
                    
                        start_timer <= '1';
                        send_character_i <= '1';
                        
                end if data_good;
        end if sync_events;
    end process decoder_table;
    
    send_character <= send_character_i; 
    mk_timer: process (clk)
        constant TERMINAL_COUNT : integer := CLOCK_FREQUENCY * 1;
        variable timer_value : integer range 0 to TERMINAL_COUNT := 0;
        variable timer_running : boolean := false; -- for illuminating LEDs
        begin
        
            sync_events: if rising_edge(clk) then
            
            start_reset_timer: if (start_timer = '1') then
                timer_value := 0;
                timer_running := true;
            end if start_reset_timer;
            
            do_count: if (timer_running) then
                timer_value := timer_value + 1;
            end if do_count;
            
            stop_timer: if (timer_value = TERMINAL_COUNT) then
                timer_running := false;
            end if stop_timer;
            
            illuminate <= timer_running;
        end if sync_events;
    end process mk_timer;
    
    do_LEDs: process (clk)
        begin
            sync_events: if rising_edge(clk) then
                LED_hi <= '0';
                LED_lo <= '0';
                LEDS_are_on: if (illuminate) then
                    LED_hi <= LED_hi_req;
                    LED_lo <= LED_lo_req;
                end if LEDS_are_on;
            end if sync_events;
        end process do_LEDs;
end Behavioral;