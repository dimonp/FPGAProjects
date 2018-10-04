entity t03_loopTb is
end entity;

architecture sim of t03_loopTb is
begin

    process is
    begin
        report "Hello!";
        loop
            report "Peekaboo!";
            exit;
        end loop;
        report "Goodbye!";
        wait;
    end process;
	
end architecture;