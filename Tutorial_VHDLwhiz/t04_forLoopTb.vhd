entity t04_forLoopTb is
end entity;

architecture sim of t04_forLoopTb is
begin

    process is
    begin
        for i in 1 to 10 loop
            report "i=" & integer'image(i);
        end loop;
        wait;
    end process;
	
end architecture;