library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity VGA_tester is
     port(
          clk   : in std_logic;
          rst   : in std_logic;
          key   : in std_logic;
          vgaHs : out std_logic;
          vgaVs : out std_logic;
          vgaR  : out unsigned(4 downto 0);
          vgaG  : out unsigned(5 downto 0);
          vgaB  : out unsigned(4 downto 0));
end entity VGA_tester;

architecture rtl of VGA_tester is
    ------------------------------------------------------------
    --  Horizontal scanning parameter setting (1024*768 60Hz VGA)
    ------------------------------------------------------------
    constant LINE_PERIOD    : natural := 1344;  -- Number of rows
    constant H_SYNC_PULSE   : natural := 136;   -- Line sync pulse (Sync a)
    constant H_BACKPORCH    : natural := 160;   -- Display trailing edge (Back porch b)
    constant H_ACTIVE_PIX   : natural := 1024;  -- Display interval c
    constant H_FRONTPORCH   : natural := 24;    -- Display front (Front porch d)
    constant H_DE_START     : natural := 296;
    constant H_DE_END       : natural := 1320;

    ------------------------------------------------------------
    --  Vertical scanning parameter setting (1024*768 60Hz VGA)
    ------------------------------------------------------------
    constant FRAME_PERIOD   : natural := 806;    -- Number of column cycles
    constant V_SYNC_PULSE   : natural := 6;      -- Column sync pulse (Sync o)
    constant V_BACKPORCH    : natural := 29;     -- Display trailing edge (Back porch p)
    constant V_ACTIVEPIX    : natural := 768;    -- Display timing segment (Display interval q)
    constant V_FRONTPORCH   : natural := 3;      -- Display front (Front porch r)
    constant V_DE_START     : natural := 35;
    constant V_DE_END       : natural := 803;

    signal xCnt         : unsigned(10 downto 0);
    signal yCnt         : unsigned(9 downto 0);

    signal gridData1    : unsigned(15 downto 0);
    signal gridData2    : unsigned(15 downto 0);
    signal barData      : unsigned(15 downto 0);
    signal vgaDisMode   : unsigned(3 downto 0) := "1100"; -- Default output color bar
    signal vgaRReg      : unsigned(4 downto 0);
    signal vgaGReg      : unsigned(5 downto 0);
    signal vgaBReg      : unsigned(4 downto 0);
      
    signal hSyncR       : std_logic;
    signal vSyncR       : std_logic;
    signal hSyncDe      : boolean;
    signal vSyncDe      : boolean;

    signal keyCounter   : unsigned(23 downto 0);    -- Button detection register

    signal vgaClk       : std_logic;
    signal barInterval  : unsigned(12 downto 0) := to_unsigned(H_ACTIVE_PIX/8, 13); -- Color bar width=H_ACTIVE_PIX/8

    component clk65
        port ( inclk0 : in std_logic;
               areset : in std_logic;
               c0     : out std_logic;
               locked : out std_logic);
    end component;
begin
    -- Horizontal scan count
    process (vgaClk) is
    begin
        if rising_edge(vgaClk) then
            if rst = '0' then
                xCnt <= to_unsigned(1, 11);
            elsif xCnt = LINE_PERIOD then 
                xCnt <= to_unsigned(1, 11);
            else
                xCnt <= xCnt + 1;
            end if;
        end if;
    end process;

    -- Horizontal scan signal hSync, hSyncDe generated
    process (vgaClk) is
    begin
        if rising_edge(vgaClk) then
            if rst = '0' then
                hSyncR <= '1';
            elsif xCnt = 1 then -- Generate hSync signal
                hSyncR <= '0';
            elsif xCnt = H_SYNC_PULSE then
                hSyncR <= '1';
            end if;

            if rst = '0' then
                hSyncDe <= false;
            elsif xCnt = H_DE_START then -- Generate hSyncDe signal
                hSyncDe <= true;
            elsif xCnt = H_DE_END then
                hSyncDe <= false;
            end if;
        end if;
    end process;

    -- Vertical scan count
    process (vgaClk) is
    begin
        if rising_edge(vgaClk) then
            if rst = '0' then
                yCnt <= to_unsigned(1, 10);
            elsif yCnt = FRAME_PERIOD then
                yCnt <= to_unsigned(1, 10);
            elsif xCnt = LINE_PERIOD then
                yCnt <= yCnt + 1;
            end if;
        end if;
    end process;

    -- Vertical scan signal vSync, vSyncDe generated
    process (vgaClk) is
    begin
        if rising_edge(vgaClk) then
            if rst = '0' then
                vSyncR <= '1';
            elsif yCnt = 1 then -- Generate vSync signal
                vSyncR <= '0';
            elsif yCnt = V_SYNC_PULSE then
                vSyncR <= '1';
            end if;

            if rst = '0' then
                vSyncDe <= false;
            elsif yCnt = V_DE_START then -- Generate vSyncDe signal
                vSyncDe <= true;
            elsif yCnt = V_DE_END then
                vSyncDe <= false;
            end if;
        end if;
    end process;

    -- Lattice test image generation
    process (vgaClk) is
    begin
        if falling_edge(vgaClk) then
            if xCnt(4) = '1' xor yCnt(4) = '1' then -- Produce a small grid image
                gridData1 <= x"0000";
            else
                gridData1 <= x"FFFF";
            end if;

            if xCnt(6) = '1' xor yCnt(6) = '1' then -- Produce a large grid image
                gridData2 <= x"0000";
            else
                gridData2 <= x"FFFF";
            end if;
        end if;
    end process;

    -- Color strip test image generation
    process (vgaClk) is
    begin
        if falling_edge(vgaClk) then
            if xCnt = H_DE_START then
                barData <= x"F800";              -- Red color strip
            elsif xCnt = H_DE_START + barInterval then
                barData <= x"07E0";              -- Green color strip
            elsif xCnt = H_DE_START + barInterval*2 then
                barData <= x"001F";              -- Blue color strip
            elsif xCnt = H_DE_START + barInterval*3 then
                barData <= x"F81F";              -- Purple color strip
            elsif xCnt = H_DE_START + barInterval*4 then
                barData <= x"FFE0";              -- Yellow color strip
            elsif xCnt = H_DE_START + barInterval*5 then
                barData <= x"07FF";              -- Blue color strip
            elsif xCnt = H_DE_START + barInterval*6 then
                barData <= x"FFFF";              -- White color strip
            elsif xCnt = H_DE_START + barInterval*7 then
                barData <= x"FC00";              -- Orange color strip
            elsif xCnt = H_DE_START + barInterval*8 then
                barData <= x"0000";              -- Other black
            end if;
        end if;
    end process;

