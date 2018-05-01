


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

    game_end : out std_logic := '0';
    game_winner : out integer range 0 to NB_PLAYERS - 1;

    grid : out td_array_cube_types(ROWS - 1 downto 0, COLS - 1 downto 0) := (others => (0, 0, 0));
);
end game_controller;

architecture behavioural of game_controller is
    -- Cubes types
    -- 0 = empty block
    -- 1..3 = unbreakable block type 0,1,2
    -- 4..6 = breakeable block type 0,1,2

    -- 7..9 = Bombs type 0,1,2
    -- 10 : Explosion, State is color 
	    --	0 : Yellow
	    --	1 : Blue
	    --	2 : Red
	    --	3 : Green
    -- from 11 to 31 : Bonus of malus blocks
    constant EMPTY_BLOCK : integer := 0;
    constant UNBREKEABLE_BLOCK : integer := 0;
    signal cubes_grid : td_array_cube_types(ROWS - 1 downto 0, COLS - 1 downto 0) := (others => (0, 0, 0));

    -- Choices
    constant STATE_MENU_LOADING : integer := 0;
    constant STATE_MAP_INIT : integer := 1;
    constant STATE_GAME : integer := 2;
    constant STATE_DEATH_MODE : integer := 3;
    constant STATE_GAME_OVER : integer := 4;

    signal GAME_STATE : integer range 0 to 2**3 - 1 := STATE_MENU_LOADING;

    -- Players states
    type players_status_type is array(NB_PLAYERS - 1 downto 0) of std_logic;
    signal players_status : players_status_type := (others => '1'); -- 1 = alive, 0 = dead

    -- Players positions
    type players_position_type is array(NB_PLAYERS - 1 downto 0) of vector;
    signal players_positions : players_position_type := (others => (others => 0));

    -- Players bonus and malus
    type state_array_type is array(2**4 - 1 downto 0) of integer range 0 to 2**5 - 1;
    type player_status_type is array(1 downto 0) of state_array_type; -- (bonus_array, malus_array)
    type players_bonus_type is array(NB_PLAYERS downto 0) of player_status_type;
    signal player_status_array : players_bonus_type := (others => (others => (others => 0)));

    constant player_hitbox : vector := (3276, 3276);

    -- Physic engine signals
    signal phy_i : integer range 0 to ROWS - 1 := 0;
    signal phy_j : integer range 0 to COLS - 1 := 0;

    -- Players states
    signal players_collision : players_status_type := (others => '1');

    -- Components
    component collision_detector_rect_rect
    port(
        x_pos, y_pos : vector;
        x_dim, y_dim : vector;
        collision : std_logic;
    );
    end component;
begin

grid <= cubes_grid;

for k in 0 to NB_PLAYERS - 1 generate
    collision_detector_rect_rect
    port map(
        x_pos <= players_positions(k),
        x_dim <= player_hitbox,
        y_pos <= (phy_i * 4096, phy_j * 4096),
        y_dim <= (4096, 4096),
        collision <= players_collision(k)
    )
end generate;

process(CLK)
    signal i : integer range 0 to ROWS - 1 := 0;
    signal j : integer range 0 to COLS - 1 := 0;
    signal tpm : integer range 0 to 2**64 - 1;

    constant sec_per_move : integer := 2;
begin
    if rising_edge(CLK) then
        if rst = '1' then
            i <= 0; j <= 0;
            GAME_STATE <= STATE_MAP_INIT;
            game_end <= '0';
            game_winner <= 0;
        else
            if GAME_STATE = STATE_MAP_INIT then
                -- Generate borders
                if (j = 0 or j = COLS - 1) or (i = 0 or i = ROWS - 1) then
                    cubes_grid(i, j) <= UNBREKEABLE_BLOCK;
                else
                    cubes_grid(i, j) <= EMPTY_BLOCK;
                    -- TODO : Generate entire map
                end if;

                if i = ROWS - 1 and j = COLS - 1 then
                    i <= 0; j <= 0;
                    GAME_STATE <= STATE_GAME;
                else
                    if j = COLS - 1 then
                        j <= 0;
                        i <= i + 1;
                    end if;
                end if;
            elsif GAME_STATE = STATE_GAME then
                case cubes_grid(i,j).category is
                    when 3
                end case;

                if i = ROWS - 1 and j = COLS - 1 then
                    i <= 0; j <= 0;
                else
                    if j = COLS - 1 then
                        j <= 0;
                        i <= i + 1;
                    end if;
                end if;
            elsif GAME_STATE = STATE_DEATH_MODE then
                if tpm = (sec_per_move * FREQUENCY) - 1 then
                    tpm <= 0;
                    cubes_grid(i, j) <= UNBREKEABLE_BLOCK;

                    if i = ROWS - 1 and j = COLS - 1 then
                        GAME_STATE <= STATE_GAME_OVER;
                    else
                        if j = COLS - 1 then
                            j <= 0;
                            i <= i + 1;
                        end if;
                    end if;
                else
                    tpm <= tpm + 1;
                end if;
            elsif GAME_STATE = STATE_GAME_OVER then
                game_end <= '1';
                game_winner <= 0; -- TODO
            end if;
        end if;
    end if;
end process;

end architecture;
