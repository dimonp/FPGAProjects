library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity VGA_Sync is
    port(
        pixelClk    : in std_logic;
        hSync       : out std_logic;
        vSync       : out std_logic;
        blankN      : out std_logic;
        pixelClkN   : out std_logic);
end entity VGA_Sync;

architecture Behavioral of VGA_Sync is

    -- 1280 x 1024 at 60 Hz
    -- Horizontal timing
    constant H_ACTIVE_VIDEO : natural := 1280;
    constant H_FRONT_PORCH  : natural := 48;
    constant H_SYNC_PULSE   : natural := 112;
    constant H_BACK_PORCH   : natural := 248;
    constant H_BLANK_PIX    : natural := H_FRONT_PORCH + H_SYNC_PULSE + H_BACK_PORCH;
    constant H_TOTAL_PIX    : natural := H_ACTIVE_VIDEO + H_BLANK_PIX;
     
    -- 1280 x 1024 at 60 Hz
    -- Vertical timing
    constant V_ACTIVE_VIDEO : natural := 1024;
    constant V_FRONT_PORCH  : natural := 1;
    constant V_SYNC_PULSE   : natural := 3;
    constant V_BACK_PORCH   : natural := 38;
    constant V_BLANK_PIX    : natural := V_FRONT_PORCH + V_SYNC_PULSE + V_BACK_PORCH;
    constant V_TOTAL_PIX    : natural := V_ACTIVE_VIDEO + V_BLANK_PIX;
    
    signal countV : unsigned(10 downto 0);
    signal countH : unsigned(11 downto 0);
begin
    pixelClkN <= not pixelClk;

    blankN <= '0' when ((countV < V_BLANK_PIX) or (countH < H_BLANK_PIX)) else '1';

    vSync <= '1' when ((countV >= V_FRONT_PORCH-1) and (countV <= V_FRONT_PORCH + V_SYNC_PULSE-1)) else '0';
    hSync <= '0' when ((countH >= H_FRONT_PORCH-1) and (countH <= H_FRONT_PORCH + H_SYNC_PULSE-1)) else '1';

    process (pixelClk) is
    begin
        if rising_edge(pixelClk) then
            if countH < H_TOTAL_PIX then
                countH <= countH + 1;
            else
                countH <= (others=>'0');

                if countV < V_TOTAL_PIX then
                    countV <= countV + 1;
                else
                    countV <= (others=>'0');
                end if;
            end if;
        end if;
    end process;

end architecture Behavioral;
