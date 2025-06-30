library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity VGA_sync is
    generic (
        -- Horizontal timing (line)
        H_ACTIVE_VIDEO : natural;
        H_FRONT_PORCH  : natural;
        H_SYNC_PULSE   : natural;
        H_BACK_PORCH   : natural;
        -- Vertical timing (frame)
        V_ACTIVE_VIDEO : natural;
        V_FRONT_PORCH  : natural;
        V_SYNC_PULSE   : natural;
        V_BACK_PORCH   : natural);
    port(
        i_clock  : in std_logic;
        i_nrst   : in std_logic;
        o_syncH  : out  std_logic;
        o_syncV  : out  std_logic;
        o_blankH : out  std_logic;
        o_blankV : out  std_logic;
        o_pixelX : out  integer;
        o_pixelY : out  integer);
end entity VGA_sync;

architecture behavioral of VGA_sync is
    constant H_BLANK_PIX    : natural := H_FRONT_PORCH + H_SYNC_PULSE + H_BACK_PORCH; -- 160
    constant H_TOTAL_PIX    : natural := H_BLANK_PIX + H_ACTIVE_VIDEO; -- 800

    constant V_BLANK_PIX    : natural := V_FRONT_PORCH + V_BACK_PORCH + V_SYNC_PULSE; -- 45
    constant V_TOTAL_PIX    : natural := V_BLANK_PIX + V_ACTIVE_VIDEO; -- 525

    signal vCounter : integer range 0 to V_TOTAL_PIX-1 := 0;
    signal hCounter : integer range 0 to H_TOTAL_PIX-1 := 0;
begin
    process (i_clock, i_nrst) is
    begin
        if i_nrst = '0' then
            hCounter <= 0;
            vCounter <= 0;
        elsif rising_edge(i_clock) then
            if hCounter = H_TOTAL_PIX-1 then
                hCounter <= 0;

                if vCounter = V_TOTAL_PIX-1 then
                    vCounter <= 0;
                else
                    vCounter <= vCounter + 1;
                end if;
            else
                hCounter <= hCounter + 1;
            end if;
        end if;
    end process;

    o_blankH <= '1' when (hCounter < H_BLANK_PIX) else '0';
    o_blankV <= '1' when (vCounter < V_BLANK_PIX) else '0';

    -- Polarity of vertical sync pulse is negative
    o_syncV <= '0' when ((vCounter >= V_FRONT_PORCH) and (vCounter < V_FRONT_PORCH + V_SYNC_PULSE)) else '1';
    
    -- Polarity of horizontal sync pulse is negative.
    o_syncH <= '0' when ((hCounter >= H_FRONT_PORCH) and (hCounter < H_FRONT_PORCH + H_SYNC_PULSE)) else '1';

    o_pixelX <= hCounter - H_BLANK_PIX;
    o_pixelY <= vCounter - V_BLANK_PIX;
    
end architecture behavioral;
