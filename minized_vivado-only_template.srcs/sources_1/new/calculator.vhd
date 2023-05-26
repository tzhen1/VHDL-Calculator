library IEEE; use IEEE.STD_LOGIC_1164.ALL; 
USE ieee.numeric_std.ALL; 

entity calculator is
    Port (  
            clk : in STD_LOGIC;
            reset: in STD_LOGIC;
            input1: in std_logic_vector(7 downto 0);
            output_result: out std_logic_vector(7 downto 0);
            dataValid_uart : in STD_LOGIC;
            
            send_character : out STD_LOGIC
    );
end calculator;

architecture Behavioral of calculator is
    
    signal uart_stored: STD_LOGIC := '0';
    signal digit_10_present: STD_LOGIC := '0'; -- digit 10s
    signal digit_10_present_mult_div: STD_LOGIC := '0'; -- digit 10s for mult/div
    signal sent_digit_10: STD_LOGIC := '0'; -- digit 10s
    signal in1_from_uart: std_logic_vector(7 downto 0) := (others=>'0');
    signal in_op_from_uart: std_logic_vector(7 downto 0) := (others=>'0');
    signal in2_from_uart: std_logic_vector(7 downto 0) := (others=>'0');
    signal int_sub_unsigned: unsigned(7 downto 0) := x"30"; -- minus 48 to get back to true num val
    
    signal in_int1, in_int2 : integer range 0 to 255;
    signal int_add, int_sub : integer range 0 to 255;
    signal int_mult, int_div : integer range 0 to 255;
    signal temp_digit_1, temp_digit_10 : integer range 0 to 255;
    signal temp : integer range 0 to 255;
    signal int_add_ascii, int_sub_ascii : integer range 0 to 255;
    signal int_add_ascii_2, int_sub_ascii_2 : integer range 0 to 255;
    signal int_mult_ascii, int_div_ascii : integer range 0 to 255;
    signal int_mult_ascii_2, int_div_ascii_2 : integer range 0 to 255;
    signal out_other: std_logic_vector(7 downto 0) := (others=>'0');
    
    signal add_out_1, add_out_2 : std_logic_vector(7 downto 0) := (others=>'0');
    signal sub_out_1, sub_out_2 : std_logic_vector(7 downto 0) := (others=>'0');
    signal mult_out_1, mult_out_2 : std_logic_vector(7 downto 0) := (others=>'0');
    signal div_out_1, div_out_2 : std_logic_vector(7 downto 0) := (others=>'0');
    
