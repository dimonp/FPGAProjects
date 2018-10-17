library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity VGA_text_top is
    port(
        clk     : in std_logic;
        rst     : in std_logic;
        vgaHs   : out std_logic;
        vgaVs   : out std_logic;
        vgaR    : out std_logic_vector(4 downto 0);
        vgaG    : out std_logic_vector(5 downto 0);
        vgaB    : out std_logic_vector(4 downto 0));

end entity VGA_text_top;

architecture behavioral of VGA_text_top is
    component VGA_text
        port ( 
            clock   : in std_logic;
            reset   : in std_logic;
            wen     : in std_logic;
            addr    : in natural range 0 to 2400;
            data    : in std_logic_vector(15 downto 0);
            hsync   : out std_logic;
            vsync   : out std_logic;
            r       : out std_logic_vector(4 downto 0);
            g       : out std_logic_vector(5 downto 0);
            b       : out std_logic_vector(4 downto 0));
    end component;

    signal wen     : std_logic := '0';
    signal addr    : natural range 0 to 2400;
    signal data    : std_logic_vector(15 downto 0);
    signal q       : std_logic_vector(23 downto 0) := (others => '0');
begin
    vgaText_inst : VGA_text port map (
            clock => clk,
            reset => not rst,
            wen   => wen,
            addr  => addr,
            data  => data,
            hsync => vgaHs,
            vsync => vgaVs,
            r => vgaR,
            g => vgaG,
            b => vgaB);

    process(clk) is
    begin
        if rising_edge(clk) then
            q <= q + 1;
        end if;
    end process;


    -- 2.98 Hz
    process(q(23)) is
        variable wAddr : natural range 0 to 2400 := 0;
    begin
        if rising_edge(q(23)) then
            addr <= wAddr;
            data <= (others=>'0');
            wen <= '1';

            wAddr := wAddr + 2;
        end if;
    end process;

end architecture behavioral;
