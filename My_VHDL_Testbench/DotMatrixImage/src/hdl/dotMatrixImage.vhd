--Standard includes
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
 
--Entity definiton
entity dotMatrixImage is
    Port ( 
        U2_138_select           : out std_logic ;
        U3_138_select           : out std_logic ;
        dataout                 : out std_logic_vector(7 downto 0);
        U2_138_A                : out std_logic_vector(2 downto 0);
        clk                     : in std_logic); --clock signal
end dotMatrixImage;
 
--architecture definition
architecture Behavioral of dotMatrixImage is
    --Interial signals
    signal counter : std_logic_vector(8 downto 0) := (others => '0');    --counter to control state and delay
    signal row : std_logic_vector(7 downto 0) := "11111110";             --signal for LED rows
    signal col : std_logic_vector(7 downto 0) := "11111110";  
 
    type display_t is array(7 downto 0) of std_logic_vector(7 downto 0);
    signal display : display_t := ("11111111" ,    -- A simple image to display
                                   "10011001" ,    -- stored in an array
                                   "10011001" ,
                                   "11111111" ,
                                   "11111111" ,
                                   "00111100" ,
                                   "11000011" ,
                                   "11111111");
 
    signal col_mask    : std_logic_vector(7 downto 0) := "11111111";      --mask value used to activate only desired pixels
    signal row_count   : unsigned(2 downto 0) := "001";      
    
    function mux138 (val : in std_logic_vector(7 downto 0)) 
            return std_logic_vector is
        variable v_temp : std_logic_vector(2 downto 0);
    begin
        case val is
          when"11111110"=> v_temp:="000";
          when"11111101"=> v_temp:="001";
          when"11111011"=> v_temp:="010";
          when"11110111"=> v_temp:="011";
          when"11101111"=> v_temp:="100";
          when"11011111"=> v_temp:="101";
          when"10111111"=> v_temp:="110";
          when"01111111"=> v_temp:="111";
          when others=> v_temp:="111";
        end case;
        return v_temp;
    end;    
    
begin
    U2_138_select <= '0';
    U3_138_select <= '1';

    --Process Definition
    process(clk)
    begin
        -- triggers action on rising edge of clock signal
        if rising_edge(clk) then
            --increment counter
            counter <= counter+1;

            --clock period is 31.25ns, counter is 9 bits, should scan whole matrix in < 1ms
            --trigger each time counter rolls over back to zero
            if counter = 0 then
                 -- Left Rotate col
                 col <= col(6 downto 0) & col(7);

                 -- Trigger when last column becomes active
                 if col = "01111111" then
                      -- Left rotate row
                      row <= row(6 downto 0) & row(7);
                      
                      -- increment row count
                      row_count <= row_count + 1;
                      
                      -- get column mask from current position in array
                      col_mask <= display(conv_integer(row_count));
                 end if;
            end if;

            U2_138_A <= mux138(row);
            dataout <= (col or col_mask);
        end if;
    end process;
end Behavioral;