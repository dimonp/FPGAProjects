entity t09_sensitivityListTb is
end entity;

architecture sim of t09_sensitivityListTb is
    signal countUp   : integer := 0;
    signal countDown : integer := 10;
begin

    process is
    begin
        countUp <= countUp + 1;
        countDown <= countDown - 1;
        wait for 10 ns;
    end process;
    
    -- Process triggered using Wait On
    process is
    begin
        if countUp = countDown then
            report "Process A: Jackpot!";
        end if;

        wait on countUp, countDown;
    end process;

    -- Process triggered using sensitivity list
    process(countUp, countDown) is
    begin
        if countUp = countDown then
            report "Process B: Jackpot!";
        end if;
    end process;
    
end architecture;