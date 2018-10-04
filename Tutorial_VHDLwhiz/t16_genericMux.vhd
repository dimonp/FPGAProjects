library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity t16_genericMux is
    generic(dataWidth : integer);
    port(
        -- Inputs
        sig1 : in unsigned(dataWidth-1 downto 0);
        sig2 : in unsigned(dataWidth-1 downto 0);
        sig3 : in unsigned(dataWidth-1 downto 0);
        sig4 : in unsigned(dataWidth-1 downto 0);

        sel  : unsigned(1 downto 0);
        
        -- Output
        output1 : out unsigned(dataWidth-1 downto 0));
end entity;

architecture rtl of t16_genericMux is
begin

    process(sel, sig1, sig2, sig3, sig4) is
        begin
            case sel is
                when "00" => 
                    output1 <= sig1;
                when "01" => 
                    output1 <= sig2;
                when "10" => 
                    output1 <= sig3;
                when "11" => 
                    output1 <= sig4;
                when others =>
                    output1 <= (others => 'X');
            end case;
        end process;
        
end architecture;
