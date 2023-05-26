library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
USE ieee.numeric_std.ALL;

package uart_components is

component UART_baudRateGenerator 
        generic(BAUD_RATE:integer:=115200;CLOCK_RATE:integer:=50000000);     
        port(reset:in STD_LOGIC;clock:in STD_LOGIC;baudRateEnable:out STD_LOGIC;baudRateEnable_x16:out STD_LOGIC);
        end component;
        
component UART_transmitter Port ( reset : in STD_LOGIC;clock : in STD_LOGIC;baudRateEnable : in STD_LOGIC;
        parallelDataIn : in STD_LOGIC_VECTOR (7 downto 0); transmitRequest : in STD_LOGIC;
        ready : out STD_LOGIC; serialDataOut : out STD_LOGIC);end component;
        
component UART_receiver Port (  reset : in STD_LOGIC;clock : in STD_LOGIC;baudRateEnable_x16 : in STD_LOGIC;
        serialDataIn : in STD_LOGIC;parallelDataOut : out STD_LOGIC_VECTOR (7 downto 0);dataValid : out STD_LOGIC);
        end component;

component character_decoder 
        generic (CLOCK_FREQUENCY : integer := 50_000_000);
        port (  clk : in STD_LOGIC; charFromUART_valid : in STD_LOGIC;
        charFromUART : in STD_LOGIC_VECTOR(7 downto 0);LED_hi : out STD_LOGIC;LED_lo : out STD_LOGIC;
        send_character : out STD_LOGIC;character_to_send : out STD_LOGIC_VECTOR (7 downto 0));end component;  
    
component character_encoder Port (  clk : in STD_LOGIC;character_decoded : in STD_LOGIC;
        character_to_send : in STD_LOGIC_VECTOR (7 downto 0);tx_ready : in STD_LOGIC;
        parallelDataIn : out STD_LOGIC_VECTOR (7 downto 0);transmitRequest : out STD_LOGIC;
        DIP_dbncd : in STD_LOGIC_VECTOR (3 downto 0));end component;
    
component debouncer 
        Generic (DELAY_VALUE : integer := 100);
        Port (  clk : in STD_LOGIC;signal_in : in STD_LOGIC;signal_out : out STD_LOGIC);end component;

component UART 
        generic(BAUD_RATE : integer := 115200; CLOCK_RATE : integer := 50000000);
        port (  reset : in STD_LOGIC;clock : in STD_LOGIC;serialDataIn : in STD_LOGIC;
        parallelDataOut : out STD_LOGIC_VECTOR (7 downto 0);dataValid : out STD_LOGIC;
        parallelDataIn : in STD_LOGIC_VECTOR (7 downto 0);transmitRequest : in STD_LOGIC;txIsReady : out STD_LOGIC;
        serialDataOut : out STD_LOGIC);end component;
     
--component calculator -- dec
--        port (  
----        clk : in STD_LOGIC; charFromUART_valid : in STD_LOGIC;
----        charFromUART : in STD_LOGIC_VECTOR(7 downto 0);LED_hi : out STD_LOGIC;LED_lo : out STD_LOGIC;
----        send_character : out STD_LOGIC;character_to_send : out STD_LOGIC_VECTOR (7 downto 0));end component;
        
--        clk : in STD_LOGIC; input1: in std_logic_vector(7 downto 0); input2: in std_logic_vector(7 downto 0);
--        operator: in std_logic_vector(7 downto 0); output_result: out std_logic_vector(15 downto 0));end component;
end;