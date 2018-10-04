library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity Div_50Mhz_to_1Hz is
    port( clk:in std_logic; 
          clk_out:out std_logic);
end Div_50Mhz_to_1Hz;

architecture Behavioral of Div_50Mhz_to_1Hz is
begin
    process(clk)
    variable cnt : integer range 0 to 50000000;
    begin
        if rising_edge(clk) then

            if(cnt >= 25000000) then
                clk_out <= '1';
            else 
                clk_out <= '0';
            end if;

            if(cnt = 50000000) then
                cnt := 0;
            else
                cnt := cnt + 1;
            end if; 

        end if;
    end process;
end Behavioral;