begin
    out_other <=  x"3F";
    calc_op: process(clk)
    begin
        sync_events: if rising_edge(clk) then 
           
        send_character <= '0';
        digit_10_present <= '0';
        digit_10_present_mult_div <= '0';
        
        if (input1 >= X"30") and (input1 <= X"39") and (dataValid_uart = '1') then -- num 0 to 9
            if (uart_stored = '0') then
                in1_from_uart <= input1;
                uart_stored <= '1';
            end if;
        end if;
        
        if (dataValid_uart = '1') then
            if input1 = x"2D" then -- -
                in_op_from_uart <= input1;
            elsif input1 = x"2B" then -- +
                in_op_from_uart <= input1;
            elsif input1 = x"2A" then -- *
                in_op_from_uart <= input1;
            elsif input1 = x"2F" then -- /
                in_op_from_uart <= input1;          
            elsif input1 = x"5E" then -- /
                in_op_from_uart <= input1;    
            end if;
        end if;
        
        -- when first uart_stored = 1, get 2nd uart 
        if ((input1 /= in1_from_uart) and (input1 >= X"30") and (input1 <= X"39") and (dataValid_uart = '1')) then
            in2_from_uart <= input1;
        end if;
          
        -- convert std_vector to int
        in_int1 <= to_integer(unsigned(in1_from_uart) - int_sub_unsigned); 
        in_int2 <= to_integer(unsigned(in2_from_uart) - int_sub_unsigned);
      
        -- for single digit calculations
        int_add <= in_int1 + in_int2;
        int_sub <= in_int1 - in_int2;
        int_mult <= in_int1 * in_int2;
        
        if(in_op_from_uart = x"5E") then
            int_mult <= in_int1 ** 2; -- pow
        end if;
          
        if (in_op_from_uart = x"2F") then
            if (in_int2 = 1) then
                int_div <= in_int1 / 1; -- 2 works, but not int in_int2 
            end if;
            if (in_int2 = 2) then
                int_div <= in_int1 / 2; 
            end if;
            if (in_int2 = 3) then
                int_div <= in_int1 / 3; 
            end if; 
            if (in_int2 = 4) then
                int_div <= in_int1 / 4; 
            end if;
            if (in_int2 = 5) then
                int_div <= in_int1 / 5; 
            end if;
        end if; 

         -- single digit to ASCII
        int_add_ascii <= int_add + 48;
        int_sub_ascii <= int_sub + 48; -- +48 to get to correct ascii, but not for double digits
        int_mult_ascii <= int_mult + 48;
        int_div_ascii <= int_div + 48;
          
      -- double digit ASCII, split integer, then convert to ASCII
        if (int_add >9) and (in_op_from_uart = x"2B") then
            digit_10_present <= '1';
            temp_digit_1 <= int_add mod 10; -- get 1's, by divide by 10, then remainder
            temp <= int_add / 10; -- divide first, get digit 10's right then
            temp_digit_10 <= temp mod 10; -- mod, give it self if not above 10
            
            -- assign singular digits to ASCII
            int_add_ascii <= temp_digit_10 + 48;
            int_add_ascii_2 <= temp_digit_1 + 48;
            
        elsif (int_add = 0) then -- equals 0
            report "error, add value = 0";
        end if;
      
        -- double digit, sub, not needed
        if (int_sub >9) and (in_op_from_uart = x"2D") then
            digit_10_present <= '1';
            temp_digit_1 <= int_sub mod 10; -- get 1's, by divide by 10, then remainder
            temp <= int_sub / 10; -- divide first, get digit 10's right then
            temp_digit_10 <= temp mod 10; -- mod, give it self if not above 10
            
            -- assign singular digits to ASCII
            int_sub_ascii <= temp_digit_10 + 48; -- 10s first
            int_sub_ascii_2 <= temp_digit_1 + 48; -- 1s
      
        elsif (int_sub = 0) then -- equals 0
            report "error, sub value = 0";
        end if;
        
        -- double digit, multilply
        if (int_mult >9) and (in_op_from_uart = x"2A") then
            digit_10_present <= '1';
            temp_digit_1 <= int_mult mod 10; -- get 1's, by divide by 10, then remainder
            temp <= int_mult / 10; -- divide first, get digit 10's right then
            temp_digit_10 <= temp mod 10; -- mod, give it self if not above 10
            
            -- assign singular digits to ASCII
            int_mult_ascii <= temp_digit_10 + 48;
            int_mult_ascii_2 <= temp_digit_1 + 48;
      
        elsif (int_mult = 0) then -- equals 0
            report "error, sub value = 0";
        end if;        
        
        -- double digit, divide
        if (int_div >9) and (in_op_from_uart = x"2F") then
            digit_10_present <= '1';
            temp_digit_1 <= int_div mod 10; -- get 1's, by divide by 10, then remainder
            temp <= int_div / 10; -- divide first, get digit 10's right then
            temp_digit_10 <= temp mod 10; -- mod, give it self if not above 10
            
            -- assign singular digits to ASCII
            int_div_ascii <= temp_digit_10 + 48;
            int_div_ascii_2 <= temp_digit_1 + 48;
      
        elsif (int_div = 0) then -- equals 0
            report "error, sub value = 0";
        end if;   
                   
        add_out_1 <= std_logic_vector(to_unsigned(int_add_ascii, add_out_1'length));
        add_out_2 <= std_logic_vector(to_unsigned(int_add_ascii_2, add_out_2'length));
      
        sub_out_1 <= std_logic_vector(to_unsigned(int_sub_ascii, sub_out_1'length));
        sub_out_2 <= std_logic_vector(to_unsigned(int_sub_ascii_2, sub_out_2'length));
      
        mult_out_1 <= std_logic_vector(to_unsigned(int_mult_ascii, mult_out_1'length));
        mult_out_2 <= std_logic_vector(to_unsigned(int_mult_ascii_2, mult_out_2'length));
      
        div_out_1 <= std_logic_vector(to_unsigned(int_div_ascii, div_out_1'length));
        div_out_2 <= std_logic_vector(to_unsigned(int_div_ascii_2, div_out_2'length));

        -- loop over, send 10s then 1s next
        -- send only when received valid data
        if (in_op_from_uart = x"2B") and (dataValid_uart = '1') then  -- add
        
             -- when no 10 digit, sent single
            output_result <= add_out_1; -- send 10s first, 
            sent_digit_10 <= '1';
            
            if ((sent_digit_10 = '1') and (digit_10_present = '1')  and (dataValid_uart = '1')) then
                output_result <= add_out_2; -- single digit, e.g 14, will be 4
                sent_digit_10 <= '0';
            end if;       
        end if;
        
        -- minus
        if (in_op_from_uart = x"2D") and (dataValid_uart = '1') then 
            output_result <= sub_out_1;
            sent_digit_10 <= '1';
            
            if ((sent_digit_10 = '1') and (digit_10_present = '1') and (dataValid_uart = '1')) then
                output_result <= sub_out_2;
                sent_digit_10 <= '0';
            end if;    
        end if;
        
        -- multiply
        if (in_op_from_uart = x"2A") and (dataValid_uart = '1') then
        
            output_result <= mult_out_1; 
            sent_digit_10 <= '1';
            
            if ((sent_digit_10 = '1') and (digit_10_present = '1') and (dataValid_uart = '1')) then -- when no 10 dig, sent single
                output_result <= mult_out_2;
                sent_digit_10 <= '0';
            end if;    
        end if;
    
        -- divde
        if (in_op_from_uart = x"2F") and (dataValid_uart = '1') then
        
            output_result <= div_out_1; 
            sent_digit_10 <= '1';
            
            if ((sent_digit_10 = '1') and (digit_10_present = '1') and (dataValid_uart = '1')) then -- when no 10 dig, sent single
                output_result <= div_out_2;
                sent_digit_10 <= '0';
            end if;    
        end if;
           
        -- send success 
        send_character <= '1';
    
    end if sync_events;
    end process calc_op;
end Behavioral;
