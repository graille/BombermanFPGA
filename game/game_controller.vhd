library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.PROJECT_PARAMS_PKG.all;
use work.PROJECT_TYPES_PKG.all;
use work.PROJECT_DIRECTION_PKG.all;
use work.PROJECT_GAME_STATES_PKG.all;
use work.PROJECT_BLOCKS_PKG.all;
use work.PROJECT_POS_FUNCTIONS_PKG.all;

entity game_controller is
    generic(
        SEED_LENGTH : integer := 16;
        FREQUENCY : integer := 70_000_000
    );
    port(
        clk, rst : in std_logic;

        -- PRNG control signals
        in_seed : in std_logic_vector(SEED_LENGTH - 1 downto 0);

        -- I/O informations
        in_io_state : in std_logic;
        out_io_command_request : out integer range 0 to NB_CONTROLS - 1;
        out_io_player_request : out integer range 0 to NB_PLAYERS - 1;

        -- Game informations
        game_end : out std_logic := '0';
        game_winner : out integer range 0 to NB_PLAYERS - 1;

        -- Grid informations
        out_grid_position : out grid_position;
        out_block : out block_type;
        out_write : out std_logic;

        in_read_block : in block_type;

        -- Players informations
        in_requested_player : in integer range 0 to NB_PLAYERS - 1;
        out_player_position: out vector;
        out_player_status: out player_status_type;

        -- Time remaining
        out_time_remaining : out millisecond_count := 0
    );
end game_controller;

architecture behavioral of game_controller is
    -- Millisecond counter
    signal millisecond : millisecond_count := 0;
    signal time_remaining : millisecond_count := 0;

    -- Physics engines
    signal players_collision : std_logic_vector(NB_PLAYERS - 1 downto 0) := (others => '0');

    ---------------------------------------------------------------------------
    -- Commands
    ---------------------------------------------------------------------------
    signal current_command : integer range 0 to NB_CONTROLS - 1 := 0;
    signal last_command_update : time_count_2d_array_type(NB_CONTROLS - 1 downto 0, NB_PLAYERS - 1 downto 0) := (others => (others => 0));

    ---------------------------------------------------------------------------
    -- Player values
    ---------------------------------------------------------------------------
    constant PLAYER_INITIAL_POSITION : vector := DEFAULT_VECTOR_POSITION;

    constant PLAYER_DEFAULT_SPEED : integer := 2;

    signal current_player : integer range 0 to NB_PLAYERS - 1 := 0;

    -- Players informations
    signal players_position : array_vector(NB_PLAYERS - 1 downto 0) := (others => DEFAULT_VECTOR_POSITION);
    signal players_grid_position : players_grid_position_type := (others => (others => 0));

    type players_dol_type is array(NB_PLAYERS - 1 downto 0) of std_logic_vector(3 downto 0);
    signal players_dol : players_dol_type := (others => (others => '0'));

    subtype player_speed_type is integer range 0 to 2**6 - 1;
    type players_speed_type is array(NB_PLAYERS - 1 downto 0) of player_speed_type;
    signal players_speed : players_speed_type := (others => PLAYER_DEFAULT_SPEED);

    type players_power_type is array(NB_PLAYERS - 1 downto 0) of integer range 0 to MAX_PLAYER_POWER - 1;
    signal players_power : players_power_type := (others => 1);

    type players_bombs_counter is array(NB_PLAYERS - 1 downto 0) of integer range 0 to 31;
    signal players_max_bombs : players_bombs_counter := (others => 10);
    signal players_nb_bombs : players_bombs_counter := (others => 0);
    signal players_can_plant_bomb : std_logic_vector(NB_PLAYERS - 1 downto 0) := (others => '1');

    -- Bonus
    signal players_god_mode : std_logic_vector(NB_PLAYERS - 1 downto 0) := (others => '0');
    signal players_wall_hack : std_logic_vector(NB_PLAYERS - 1 downto 0) := (others => '0');

    type players_lives_type is array(NB_PLAYERS - 1 downto 0) of integer range 0 to 3;
    signal players_lives : players_lives_type := (others => 1);

    -- Malus
    signal players_inversed_commands : std_logic_vector(NB_PLAYERS - 1 downto 0) := (others => '0');

    -- Player counters
    constant PLAYER_GOD_MOD_DURATION : integer := 5000;
    constant PLAYER_WALL_HACK_DURATION : integer := 10000;
    constant PLAYER_NO_BOMBS_DURATION : integer := 7000;
    constant PLAYER_INVERSED_COMMANDS_DURATION : integer := 7000;

    signal players_god_mode_activation : time_count_array_type(NB_PLAYERS - 1 downto 0) := (others => 0);
    signal players_wall_hack_activation : time_count_array_type(NB_PLAYERS - 1 downto 0) := (others => 0);
    signal players_no_bombs_activation : time_count_array_type(NB_PLAYERS - 1 downto 0) := (others => 0);
    signal players_inversed_commands_activation : time_count_array_type(NB_PLAYERS - 1 downto 0) := (others => 0);

    type players_status_type is array(NB_PLAYERS - 1 downto 0) of player_status_type;
    signal players_status : players_status_type := (others => DEFAULT_PLAYER_STATUS);

    function GRID_TO_VECTOR(pos : grid_position)
        return vector is
    begin
        return (pos.i * DEFAULT_BLOCK_SIZE_X, pos.j * DEFAULT_BLOCK_SIZE_Y);
    end GRID_TO_VECTOR;

    function INIT_PLAYER_POSITION(nb : integer)
        return vector is
        variable grid_reset_position : grid_position := DEFAULT_GRID_POSITION;
    begin
        case nb is
            when 0 => grid_reset_position := (1, 1);
            when 1 => grid_reset_position := (1, GRID_COLS - 2);
            when 2 => grid_reset_position := (GRID_ROWS - 2, 1);
            when 3 => grid_reset_position := (GRID_ROWS - 2, GRID_COLS - 2);
            when others => grid_reset_position := (2, 2);
        end case;

        return GRID_TO_VECTOR(grid_reset_position);
