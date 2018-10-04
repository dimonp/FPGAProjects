library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity t15_portMapTb is
end entity;

architecture sim of t15_portMapTb is
    signal sig1  : unsigned(7 downto 0) := x"AA";
    signal sig2  : unsigned(7 downto 0) := x"BB";
    signal sig3  : unsigned(7 downto 0) := x"CC";
    signal sig4  : unsigned(7 downto 0) := x"DD";

    signal sel  : unsigned(1 downto 0) := (others => '0');
    
    signal output1  : unsigned(7 downto 0);
begin
    -- An instance of t15_mux with architecture rtl
    i_mux : entity work.t15_mux(rtl) port map(
        sel     => sel,
        sig1    => sig1,
        sig2    => sig2,
        sig3    => sig3,
        sig4    => sig4,
        output1 => output1);

    -- Testbench process
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
    
        
end architecture;