---------------------------------------------------------------------------
---  VGA image selection output
---------------------------------------------------------------------------

    -- LCD data signal selection
    process (vgaClk) is
    begin
        if falling_edge(vgaClk) then
            if rst = '0' then
                vgaRReg <= (others=>'0');
                vgaGReg <= (others=>'0');
                vgaBReg <= (others=>'0');
            else
                case vgaDisMode is
                    when "0000" =>      -- VGA display is full black
                        vgaRReg <= (others=>'0');
                        vgaGReg <= (others=>'0');
                        vgaBReg <= (others=>'0');
                    when "0001" =>      -- VGA display is full white
                        vgaRReg <= (others=>'1');
                        vgaGReg <= (others=>'1');
                        vgaBReg <= (others=>'1');
                    when "0010" =>      --  VGA display is full red
                        vgaRReg <= (others=>'1');
                        vgaGReg <= (others=>'0');
                        vgaBReg <= (others=>'0');
                    when "0011" =>      --  VGA display is full green
                        vgaRReg <= (others=>'0');
                        vgaGReg <= (others=>'1');
                        vgaBReg <= (others=>'0');
                    when "0100" =>      --  VGA display is full blue
                        vgaRReg <= (others=>'0');
                        vgaGReg <= (others=>'0');
                        vgaBReg <= (others=>'1');
                    when "0101" =>      --  VGA display is square 1
                        vgaRReg <= gridData1(15 downto 11);
                        vgaGReg <= gridData1(10 downto 5);
                        vgaBReg <= gridData1(4 downto 0);
                    when "0110" =>      --  VGA display is square 2
                        vgaRReg <= gridData2(15 downto 11);
                        vgaGReg <= gridData2(10 downto 5);
                        vgaBReg <= gridData2(4 downto 0);
                    when "0111" =>      --  VGA display is horizontal gradient
                        vgaRReg <= xCnt(6 downto 2);
                        vgaGReg <= xCnt(6 downto 1);
                        vgaBReg <= xCnt(6 downto 2);
                    when "1000" =>      --  VGA display is vertical gradient
                        vgaRReg <= yCnt(6 downto 2);
                        vgaGReg <= yCnt(6 downto 1);
                        vgaBReg <= yCnt(6 downto 2);
                    when "1001" =>      --  VGA display is red horizontal gradient
                        vgaRReg <= xCnt(6 downto 2);
                        vgaGReg <= (others=>'0');
                        vgaBReg <= (others=>'0');
                    when "1010" =>      --  VGA display is green horizontal gradient
                        vgaRReg <= (others=>'0');
                        vgaGReg <= xCnt(6 downto 1);
                        vgaBReg <= (others=>'0');
                    when "1011" =>      --  VGA display is blue horizontal gradient
                        vgaRReg <= (others=>'0');
                        vgaGReg <= (others=>'0');
                        vgaBReg <= xCnt(6 downto 2);
                    when "1100" =>      --  VGA display is color bar
                        vgaRReg <= barData(15 downto 11);
                        vgaGReg <= barData(10 downto 5);
                        vgaBReg <= barData(4 downto 0);
                    when others =>      --VGA display is full white
                        vgaRReg <= (others=>'1');
                        vgaGReg <= (others=>'1');
                        vgaBReg <= (others=>'1');
                end case;
            end if;
        end if;
    end process;

    vgaHs <= hSyncR;
    vgaVs <= vSyncR;
    vgaR <= vgaRReg when (hSyncDe and vSyncDe) else (others=>'0');
    vgaG <= vgaGReg when (hSyncDe and vSyncDe) else (others=>'0');
    vgaB <= vgaBReg when (hSyncDe and vSyncDe) else (others=>'0');

    pll_inst : clk65 port map (
        inclk0 => clk,
        c0 => vgaClk,   -- 65.0Mhz for 1024x768(60hz)
        areset => '0');

    process (vgaClk) is
    begin
        if rising_edge(vgaClk) then
            if rst = '0' then
                vgaDisMode <= "1100";   -- Default output color bar
                keyCounter <= (others=>'0');
            else
                if key = '1' then
                    keyCounter <= (others=>'0');
                elsif key = '0' and keyCounter <= 499999 then   -- If the button is pressed and the pressing time is less than 1ms, the count (65M*0.1-1=6_499_999)
                    keyCounter <= keyCounter + 1;
                    if keyCounter = 499999 then -- One button is valid, change the display mode
                        if vgaDisMode = "1101" then
                            vgaDisMode <= "0000";
                        else
                            vgaDisMode <= vgaDisMode + 1;
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end process;
end architecture rtl;
