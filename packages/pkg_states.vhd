package PROJECT_GAME_STATES_PKG is
    -- Choices
    constant STATE_START : integer := 0;
    constant STATE_MENU_LOADING : integer := 1;
    constant STATE_MAP_INIT : integer := 2;
    constant STATE_GAME : integer := 3;
        constant STATE_GAME_PLAYERS_BOMB_CHECK : integer := 4;
        constant STATE_GAME_GRID_UPDATE : integer := 5;
            constant STATE_GAME_BOMB_EXPLODE : integer := 6;
        constant STATE_GAME_CHECK_PLAYERS_DOG : integer := 7;
    constant STATE_DEATH_MODE : integer := 8;
        constant STATE_DEATH_MODE_PLACE_BLOCK : integer := 9;
        constant STATE_DEATH_MODE_CHECK_DEATH : integer := 10;
    constant STATE_GAME_OVER : integer := 11;

    subtype game_state_type is integer range 0 to STATE_GAME_OVER;
end package;
