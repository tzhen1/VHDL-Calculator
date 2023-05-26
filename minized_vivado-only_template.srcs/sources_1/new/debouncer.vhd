library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
USE ieee.numeric_std.ALL;
-- checks if old signal same as new. if not same, then change signals to new after period (stable)
entity debouncer is
    Generic (DELAY_VALUE : integer := 100); -- count checker
    Port (  clk : in STD_LOGIC;
            signal_in : in STD_LOGIC; -- button press, DIP_PINs i/p here, configured in TB
            signal_out : out STD_LOGIC -- o/p to DIP_DEBOUNCED to encoder
            );
end entity debouncer;

architecture Behavioral of debouncer is
    type legalStates is (INIT_OUTPUT, IDLING, WAITING, CHANGING); --state types, state machine
    signal countReset : std_logic := '0'; --U
    signal countDone : std_logic := '0'; --U
    
begin
    dbnceSM: process (clk)
    variable state : legalStates := INIT_OUTPUT;
    variable lastInput : std_logic := '0'; -- pulse o/p 0
    
    begin
        sync_events: if rising_edge(clk) then
        case state is -- case, switch cases depending on state (INPUT_OUTPUT etc)
        
        when INIT_OUTPUT =>
            signal_out <= '0'; -- init to 0
            state := IDLING; --idle check for button
            
        when IDLING =>
            countReset <= '1'; -- reset counter
            if ((lastInput /= signal_in) and (lastInput /= 'U')) then -- if last and current sig not equal
                countReset <= '0'; -- no reset cnt
                state := WAITING; -- goto wait sate below
            end if;
            
            lastInput := signal_in; -- curr into last sig
            
        when WAITING =>
            countReset <= '0';
            
            if (lastInput /= signal_in) then -- i/p changes, 0 to 1, then
                lastInput := signal_in; -- new i/p
                countReset <= '1';
            end if;
        
            if (countDone = '1') then  -- after counter finished, switch signal from old to new
                signal_out <= signal_in; -- o/p new sig
                countReset <= '1';
                state := IDLING;
            end if;
        
        when others=>
            signal_out <= 'U';
        end case;
        
        end if sync_events;
    end process dbnceSM;

    -- counter until max
    cntr: process (clk)
        constant adjLimit : integer := DELAY_VALUE - 3; -- start = 100, adjusted to 97
        variable internalCount : integer range 0 to adjLimit := adjLimit;
    begin
        if rising_edge(clk) then
            if (countReset = '1') then
            internalCount := adjLimit; -- reset count
            countDone <= '0';
        else
            countDone <= '0'; -- when rst = 0, not finish conting
        if (internalCount = 0) then -- counts fully down to 0
            countDone <= '1';
        else
            internalCount := internalCount - 1; -- count down 97 to 0
        end if;
    end if;
end if;
end process cntr;
end Behavioral;