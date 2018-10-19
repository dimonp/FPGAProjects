library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity Snake_Game_top is
    port(
        clk         : in std_logic;
        rst         : in std_logic;
        keyUp       : in std_logic;
        keyDown     : in std_logic;
        keyLeft     : in std_logic;
        keyRight    : in std_logic;
        vgaHs       : out std_logic;
        vgaVs       : out std_logic;
        vgaR        : out std_logic_vector(4 downto 0);
        vgaG        : out std_logic_vector(5 downto 0);
        vgaB        : out std_logic_vector(4 downto 0));

end entity Snake_Game_top;

architecture behavioral of Snake_Game_top is
    constant FIFO_SIZE  : natural := 20;
    constant DONE       : string := "Done!";
    constant DONE_X     : natural := 35;
    constant DONE_Y     : natural := 6;

    constant DISPLAY_WIDTH : natural := 80;
    constant DISPLAY_HEIGHT : natural := 30;

    type t_Snake_state is (sRunUp, sRunDown, sRunLeft, sRunRight, sStop);
    type t_Draw_state is (sHead, sBody, sTail);

    signal wen      : std_logic := '0';
    signal addr     : std_logic_vector (11 downto 0);
    signal data     : std_logic_vector(15 downto 0);
    signal q        : std_logic_vector(23 downto 0) := (others => '0');
    signal isDone   : boolean := false;

    type t_Coords is record
        xc : natural range 0 to DISPLAY_WIDTH-1;
        yc : natural range 0 to 39;
    end record;
    type t_Coords_fifo is array(0 to FIFO_SIZE-1) of t_Coords;
    signal fifo : t_Coords_fifo := (others=>(others=>0));

    function calcAddr(x : natural range 0 to DISPLAY_WIDTH-1;
                      y : natural range 0 to DISPLAY_HEIGHT-1) 
            return std_logic_vector is
    begin
        return std_logic_vector(to_unsigned(y * 80 + x, 12));
    end function calcAddr;

    procedure updateFifo(x : natural range 0 to DISPLAY_WIDTH-1;
                         y : natural range 0 to DISPLAY_HEIGHT-1) is
    begin
        -- This loop is unrolled by the synthesis tool.
        for i in FIFO_SIZE-1 downto 1 loop
            fifo(i) <= fifo(i-1);
        end loop;

        -- insert into position zero
        fifo(0) <= (xc=>x, yc=>y);
    end procedure updateFifo;

    component VGA_text
        port (
            clock   : in std_logic;
            reset   : in std_logic;
            wen     : in std_logic;
            addr    : in std_logic_vector (11 downto 0);
            data    : in std_logic_vector(15 downto 0);
            hsync   : out std_logic;
            vsync   : out std_logic;
            r       : out std_logic_vector(4 downto 0);
            g       : out std_logic_vector(5 downto 0);
            b       : out std_logic_vector(4 downto 0));
    end component;
begin
    vgaText_inst : VGA_text port map (
            clock => clk,
            reset => not rst,
            wen   => not q(20),
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

    -- State Machine
    -- 6 Hz
    process (q(22), rst)
        variable x      : natural range 0 to DISPLAY_WIDTH-1 := 0;
        variable y      : natural range 0 to DISPLAY_HEIGHT-1 := 0;
        variable state  : t_Snake_state := sStop;
        variable delta_x : integer;
        variable delta_y : integer;

        procedure changeState(currentState : t_Snake_state) is
        begin
            if keyUp = '0' and state /= sRunDown then
                state := sRunUp;
            elsif keyDown = '0' and state /= sRunUp then
                state := sRunDown;
            elsif keyLeft = '0' and state /= sRunRight then
                state := sRunLeft;
            elsif keyRight = '0' and state /= sRunLeft then
                state := sRunRight;
            end if;
        end procedure changeState;

        function updateX(x      : natural range 0 to DISPLAY_WIDTH-1; 
                         delta  : integer) 
                return natural is
            variable tmp_x : integer;
        begin
            tmp_x := x + delta;

            if tmp_x > DISPLAY_WIDTH-1 then
                tmp_x := 0;
            elsif tmp_x < 0 then
                tmp_x := DISPLAY_WIDTH-1;
            end if;
    
            return tmp_x;
        end function updateX;

        function updateY(y      : natural range 0 to DISPLAY_HEIGHT-1; 
                         delta  : integer) 
                return natural is
            variable tmp_y : integer;
        begin
            tmp_y := y + delta;

            if tmp_y > DISPLAY_HEIGHT-1 then
                tmp_y := 0;
            elsif tmp_y < 0 then
                tmp_y := DISPLAY_HEIGHT-1;
            end if;
    
            return tmp_y;
        end function updateY;

    begin   
        if rst = '0' then
            x := 0;
            y := 0;
            state := sStop;
            isDone <= false;
        elsif rising_edge(q(22)) then
            changeState(state);

            case state is
                when sRunUp =>
                    delta_x := 0;
                    delta_y := -1;
                when sRunDown =>
                    delta_x := 0;
                    delta_y := 1;
                when sRunLeft =>
                    delta_x := -1;
                    delta_y := 0;
                when sRunRight =>
                    delta_x := 1;
                    delta_y := 0;
                when sStop =>
                    delta_x := 1;
                    delta_y := 0;
            end case;

            x := updateX(x, delta_x);
            y := updateY(y, delta_y);

            updateFifo(x, y);
        end if;
    end process;

    -- 24 Hz
    process(q(20))
        variable state      : t_Draw_State := sHead;
        variable drawAddr   : std_logic_vector (11 downto 0);
        variable drawData   : std_logic_vector(15 downto 0);
    begin
        if rising_edge(q(20)) then
            case state is
                when sHead =>
                    drawAddr := calcAddr(fifo(0).xc, fifo(0).yc);
                    drawData := "0000001000000010";
                    state := sBody;
                when sBody =>
                    drawAddr := calcAddr(fifo(1).xc, fifo(1).yc);
                    drawData := "0000001000000001";
                    state := sTail;
                when sTail =>
                    drawAddr := calcAddr(fifo(FIFO_SIZE-1).xc, fifo(FIFO_SIZE-1).yc);
                    drawData := (others=>'0');
                    state := sHead;
            end case;

            addr <= drawAddr;
            data <= drawData;
        end if;
    end process;

    process(q(20))
        variable idx : natural range 0 to DONE'length-1 := 0;
    begin
        if rising_edge(q(20)) then
            if isDone then -- show done message
                if idx < DONE'length then
                    idx := idx + 1;
                end if;

                --addr <= calcAddr(DONE_X + idx, DONE_Y);
                --data <= "00000010" &  std_logic_vector(to_unsigned(character'pos(DONE(idx)),8));
            end if;
        end if;
    end process;
    
end architecture behavioral;
