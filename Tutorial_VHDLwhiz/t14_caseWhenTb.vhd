library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity t14_caseWhenTb is
end entity;

architecture sim of t14_caseWhenTb is
    signal sig1  : unsigned(7 downto 0) := x"AA";
    signal sig2  : unsigned(7 downto 0) := x"BB";
    signal sig3  : unsigned(7 downto 0) := x"CC";
    signal sig4  : unsigned(7 downto 0) := x"DD";

    signal sel  : unsigned(1 downto 0) := (others => '0');
    
    signal output1  : unsigned(7 downto 0);
    signal output2  : unsigned(7 downto 0);
begin

    -- Stimuli for the selector signal
    process is
    begin
        wait for 10 ns;
        sel <= sel + 1;
        wait for 10 ns;
        sel <= sel + 1;
        wait for 10 ns;
        sel <= sel + 1;
        wait for 10 ns;
        sel <= sel + 1;
        wait for 10 ns;
        sel <= "UU";
        wait;
    end process;

    -- MUX using if-then-else
    process(sel, sig1, sig2, sig3, sig4) is
    begin
        if sel = "00" then
            output1 <= sig1;
        elsif sel = "01" then
            output1 <= sig2;
        elsif sel = "10" then
            output1 <= sig3;
        elsif sel = "11" then
            output1 <= sig4;
        else
            output1 <= (others => 'X');
        end if;
    end process;

    -- MUX using case-when
    process(sel, sig1, sig2, sig3, sig4) is
    begin
        case sel is
            when "00" => 
                output2 <= sig1;
            when "01" => 
                output2 <= sig2;
            when "10" => 
                output2 <= sig3;
            when "11" => 
                output2 <= sig4;
            when others =>
                output2 <= (others => 'X');
        end case;
    end process;
        
end architecture;