--        return (grid_reset_position.i * DEFAULT_BLOCK_SIZE_X + 1, grid_reset_position.j * DEFAULT_BLOCK_SIZE_Y + 1);
    end INIT_PLAYER_POSITION;

    function INIT_PLAYER_DIRECTION(nb : integer)
        return direction_type is
        variable direction : direction_type := D_DOWN;
    begin
        case nb is
            when 0 => direction := D_DOWN;
            when 1 => direction := D_DOWN;
            when 2 => direction := D_UP;
            when 3 => direction := D_UP;
            when others => direction := D_DOWN;
        end case;

        return direction;
    end INIT_PLAYER_DIRECTION;

    ---------------------------------------------------------------------------
    -- PRNG value
    ---------------------------------------------------------------------------
    signal prng_value: std_logic_vector(PRNG_PRECISION - 1 downto 0);
    signal prng_percent : integer range 0 to 100;

    -- Choices
    type game_state_type is (
        STATE_START,
        STATE_MENU_LOADING,

        STATE_MAP_REINIT,
        STATE_MAP_INIT,
            -- Place unbreakable blocks around the grid
            STATE_MAP_BUILD_UNBREAKABLE_BORDER,
            STATE_MAP_BUILD_UNBREAKABLE_BORDER_ROTATE,

            -- Place unbreakable blocks inside the grid
            STATE_MAP_BUILD_UNBREAKABLE_INSIDE,
            STATE_MAP_BUILD_UNBREAKABLE_INSIDE_ROTATE,

            -- Place breakeable blocks
            STATE_MAP_BUILD_BREAKABLE,
            STATE_MAP_BUILD_BREAKABLE_ROTATE,

        STATE_PLAYERS_INIT,
        STATE_PLAYERS_INIT_ROTATE,

        STATE_GAME,
            STATE_GAME_UPDATE_TIME_REMAINING,

            -- Check and update players position
            STATE_UPDATE_PLAYERS_POSITION,
            STATE_UPDATE_PLAYERS_POSITION_WAIT,
            STATE_UPDATE_PLAYERS_POSITION_ROTATE_PLAYER,
            STATE_UPDATE_PLAYERS_POSITION_ROTATE_COMMAND,

            -- Check and update players status
            STATE_UPDATE_PLAYERS_STATUS,
            STATE_UPDATE_PLAYERS_STATUS_ROTATE,

            -- Update players degrees of liberty
            STATE_GAME_PLAYERS_DOL,
            STATE_GAME_PLAYERS_DOL_WAIT,
            STATE_GAME_PLAYERS_DOL_GET_BLOCK,
            STATE_GAME_PLAYERS_DOL_ROTATE_POSITION,
            STATE_GAME_PLAYERS_DOL_ROTATE_PLAYER,

            -- Check and update each blocks of the grid
            STATE_GAME_GRID_UPDATE,
            STATE_GAME_GRID_UPDATE_WAIT,
            STATE_GAME_GRID_UPDATE_ROTATE,
                STATE_GAME_GRID_UPDATE_ANIMATION,
                STATE_GAME_GRID_UPDATE_ANIMATION_WAIT,
                
                
                STATE_GAME_GRID_UPDATE_PLAYERS_ATTRIBUTES,

                -- Explose bombs if needed
                STATE_GAME_GRID_CHECK_BOMBS_PROPAGATION,
                STATE_GAME_GRID_CHECK_BOMBS_PROPAGATION_WAIT,
                STATE_GAME_GRID_CHECK_BOMBS_PROPAGATION_GET_BLOCK,
                STATE_GAME_GRID_CHECK_BOMBS_PROPAGATION_ROTATE_POSITION,
                
                STATE_GAME_GRID_CHECK_BOMBS_RESULT,

            -- Death mode : final mode
            STATE_CHECK_DEATH_MODE,

        STATE_DEATH_MODE,
            STATE_DEATH_MODE_PLACE_BLOCK,
            STATE_DEATH_MODE_CHECK_DEATH,
        STATE_GAME_OVER
    );

    signal current_state : game_state_type := STATE_START;
    signal current_grid_position : grid_position := DEFAULT_GRID_POSITION;
    signal death_mode_activated : std_logic := '0';

