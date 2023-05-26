-- This file provides a boilerplate for the simple passthrough 
-- You can edit this as you see fit, to integrate with your assignment to 
-- get it running on the Minized board

-- You'll need to add your lab_design_top as a component here!

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Toplevel_Impl is
    port (
        sys_clk : in std_logic;
        sys_nrst : in std_logic;
        
        uart_tx : out std_logic;
        uart_rx : in std_logic
    );
end Toplevel_Impl;

architecture Behavioral of Toplevel_Impl is

component lab_design_top Port 
       (reset_pin : in STD_LOGIC;
        clock_pin : in STD_LOGIC;
        serialDataIn_pin : in STD_LOGIC;
        serialDataOut_pin : out STD_LOGIC;
        LED_hi_pin : out STD_LOGIC;
        LED_lo_pin : out STD_LOGIC;
        DIP_pins : in STD_LOGIC_VECTOR (3 downto 0));
end component;

    -- i/p lab design, placed by me
    signal reset_pin : STD_LOGIC;
    signal clock_pin : STD_LOGIC;
    signal serialDataIn_pin : STD_LOGIC; -- serial data in for UART
    signal serialDataOut_pin : STD_LOGIC;
    signal LED_hi_pin : STD_LOGIC;
    signal LED_lo_pin : STD_LOGIC;
    signal DIP_pins : STD_LOGIC_VECTOR (3 downto 0);
    
begin
    process (sys_clk,sys_nrst)
        begin
            if sys_nrst = '0' then
                uart_tx <= '0';
                
            elsif rising_edge(sys_clk) then
                uart_tx <= uart_rx;
            
            end if; 
    end process;

--    process (clock_pin,reset_pin)
--        begin
--            if reset_pin = '0' then
--                serialDataOut_pin <= '0';
                
--            elsif rising_edge(clock_pin) then
--                serialDataOut_pin <= serialDataIn_pin;
            
--            end if; 
--    end process;
end Behavioral;
