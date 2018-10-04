-- Example 52: x7segbc - Display 7-seg with leading blanks
-- input cclk should be 190 Hz
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity x7segbc is
    port(
        x       : in std_logic_vector(15 downto 0);
        cclk    : in std_logic;
        clr     : in std_logic;
        a_to_g  : out std_logic_vector(6 downto 0);
        anc     : out std_logic_vector(2 downto 0);
        dp      : out std_logic);
end entity x7segbc;

architecture rtl of x7segbc is
    signal s        : std_logic_vector(1 downto 0) := "00";
    signal digit    : std_logic_vector(3 downto 0);
begin
    dp <= '1';

    -- Quad 4-to-1 MUX: mux44
    mux44 : process(s, x) is
    begin
        case s is
            when "00" => 
                digit <= x(3 downto 0);
            when "01" => 
                digit <= x(7 downto 4);
            when "10" => 
                digit <= x(11 downto 8);
            when others => 
                digit <= x(15 downto 12);
        end case;
    end process mux44;
    
    -- 7-segment decoder: hex7seg
    hex7seg : process(digit) is
    begin
        case digit is
            when x"0" => 
                a_to_g <= "1000000"; -- 0
            when x"1" => 
                a_to_g <= "1111001"; -- 1
            when x"2" => 
                a_to_g <= "0100100"; -- 2
            when x"3" => 
                a_to_g <= "0110000"; -- 3
            when x"4" => 
                a_to_g <= "0011001"; -- 4
            when x"5" => 
                a_to_g <= "0010010"; -- 5
            when x"6" => 
                a_to_g <= "0000010"; -- 6
            when x"7" => 
                a_to_g <= "1111000"; -- 7
            when x"8" => 
                a_to_g <= "0000000"; -- 8
            when x"9" => 
                a_to_g <= "0010000"; -- 9
            when x"A" => 
                a_to_g <= "0001000"; -- A
            when x"B" => 
                a_to_g <= "0000011"; -- B
            when x"C" => 
                a_to_g <= "1000111"; -- C
            when x"D" => 
                a_to_g <= "0100001"; -- D
            when x"E" => 
                a_to_g <= "0000110"; -- E
            when others => 
                a_to_g <= "0001110"; -- F
        end case;
    end process hex7seg;

    -- Digit select: ancode
    ancode : process(s)
    begin
        case s is
            when"00" => 
                anc <="000";
            when"01" => 
                anc <="001";
            when"10" => 
                anc<="010";
            when others => 
                anc<="011";
        end case;
    end process ancode;

    -- 2-bit counter
    process(cclk, clr) is
    begin
        if clr = '1' then
            s <= "00";
        elsif rising_edge(cclk) then
            s <= s + 1;
        end if;
    end process;

end architecture rtl;