begin
    -- Grid position updater
    out_grid_position <= current_grid_position;

    -- Player information transmitter
    out_player_position <= players_position(in_requested_player);
    out_player_status <= players_status(in_requested_player);

    -- I/O output manager
    out_io_command_request <= current_command;
    out_io_player_request <= current_player;

    -- Time remaining output
    out_time_remaining <= time_remaining;

    PRNG_GENERATOR:entity work.simple_prng_lfsr
        generic map (
            DATA_LENGTH => PRNG_PRECISION,
            SEED_LENGTH => SEED_LENGTH
        )
        port map (
            clk => clk,
            rst => RST,

            in_seed => in_seed,
            random_output => prng_value,
            percent => prng_percent
        );

    -- Millisecond counter
    COUNTER_ENGINE:entity work.millisecond_counter
        generic map (
            FREQUENCY => FREQUENCY
        )
        port map (
            CLK => CLK,
            RST => RST,
            timer => millisecond
        );

    -- Instantiate collisions detectors
    PHYSIC_GENERATOR:for K in 0 to NB_PLAYERS - 1 generate
        I_PLAYER_PHYSIC_ENGINE:entity work.collision_detector_rect_rect
            port map(
                clk => clk,

                r1_pos => players_position(K),
                r1_dim => DEFAULT_PLAYER_HITBOX,
                r2_pos => GRID_TO_VECTOR(current_grid_position),
                r2_dim => DEFAULT_BLOCK_SIZE,

                are_colliding => players_collision(K)
            );

        I_PLAYER_POSITION_CONVERTER:entity work.player_to_grid
            port map(
                clk => clk,
                in_player_position => players_position(K),
                out_position => players_grid_position(K)
            );
    end generate;


    process(clk)
        variable real_speed : player_speed_type := 0;
        variable collision_block_position : integer range 0 to 4 := 0;
        variable nb_players_alive : integer range 0 to NB_PLAYERS - 1;
        
        variable waiting_clocks : integer range 0 to 15 := 2;
        
        variable position_state : integer range 0 to 3 := 0;
    begin
        if rising_edge(CLK) then
            if RST = '1' then
                current_state <= STATE_START;
            else
                case current_state is
                    when STATE_START =>
                        -- Reinit players parameters
                        last_command_update <= (others => (others => 0));

                        players_dol <= (others => (others => '1'));
                        players_speed <= (others => PLAYER_DEFAULT_SPEED);

                        players_nb_bombs <= (others => 0);
                        players_max_bombs <= (others => 1);
                        players_can_plant_bomb <= (others => '1');

                        players_power <= (others => 1);

                        players_god_mode <= (others => '0');
                        players_wall_hack <= (others => '0');
                        players_lives <= (others => 1);

                        players_inversed_commands <= (others => '0');
                        players_status <= (others => DEFAULT_PLAYER_STATUS);

                        players_god_mode_activation <= (others => 0);
                        players_wall_hack_activation <= (others => 0);
                        players_no_bombs_activation <= (others => 0);
                        players_inversed_commands_activation <= (others => 0);

                        -- Reinit global parameters
                        current_command <= 0;
                        current_player <= 0;
                        out_write <= '0';
                        out_block <= (EMPTY_BLOCK, 0, 0, millisecond, 0, 0);

                        death_mode_activated <= '0';

                        current_grid_position <= DEFAULT_GRID_POSITION;
                        current_state <= STATE_MENU_LOADING;
                    when STATE_MENU_LOADING =>
                        current_state <= STATE_MAP_REINIT;
                    ----------------------------------------------------------------
                    when STATE_MAP_REINIT =>
                        out_block <= (EMPTY_BLOCK, 0, 0, 0, 0, 0);
                        out_write <= '1';

                        if current_grid_position = DEFAULT_LAST_GRID_POSITION then
                            current_state <= STATE_MAP_INIT;
                            current_grid_position <= DEFAULT_GRID_POSITION;
                        else
                            current_grid_position <= INCR_POSITION_LINEAR(current_grid_position);
                        end if;
                    when STATE_MAP_INIT =>
                        current_state <= STATE_MAP_BUILD_UNBREAKABLE_BORDER;
                    when STATE_MAP_BUILD_UNBREAKABLE_BORDER =>
                        -- Place block
                        out_block <= (UNBREAKABLE_BLOCK_1, 0, 0, millisecond, 0, 0);
                        out_write <= '1';

                        current_state <= STATE_MAP_BUILD_UNBREAKABLE_BORDER_ROTATE;
                    when STATE_MAP_BUILD_UNBREAKABLE_BORDER_ROTATE =>
                        out_write <= '0';
                        if current_grid_position = DEFAULT_LAST_GRID_POSITION then
                            current_grid_position <= DEFAULT_GRID_POSITION;
                            current_state <= STATE_MAP_BUILD_BREAKABLE;
                        else
                            current_grid_position <= INCR_POSITION_BORDER(current_grid_position);
                            current_state <= STATE_MAP_BUILD_UNBREAKABLE_BORDER;
                        end if;

                    when STATE_MAP_BUILD_BREAKABLE =>
                        if
                            prng_percent > 25
                            and current_grid_position.i /= 0 and current_grid_position.i /= GRID_ROWS - 1
                            and current_grid_position.j /= 0 and current_grid_position.j /= GRID_COLS - 1
                            and current_grid_position /= (1, 1) and current_grid_position /= (1,2) and current_grid_position /= (2,1)
                            and current_grid_position /= (GRID_ROWS - 2, 1) and current_grid_position /= (GRID_ROWS - 2,2) and current_grid_position /= (GRID_ROWS - 3,1)
                            and current_grid_position /= (GRID_ROWS - 2, GRID_COLS - 2) and current_grid_position /= (GRID_ROWS - 2, GRID_COLS - 3) and current_grid_position /= (GRID_ROWS - 3, GRID_COLS - 2)
                            and current_grid_position /= (1, GRID_COLS - 2) and current_grid_position /= (1,GRID_COLS - 3) and current_grid_position /= (2,GRID_COLS - 2)
                        then
                            out_write <= '1';
                            out_block <= (BREAKABLE_BLOCK_0, 0, 0, millisecond, 0, 0);
                        else
                            out_write <= '0';
                        end if;

                        current_state <= STATE_MAP_BUILD_BREAKABLE_ROTATE;
                    when STATE_MAP_BUILD_BREAKABLE_ROTATE =>
                        out_write <= '0';
                        if current_grid_position /= DEFAULT_LAST_GRID_POSITION then
                            current_grid_position <= INCR_POSITION_LINEAR(current_grid_position);
                            current_state <= STATE_MAP_BUILD_BREAKABLE;
                        else
                            current_grid_position <= DEFAULT_GRID_POSITION;
                            current_state <= STATE_MAP_BUILD_UNBREAKABLE_INSIDE;
                        end if;

                    when STATE_MAP_BUILD_UNBREAKABLE_INSIDE =>
                        if
                            current_grid_position.i /= 1 and current_grid_position.i /= GRID_ROWS - 2 and current_grid_position.i mod 2 = 0
                            and current_grid_position.j /= 1 and current_grid_position.j /= GRID_COLS - 2 and current_grid_position.j mod 2 = 0
                            and current_grid_position.i /= 0 and current_grid_position.i /= GRID_ROWS - 1
                            and current_grid_position.j /= 0 and current_grid_position.j /= GRID_COLS - 1
                        then
                            out_block <= (UNBREAKABLE_BLOCK_2, 0, 0, millisecond, 0, 0);
                            out_write <= '1';
                        else
                            out_write <= '0';
                        end if;

                        current_state <= STATE_MAP_BUILD_UNBREAKABLE_INSIDE_ROTATE;
                    when STATE_MAP_BUILD_UNBREAKABLE_INSIDE_ROTATE =>
                        out_write <= '0';
                        if current_grid_position /= DEFAULT_LAST_GRID_POSITION then
                            current_grid_position <= INCR_POSITION_LINEAR(current_grid_position);
                            current_state <= STATE_MAP_BUILD_UNBREAKABLE_INSIDE;
                        else
                            current_grid_position <= DEFAULT_GRID_POSITION;
                            current_state <= STATE_PLAYERS_INIT;
                        end if;

                    when STATE_PLAYERS_INIT =>
                        players_position(current_player) <= INIT_PLAYER_POSITION(current_player);
                        players_status(current_player).direction <= INIT_PLAYER_DIRECTION(current_player);
                        players_status(current_player).id <= (current_player + players_status(current_player).id + 1) mod 7;

                        current_state <= STATE_PLAYERS_INIT_ROTATE;
                    when STATE_PLAYERS_INIT_ROTATE =>
                        if current_player = NB_PLAYERS - 1 then
                            current_player <= 0;
                            current_state <= STATE_GAME;
                        else
                            current_player <= (current_player + 1) mod NB_PLAYERS;
                            current_state <= STATE_PLAYERS_INIT;
                        end if;

                    ----------------------------------------------------------------
                    when STATE_GAME =>
                        -- Calculate nb players alive
