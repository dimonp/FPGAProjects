library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity t16_generixMuxTb is
end entity;

architecture sim of t16_generixMuxTb is

    constant dataWidth : integer := 16;

    signal sig1  : unsigned(dataWidth-1 downto 0) := x"AaAa";
    signal sig2  : unsigned(dataWidth-1 downto 0) := x"BbBb";
    signal sig3  : unsigned(dataWidth-1 downto 0) := x"CcCc";
    signal sig4  : unsigned(dataWidth-1 downto 0) := x"DdDd";

    signal sel  : unsigned(1 downto 0) := (others => '0');
    
    signal output1  : unsigned(dataWidth-1 downto 0);
begin
    -- An instance of t16_genericMux with architecture rtl
    i_mux : entity work.t16_genericMux(rtl) 
        generic map(dataWidth => dataWidth)
        port map(
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
