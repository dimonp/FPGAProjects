library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

-- For conv_std_logic_vector:
use ieee.std_logic_arith.all;

entity cnt_0_to_23 is
    port( clk       : in std_logic; 
          vector    : out std_logic_vector(4 downto 0));
end cnt_0_to_23;

architecture Behavioral of cnt_0_to_23 is
begin
    process(clk)
        variable cnt : integer range 0 to 23;
    begin
        if rising_edge(clk) then
            if(cnt = 23) then
                cnt := 0;
                vector <= conv_std_logic_vector(cnt, 5);
            else
                cnt := cnt + 1;
                vector <= conv_std_logic_vector(cnt, 5);
            end if;
        end if;
    end process;
end Behavioral;
