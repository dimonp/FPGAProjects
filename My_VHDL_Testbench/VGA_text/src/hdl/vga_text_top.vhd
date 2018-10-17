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

    type state_type is (xp, yp, xn, yn, itp, fin);
    signal state   : state_type;

    signal x : natural range 0 to 79 := 0;
    signal y : natural range 0 to 39 := 0;
    signal it : natural range 0 to 20 := 0;

    signal wen     : std_logic := '0';
    signal addr    : natural range 0 to 2400;
    signal addrT   : natural range 0 to 2400;
    signal q       : std_logic_vector(23 downto 0) := (others => '0');
begin
    vgaText_inst : VGA_text port map (
            clock => clk,
            reset => not rst,
            wen   => not q(21),
            addr  => addr,
            data  => (others=>'0'),
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

    -- State Machine
    -- 12 Hz
    process (q(21), rst)
    begin
        if rst = '0' then
            state <= xp;
        elsif (rising_edge(q(21))) then
            case state is
                when xp =>
                    if x = 79-it then
                        state <= yp;
                    else
                        x <= x + 1;
                        state <= xp;
                    end if;
                when yp =>
                    if y = 29-it then
                        state <= xn;
                    else
                        y <= y + 1;
                        state <= yp;
                    end if;
                when xn =>
                    if x = it then
                        state <= yn;
                    else
                        x <= x - 1;
                        state <= xn;
                    end if;
                when yn =>
                    if y = it + 1 then
                        state <= itp;
                    else
                        y <= y - 1;
                        state <= yn;
                    end if;
                when itp =>
                    if it = 10 then
                        state <= fin;
                    else
                        it <= it + 1;
                        state <= xp;
                    end if;
                when fin =>
                    state <= fin;
            end case;
        end if;
    end process;
    
    process(x, y) is
    begin
        addr <= y * 80 + x;
    end process;

end architecture behavioral;