--                        nb_players_alive := NB_PLAYERS;
--                        for L in 0 to NB_PLAYERS - 1 loop
--                            if players_status(L).is_alive = '0' then
--                                nb_players_alive := nb_players_alive - 1;
--                            end if;
--                        end loop;

                        -- Switch to next state
--                        if nb_players_alive <= 1 then
--                            current_state <= STATE_GAME_OVER;
--                        else
                            current_state <= STATE_GAME_UPDATE_TIME_REMAINING;
--                        end if;
                    when STATE_GAME_UPDATE_TIME_REMAINING =>
                        if death_mode_activated = '0' then
                            time_remaining <= NORMAL_MODE_DURATION - millisecond;
                        else
                            time_remaining <= (NORMAL_MODE_DURATION + DEATH_MODE_DURATION) - millisecond;
                        end if;

                        current_state <= STATE_UPDATE_PLAYERS_POSITION_WAIT;

                        -- Update players position
                    when STATE_UPDATE_PLAYERS_POSITION =>
                        case players_inversed_commands(current_player) is
                            when '0' =>
                                real_speed := players_speed(current_player);
                            when '1' =>
                                real_speed := -1 * players_speed(current_player);
                            when others => null;
                        end case;

                        -- Update position
                        if millisecond - last_command_update(current_command, current_player) >= 3 then
                            last_command_update(current_command, current_player) <= millisecond;

                            if in_io_state = '1' then
                                case current_command is
                                     when D_UP =>
                                        if players_dol(current_player)(D_UP) = '1' or players_wall_hack(current_player) = '1' then
                                            players_position(current_player).X <= (players_position(current_player).X - real_speed) mod VECTOR_PRECISION_X;
                                        end if;
                                        players_status(current_player).direction <= D_UP;

                                    when D_DOWN =>
                                        if players_dol(current_player)(D_DOWN) = '1' or players_wall_hack(current_player) = '1' then
                                            players_position(current_player).X <= (players_position(current_player).X + real_speed) mod VECTOR_PRECISION_X;
                                        end if;
                                        players_status(current_player).direction <= D_DOWN;
                                    when D_LEFT =>
                                        if players_dol(current_player)(D_LEFT) = '1' or players_wall_hack(current_player) = '1' then
                                            players_position(current_player).Y <= (players_position(current_player).Y - real_speed) mod VECTOR_PRECISION_Y;
                                        end if;
                                        players_status(current_player).direction <= D_LEFT;
                                    when D_RIGHT =>
                                        if players_dol(current_player)(D_RIGHT) = '1' or players_wall_hack(current_player) = '1' then
                                            players_position(current_player).Y <= (players_position(current_player).Y + real_speed) mod VECTOR_PRECISION_Y;
                                        end if;
                                        players_status(current_player).direction <= D_RIGHT;
                                    when 4 =>
                                        if
                                            players_nb_bombs(current_player) < players_max_bombs(current_player)
                                            and players_can_plant_bomb(current_player) = '1'
                                        then
                                            -- Write the bomb on the grid
                                            current_grid_position <= players_grid_position(current_player);
                                            out_block <= (BOMB_BLOCK_0, 0, 0, millisecond, current_player, 0);
                                            out_write <= '1';

                                            -- Update player parameters
                                            players_nb_bombs(current_player) <= players_nb_bombs(current_player) + 1;
                                        end if;
                                    when others => null;
                                end case;
                            end if;
                        end if;

                        -- Switch to next state
                        current_state <= STATE_UPDATE_PLAYERS_POSITION_ROTATE_PLAYER;
                    when STATE_UPDATE_PLAYERS_POSITION_WAIT =>
                        current_state <= STATE_UPDATE_PLAYERS_POSITION;
                    when STATE_UPDATE_PLAYERS_POSITION_ROTATE_PLAYER =>
                        if current_player = NB_PLAYERS - 1 then
                            current_player <= 0;
                            current_state <= STATE_UPDATE_PLAYERS_POSITION_ROTATE_COMMAND;
                        else
                            current_player <= current_player + 1;
                            current_state <= STATE_UPDATE_PLAYERS_POSITION_WAIT;
                        end if;
                    when STATE_UPDATE_PLAYERS_POSITION_ROTATE_COMMAND =>
                        out_write <= '0';
                        current_grid_position <= DEFAULT_GRID_POSITION;

                        if current_command = NB_CONTROLS - 1 then
                            current_state <= STATE_UPDATE_PLAYERS_STATUS;
                            current_command <= 0;
                            current_player <= 0;
                        else
                            current_command <= current_command + 1;
                            current_player <= 0;
                            current_state <= STATE_UPDATE_PLAYERS_POSITION_WAIT;
                        end if;

                        -- Update players status
                    when STATE_UPDATE_PLAYERS_STATUS =>
