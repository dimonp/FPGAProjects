library ieee;
use ieee.std_logic_1164.all;

entity mod10Kcnt_top is
    port(
        mclk    : in std_logic;
        btn     : in std_logic_vector(3 downto 3);
        a_to_g  : out std_logic_vector(6 downto 0);
        anc     : out std_logic_vector(2 downto 0);
        dp      : out std_logic;
        u2_138_select: out std_logic;
        u3_138_select: out std_logic);
end entity mod10Kcnt_top;

architecture rtl of mod10Kcnt_top is
    component clkdiv
        port(
            mclk   : in  std_logic;
            clr    : in std_logic;
            clk190 : out std_logic;
            clk12  : out std_logic);
    end component clkdiv;
    component mod10Kcnt
        port(
            clk     : in std_logic;
            clr     : in std_logic;
            q       : out std_logic_vector(13 downto 0));
    end component mod10Kcnt;
    component bin2bcd14
        port(
            b : in std_logic_vector(13 downto 0);
            p : out std_logic_vector(16 downto 0));
    end component bin2bcd14;
    component x7segbc
        port(
            x       : in std_logic_vector(15 downto 0);
            cclk    : in std_logic;
            clr     : in std_logic;
            a_to_g  : out std_logic_vector(6 downto 0);
            anc     : out std_logic_vector(2 downto 0);
            dp      : out std_logic);                       -- decimal point
    end component x7segbc;
    
    signal b : std_logic_vector(13 downto 0);
    signal p : std_logic_vector(16 downto 0);
    signal clr, clk12, clk190 : std_logic;
begin
    u2_138_select <= '1';
    u3_138_select <= '0';
    clr <= not btn(3);

    U1: clkdiv
        port map(
            mclk   => mclk,
            clr    => clr,
            clk190 => clk190,
            clk12  => clk12);
    
    U2: mod10Kcnt
        port map(
            clk  => clk12,
            clr  => clr,
            q    => b);

    U3: bin2bcd14
        port map(
            b => b,
            p => p);

    U4: x7segbc
        port map(
            x      => p(15 downto 0),
            cclk   => clk190,
            clr    => clr,
            a_to_g => a_to_g,
            anc    => anc,
            dp     => dp);

end architecture rtl;
