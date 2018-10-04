entity t02_waitForTb is
end entity;

architecture sim of t02_waitForTb is
begin

    process is
    begin
        report "Peekaboo!";
        wait for 10 ns;
    end process;
	
end architecture;