--                        if (millisecond - players_god_mode_activation(current_player)) >= PLAYER_GOD_MOD_DURATION then
--                            players_god_mode(current_player) <= '0';
--                            players_god_mode_activation(current_player) <= 0;
--                        end if;

--                        if (millisecond - players_wall_hack_activation(current_player)) >= PLAYER_WALL_HACK_DURATION then
--                            players_wall_hack(current_player) <= '0';
--                            players_wall_hack_activation(current_player) <= 0;
--                        end if;

--                        if (millisecond - players_no_bombs_activation(current_player)) >= PLAYER_NO_BOMBS_DURATION then
--                            players_can_plant_bomb(current_player) <= '1';
--                            players_no_bombs_activation(current_player) <= 0;
--                        end if;

--                        if (millisecond - players_inversed_commands_activation(current_player)) >= PLAYER_INVERSED_COMMANDS_DURATION then
--                            players_inversed_commands(current_player) <= '0';
--                             players_inversed_commands_activation(current_player) <= 0;
--                        end if;

                        current_state <= STATE_UPDATE_PLAYERS_STATUS_ROTATE;
                    when STATE_UPDATE_PLAYERS_STATUS_ROTATE =>
                        if current_player = NB_PLAYERS - 1 then
                            current_player <= 0;
                            current_state <= STATE_GAME_PLAYERS_DOL_GET_BLOCK;
                        else
                            current_player <= current_player + 1;
                            current_state <= STATE_UPDATE_PLAYERS_STATUS;
                        end if;

                        -- Update players DOL       
                    when STATE_GAME_PLAYERS_DOL =>
                        if (players_collision(current_player) = '0') or (in_read_block.category = EMPTY_BLOCK) then
                            players_dol(current_player)(position_state) <= '1';
                        else
                            players_dol(current_player)(position_state) <= '0';
                        end if;
                        
                        current_state <= STATE_GAME_PLAYERS_DOL_ROTATE_POSITION;
                    
                    when STATE_GAME_PLAYERS_DOL_WAIT =>
                        waiting_clocks := waiting_clocks - 1;
                        
                        if waiting_clocks = 0 then
                            waiting_clocks := 2;
                            current_state <= STATE_GAME_PLAYERS_DOL;
                        end if;     
                    
                    when STATE_GAME_PLAYERS_DOL_GET_BLOCK =>
                        case position_state is
                            when D_UP => current_grid_position <= (players_grid_position(current_player).i - 1, players_grid_position(current_player).j);
                            when D_RIGHT => current_grid_position <= (players_grid_position(current_player).i, players_grid_position(current_player).j + 1);
                            when D_DOWN => current_grid_position <= (players_grid_position(current_player).i + 1, players_grid_position(current_player).j);
                            when D_LEFT => current_grid_position <= (players_grid_position(current_player).i, players_grid_position(current_player).j - 1);
                            when others => null;
                        end case;
                        
                        current_state <= STATE_GAME_PLAYERS_DOL_WAIT;
                    
                    when STATE_GAME_PLAYERS_DOL_ROTATE_POSITION => 
                        if position_state = 3 then
                            position_state := 0;
                            current_state <= STATE_GAME_PLAYERS_DOL_ROTATE_PLAYER;
                        else
                            position_state := (position_state + 1) mod 4;
                            current_state <= STATE_GAME_PLAYERS_DOL_GET_BLOCK;
                        end if;
                        
                    when STATE_GAME_PLAYERS_DOL_ROTATE_PLAYER =>
                        position_state := 0;
                        
                        if current_player = NB_PLAYERS - 1 then
                            current_player <= 0;
                            current_state <= STATE_GAME_GRID_UPDATE;
                        else
                            current_player <= current_player + 1;
                            current_state <= STATE_GAME_PLAYERS_DOL_GET_BLOCK;
                        end if;

                        -- Update grid
                    when STATE_GAME_GRID_UPDATE =>
                        current_state <= STATE_GAME_GRID_UPDATE_ANIMATION;
                    when STATE_GAME_GRID_UPDATE_ROTATE =>
                        if current_grid_position = DEFAULT_LAST_GRID_POSITION then
                            current_grid_position <= DEFAULT_GRID_POSITION;
                            current_state <= STATE_CHECK_DEATH_MODE;
                        else
                            current_grid_position <= INCR_POSITION_LINEAR(current_grid_position);
                            current_state <= STATE_GAME_GRID_UPDATE_WAIT;
                        end if;
                    when STATE_GAME_GRID_UPDATE_WAIT =>
                        waiting_clocks := waiting_clocks - 1;
                        
                        if waiting_clocks = 0 then
                            waiting_clocks := 2;
                            current_state <= STATE_GAME_GRID_UPDATE;
                        end if;
                   
                        -- Animate blocks
                    when STATE_GAME_GRID_UPDATE_ANIMATION =>
                        case in_read_block.category is
                            when BOMB_BLOCK_0 =>
                                if (millisecond - in_read_block.last_update) > 700 then
                                    out_block <= (
                                        in_read_block.category,
                                        (in_read_block.state + 1) mod 2,
                                        in_read_block.direction,
                                        millisecond,
                                        in_read_block.owner,
                                        in_read_block.power);
                                    out_write <= '1';
                                end if;
                            when others =>
                                out_write <= '0';
                        end case;
                        current_state <= STATE_GAME_GRID_UPDATE_ANIMATION_WAIT;
                    when STATE_GAME_GRID_UPDATE_ANIMATION_WAIT =>
                        out_write <= '0';
                        current_state <= STATE_GAME_GRID_UPDATE_ROTATE;

                    when STATE_GAME_GRID_UPDATE_PLAYERS_ATTRIBUTES =>
                        if players_collision(current_player) = '1' and players_status(current_player).is_alive = '1' then
                            case in_read_block.category is
                                when EXPLOSION_BLOCK_JUNCTION | EXPLOSION_BLOCK_MIDDLE | EXPLOSION_BLOCK_END =>
                                    if players_lives(current_player) <= 1 and players_god_mode(current_player) = '0' then
                                        players_status(current_player).is_alive <= '0';
                                        players_lives(current_player) <= 0;
                                    else
                                        players_lives(current_player) <= players_lives(current_player) - 1;
                                    end if;
                                when BONUS_SPEED_BLOCK => -- Speed Bonus
                                    if players_speed(current_player) < 10 then
                                        players_speed(current_player) <= players_speed(current_player) + 1;
                                    end if;
                                when BONUS_ADD_POWER_BLOCK => -- Power Bonus
                                    if players_power(current_player) < 15 then
                                        players_power(current_player) <= players_power(current_player) + 1;
                                    end if;
                                when BONUS_ADD_BOMB_BLOCK => -- Add bomb Bonus
                                    if players_max_bombs(current_player) < 31 then
                                        players_max_bombs(current_player) <= players_max_bombs(current_player) + 1;
                                    end if;
                                when BONUS_GODMODE_BLOCK => -- God mode
                                    players_god_mode(current_player) <= '1';
                                    players_god_mode_activation(current_player) <= millisecond;
                                when BONUS_WALLHACK_BLOCK => -- Wall hack
                                    players_wall_hack(current_player) <= '1';
                                    players_wall_hack_activation(current_player) <= millisecond;
                                when BONUS_LIFE_BLOCK => -- Add live
                                    if players_lives(current_player) < 3 then
                                        players_lives(current_player) <= players_lives(current_player) + 1;
                                    end if;
                                -- Malus
                                when MALUS_DISABLE_BOMBS_BLOCK => -- Disable bomb planting
                                    players_can_plant_bomb(current_player) <= '0';
                                    players_no_bombs_activation(current_player) <= millisecond;
                                when MALUS_INVERSED_COMMANDS_BLOCK => -- Activate inversed command
                                    players_inversed_commands(current_player) <= '1';
                                    players_inversed_commands_activation(current_player) <= millisecond;
                                when MALUS_REMOVE_POWER_BLOCK => -- Power Bonus
                                    if players_power(current_player) > 0 then
                                        players_power(current_player) <= players_power(current_player) - 1;
                                    end if;
                                when others => null;
                            end case;
                        end if;
                        
                    when STATE_GAME_GRID_CHECK_BOMBS_PROPAGATION => null;
                    when STATE_GAME_GRID_CHECK_BOMBS_RESULT => null;
                    
                    when STATE_CHECK_DEATH_MODE =>
                        if millisecond > NORMAL_MODE_DURATION then
                            death_mode_activated <= '1';
                        else
                            death_mode_activated <= '0';
                        end if;
                        current_state <= STATE_GAME;
                    ----------------------------------------------------------------

                    when STATE_GAME_OVER =>
                        time_remaining <= NORMAL_MODE_DURATION + DEATH_MODE_DURATION - millisecond;

                        if millisecond > NORMAL_MODE_DURATION + DEATH_MODE_DURATION then
                            current_state <= STATE_START;
                        end if;
                    when others => null;
                end case;
            end if;
        end if;
    end process;
end architecture;
