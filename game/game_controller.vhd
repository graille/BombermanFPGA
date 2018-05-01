


entity game_controller
generic(
    ROWS : integer := 15;
    COLS : integer := 14;
    FREQUENCY : integer := 10**8;
    NB_PLAYERS : integer := 2
);
port(
    clk, rst : in std_logic;
    action : in std_logic_vector(16 downto 0)
);
end game_controller;


architecture behavioural of game_controller is
    -- Cubes types
    -- 0 = empty block
    -- 1 = unbreakable block
    -- 2 = breakacle block

    constant EMPTY_BLOCK : integer := 0;
    constant UNBREKEABLE_BLOCK : integer := 0;
    constant EMPTY_BLOCK : integer := 0;
    constant EMPTY_BLOCK : integer := 0;

    -- from 3 to 15 : Bonus of malus blocks
    signal cubes_grid : td_array_cube_types(ROWS - 1 downto 0, COLS - 1 downto 0) := (others => (others => '0'));

    -- Choices
    constant STATE_MENU_LOADING : integer := 0;
    constant STATE_MAP_INIT : integer := 1;
    constant STATE_GAME : integer := 2;
    constant STATE_DEATH_MODE : integer := 3;

    signal GAME_STATE : integer range 0 to 2**3 - 1 := STATE_MENU_LOADING;

    -- Players states
    type players_status_type is array(NB_PLAYERS - 1 downto 0) of std_logic;
    signal players_status : players_status_type := (others => '1'); -- 1 = alive, 0 = dead

    -- Players bonus and malus
    type state_array_type is array(2**4 - 1 downto 0) of integer range 0 to 2**5 - 1;
    type player_status_type is array(1 downto 0) of state_array_type; -- (bonus_array, malus_array)
    type players_bonus_type is array(NB_PLAYERS downto 0) of player_status_type;

    signal player_status_array : players_bonus_type := (others => (others => (others => 0)));
begin

-- Map generation
process(GAME_STATE)
begin
    if GAME_STATE = STATE_MAP_INIT then
        -- Generate borders
        for i in 0 to ROWS - 1 loop
            cubes_grid(i, 0) <= UNBREKEABLE_BLOCK;
            cubes_grid(i, COLS - 1) <= UNBREKEABLE_BLOCK;
        end loop;

        for i in 0 to COLS - 1 loop
            cubes_grid(0, i) <= UNBREKEABLE_BLOCK;
            cubes_grid(ROWS - 1, i) <= UNBREKEABLE_BLOCK;
        end loop;

        -- TODO : Generate entire map

        -- Generate map (except for corners)
        GAME_STATE <= STATE_GAME;
    end if;
end process;


-- Death mode
process(CLK)
    signal i : integer range 0 to ROWS - 1 := 0;
    signal j : integer range 0 to COLS - 1 := 0;
    signal tpm : integer range 0 to 2**64 - 1;

    constant sec_per_move : integer := 2;
begin
    if rising_edge(CLK) then
        if rst = '1' then
            i <= 0;
            j <= 0;
        else
            if GAME_STATE = STATE_DEATH_MODE then
                if tpm = 0 then
                    cubes_grid(i, j) <= UNBREKEABLE_BLOCK;
                    j <= j + 1;
                    i <= i + 1;
                else
                    tpm <= (tpm + 1) mod (sec_per_move * FREQUENCY);
                end if;
            end if;
        end if;
    end if;
end process;

end architecture;
