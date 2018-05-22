library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.PROJECT_PARAMS_PKG.all;
use work.PROJECT_TYPES_PKG.all;
use work.PROJECT_DIRECTION_PKG.all;
use work.PROJECT_GAME_STATES_PKG.all;
use work.PROJECT_BLOCKS_PKG.all;

entity game_controller is
    generic(
        SEED_LENGTH : integer := 16;
        FREQUENCY : integer := 100000000
    );
    port(
        clk, rst : in std_logic;
        in_seed : in std_logic_vector(SEED_LENGTH - 1 downto 0);
        in_io : in io_signal;

        in_read_block : in block_type;

        game_end : out std_logic := '0';
        game_winner : out integer range 0 to NB_PLAYERS - 1;

        out_grid_position : out grid_position;
        out_block : out block_type;
        out_write : out std_logic;

        out_players_position: out players_positions_type;
        out_players_status: out players_status_type;
        out_players_alive: out std_logic_vector(NB_PLAYERS - 1 downto 0);

        out_time_remaining : out millisecond_count := 0
    );
end game_controller;

architecture behavioral of game_controller is
    -- Millisecond counter
    signal millisecond : millisecond_count := 0;
    signal millisecond_counter_reset : std_logic := '0';

    signal rst_millisecond_counter : std_logic := '0';

    -- Players attributes
    type players_block_to_process_type is array(NB_PLAYERS - 1 downto 0) of block_type;
    signal players_block_to_process : players_block_to_process_type;
    signal players_process_blocks : std_logic_vector(NB_PLAYERS - 1 downto 0) := (others => '0');

    signal players_position : players_positions_type := (others => (others => 0));
    signal players_grid_position : players_grid_position_type := (others => (others => 0));
    signal players_alive : std_logic_vector(NB_PLAYERS - 1 downto 0) := (others => '0');
    signal players_power : players_power_type := (others => 0);

    signal players_next_action : players_action_type := (others => EMPTY_PLAYER_ACTION);
    signal players_new_action : std_logic_vector(NB_PLAYERS - 1 downto 0) := (others => '0');

    signal players_status : players_status_type := (others => DEFAULT_PLAYER_STATUS);

    -- Physics engines
    signal players_collision : std_logic_vector(NB_PLAYERS - 1 downto 0) := (others => '0');
    signal phy_position_grid : grid_position;
    signal phy_position : vector;

    -- Player action FIFO
    type players_fifo_data_type is array(NB_PLAYERS - 1 downto 0) of player_action;

    signal players_fifo_write_en, players_fifo_read_en : std_logic_vector(NB_PLAYERS - 1 downto 0) := (others => '0');
    signal players_fifo_data_in : players_fifo_data_type := (others => EMPTY_PLAYER_ACTION);
    signal players_fifo_data_out : players_fifo_data_type := (others => EMPTY_PLAYER_ACTION);
    signal players_fifo_empty : std_logic_vector(NB_PLAYERS - 1 downto 0) := (others => '0');
    signal players_fifo_full : std_logic_vector(NB_PLAYERS - 1 downto 0) := (others => '0');

    -- PRNG value
    signal prng_value: std_logic_vector(PRNG_PRECISION - 1 downto 0);
    signal prng_percent : integer range 0 to 100;

    signal rst_prng : std_logic := '0';

    -- Choices
    type game_state_type is (
        STATE_START,
        STATE_MENU_LOADING,

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
        STATE_GAME,
            STATE_GAME_UPDATE_TIME_REMAINING,

            STATE_GAME_PLAYERS_BOMB_CHECK,
            STATE_GAME_PLAYERS_BOMB_CHECK_ROTATE,

            STATE_GAME_GRID_UPDATE,
            STATE_GAME_GRID_UPDATE_ROTATE,
                STATE_GAME_GRID_UPDATE_PLAYERS,
                -- When we check a cells, we have to check adjacent cells
                STATE_GAME_GRID_UPDATE_CHECK_CENTER,
                STATE_GAME_GRID_UPDATE_CHECK_TOP,
                STATE_GAME_GRID_UPDATE_CHECK_LEFT,
                STATE_GAME_GRID_UPDATE_CHECK_BOTTOM,
                STATE_GAME_GRID_UPDATE_CHECK_RIGHT,

            STATE_CHECK_PLAYERS_DOG,
                STATE_GAME_PLAYERS_DOG_CHECK_TOP,
                STATE_GAME_PLAYERS_DOG_CHECK_LEFT,
                STATE_GAME_PLAYERS_DOG_CHECK_BOTTOM,
                STATE_GAME_PLAYERS_DOG_CHECK_RIGHT,
        STATE_DEATH_MODE,
            STATE_DEATH_MODE_PLACE_BLOCK,
            STATE_DEATH_MODE_CHECK_DEATH,
        STATE_GAME_OVER
    );

    signal next_state, current_state : game_state_type := STATE_START;

    signal next_grid_position, current_grid_position : grid_position := DEFAULT_GRID_POSITION;
begin
    out_players_position <= players_position;
    out_players_status <= players_status;
    out_players_alive <= players_alive;

    out_grid_position <= next_grid_position;

    PRNG_GENERATOR:entity work.simple_prng_lfsr
        generic map (
            DATA_LENGTH => PRNG_PRECISION,
            SEED_LENGTH => SEED_LENGTH
        )
        port map (
            clk => clk,
            rst => RST or rst_prng,

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
            RST => RST or millisecond_counter_reset,
            timer => millisecond
        );

    phy_position <= (to_integer(to_unsigned(phy_position_grid.i, 16) sll 12), to_integer(to_unsigned(phy_position_grid.j, 16) sll 12));

    PLAYERS_ATTRIBUTES_GENERATOR : for k in 0 to NB_PLAYERS - 1 generate
        -- Instantiate players
        I_PLAYER:entity work.player
            generic map (
                CONTROL_SET => k
            )
            port map(
                clk => CLK,
                rst => rst,

                in_millisecond => millisecond,
                in_io => in_io,
                in_dol => "1111",

                in_next_block => players_block_to_process(k),
                in_next_block_process => players_process_blocks(k),

                out_position => players_position(k),
                out_is_alive => players_alive(k),
                out_power => players_power(k),

                out_action => players_next_action(k),
                out_new_action => players_new_action(k),

                out_player_status => players_status(k)
            );

        -- Instantiate collisions detectors
        I_PLAYER_PHYSIC_ENGINE:entity work.collision_detector_rect_rect
            port map(
                o_pos => players_position(k),
                o_dim => DEFAULT_PLAYER_HITBOX,
                t_pos => phy_position,
                t_dim => DEFAULT_BLOCK_SIZE,
                is_colliding => players_collision(k)
            );

        -- Manage the FIFO player
        players_fifo_write_en(k) <= players_new_action(k);
        players_fifo_data_in(k) <= players_next_action(k);

        I_PLAYER_FIFO:entity work.fifo_player_action
            generic map (
                FIFO_DEPTH => 64
            )
            port map(
                CLK => CLK,
                RST => RST,
                WriteEn => players_fifo_write_en(k),
                DataIn => players_fifo_data_in(k),
                ReadEn => players_fifo_read_en(k),
                DataOut => players_fifo_data_out(k),
                Empty => players_fifo_empty(k),
                Full => players_fifo_full(k)
            );

        I_PLAYER_POSITION_CONVERTER:entity work.player_to_grid
            port map(
                in_player_position => players_position(K),
                out_position => players_grid_position(K)
            );
    end generate;

    process(CLK)
    begin
        if rising_edge(CLK) then
            current_state <= next_state;
            current_grid_position <= next_grid_position;
        end if;
    end process;

    -- Reset controller
    process(GAME_STATE)
    begin
        if GAME_STATE = START_STATE then
            rst_prng <= '1';
            rst_millisecond_counter <= '1';
        else
            rst_prng <= '0';
            rst_millisecond_counter <= '0';
        end if;
    end process;

    process(current_state)
    begin
        if RST = '1' then
            next_grid_position <= DEFAULT_GRID_POSITION;
            next_state <= START_STATE;
        else
            case current_state is
                when START_STATE =>
                    next_grid_position <= DEFAULT_GRID_POSITION;
                when
            end case;
        end if;
    end process;
end architecture;
