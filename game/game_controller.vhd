library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.PROJECT_PARAMS_PKG.all;
use work.PROJECT_TYPES_PKG.all;
use work.PROJECT_DIRECTION_PKG.all;
use work.PROJECT_PLAYER_ACTIONS_PKG.all;
use work.PROJECT_GAME_STATES_PKG.all;
use work.PROJECT_BLOCKS_PKG.all;

entity game_controller is
    generic(
        SEED_LENGTH : integer := 16;
        FREQUENCY : integer := 100000000
    );
    port(
        clk, rst : in std_logic;
        seed : in std_logic_vector(SEED_LENGTH - 1 downto 0);
        in_io : in io_signal;

        in_read_block : in block_type;

        game_end : out std_logic := '0';
        game_winner : out integer range 0 to NB_PLAYERS - 1;

        out_grid_position : out grid_position;
        out_block : out block_type;
        out_write : out std_logic

        --grid : out td_array_cube_types(ROWS - 1 downto 0, COLS - 1 downto 0)
    );
end game_controller;

architecture behavioural of game_controller is
    signal GAME_STATE : game_state_type;

    signal millisecond : millisecond_count := 0;

    -- Players attributes
    type players_grid_position_type is array(NB_PLAYERS - 1 downto 0) of grid_position;
    signal players_grid_position : players_grid_position_type := (others => (others => 0));

    type players_block_to_process_type is array(NB_PLAYERS - 1 downto 0) of block_type;
    signal players_block_to_process : players_block_to_process_type;

    type players_positions_type is array(NB_PLAYERS - 1 downto 0) of vector;
    type players_power_type is array(NB_PLAYERS - 1 downto 0) of integer range 0 to MAX_PLAYER_POWER - 1;
    type players_hitbox_type is array(NB_PLAYERS - 1 downto 0) of vector;
    type players_action_type is array(NB_PLAYERS - 1 downto 0) of player_action;
    type players_status_type is array(NB_PLAYERS - 1 downto 0) of player_status_type;

    signal players_position : players_positions_type := (others => (others => 0));
    signal players_alive : std_logic_vector(NB_PLAYERS - 1 downto 0) := (others => '0');
    signal players_power : players_power_type := (others => 0);
    signal players_hitbox : players_hitbox_type := (others => (others => 0));

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

    -- FSM signals
    signal s_start_finished : std_logic;
    signal s_grid_initialized : std_logic;
    signal s_death_mode_ended : std_logic;

    signal s_bomb_check_ended : std_logic;

    signal s_bomb_will_explode : std_logic;
    signal s_bomb_has_exploded : std_logic;

    signal s_players_dog_updated : std_logic;

    -- Components
    component game_fsm is
        port(
            rst : in std_logic;
            in_io : in io_signal;

            s_start_finished : in std_logic;
            s_grid_initialized : in std_logic;
            s_death_mode_ended : in std_logic;

            s_bomb_check_ended : in std_logic;

            s_bomb_will_explode : in std_logic;
            s_bomb_has_exploded : in std_logic;

            s_players_dog_updated : in std_logic;

            in_clk_count : in clk_count;
            in_millisecond : in millisecond_count;

            out_game_state : out game_state_type
        );
    end component;

    component fifo_player_action is
    	Generic (
    		constant FIFO_DEPTH	: positive := 256
    	);
    	Port (
    		CLK		: in  STD_LOGIC;
    		RST		: in  STD_LOGIC;
    		WriteEn	: in  STD_LOGIC;
    		DataIn	: in  player_action;
    		ReadEn	: in  STD_LOGIC;
    		DataOut	: out player_action;
    		Empty	: out STD_LOGIC;
    		Full	: out STD_LOGIC
    	);
    end component;

    component player is
        generic(
            CONTROL_SET : integer := 0
        );
        port(
            clk, rst : in std_logic;
            in_millisecond : in millisecond_count;
            in_io : in io_signal;
            in_dol : in dol_type;
            in_next_block : in block_type;

            out_position : out vector;
            out_is_alive : out std_logic := '1';
            out_power : out integer range 0 to MAX_PLAYER_POWER - 1;
            out_hitbox : out vector;

            out_action : out player_action := EMPTY_PLAYER_ACTION;
            out_new_action : out std_logic := '0';

            out_player_status : out player_status_type := DEFAULT_PLAYER_STATUS
        );
    end component;

    component collision_detector_rect_rect is
        port(
            o_pos, t_pos : in vector;
            o_dim, t_dim : in vector;
            is_colliding : out std_logic := '0'
        );
    end component;

    component millisecond_counter is
        generic(
            FREQUENCY : integer := 100000000
        );
        port(
            CLK, RST : in std_logic;
            timer : out millisecond_count
        );
    end component;
begin

    --grid <= cubes_grid;
    phy_position <= (to_integer(to_unsigned(phy_position_grid.i, 16) sll 12), to_integer(to_unsigned(phy_position_grid.j, 16) sll 12));

    PLAYERS_ATTRIBUTES_GENERATOR : for k in 0 to NB_PLAYERS - 1 generate
        -- Instantiate players
        CURRENT_PLAYER:player
            generic map (
                CONTROL_SET => k
            )
            port map(
                clk => CLK,
                rst => rst,
                in_millisecond => millisecond,
                in_io => in_io,
                in_dol => x"f",
                in_next_block => players_block_to_process(k),

                out_position => players_position(k),
                out_is_alive => players_alive(k),
                out_power => players_power(k),
                out_hitbox => players_hitbox(k),

                out_action => players_next_action(k),
                out_new_action => players_new_action(k),

                out_player_status => players_status(k)
            );

        -- Instantiate collisions detectors
        PHY_ENGINE:collision_detector_rect_rect
            port map(
                o_pos => players_position(k),
                o_dim => players_hitbox(k),
                t_pos => phy_position,
                t_dim => DEFAULT_BLOCK_SIZE,
                is_colliding => players_collision(k)
            );

        -- Manage the FIFO which deals with players actions
        players_fifo_write_en(k) <= players_new_action(k);
        players_fifo_data_in(k) <= players_next_action(k);

        PLAYER_FIFO:fifo_player_action
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
    end generate;

    -- Millisecond counter
    COUNTER_ENGINE:millisecond_counter
    generic map (
        FREQUENCY => FREQUENCY
    )
    port map(
        CLK => CLK,
        RST => RST,
        timer => millisecond
    );

    process(CLK)
        -- STATE_GAME_PLAYERS_BOMB_CHECK
        type STATE_GAME_PLAYERS_BOMB_CHECK_STATE is (
            PROCESS_START_STATE,
            PROCESS_START_PLAYER_CHECK,
            PROCESS_LOADING_PLAYER_NEXT_ACTION,
            PROCESS_NEXT_ACTION_LOADED,
            PROCESS_ACTION_PROCESSED,
            PROCESS_END_STATE
        );
        
        variable STATE_GAME_PLAYERS_BOMB_CHECK_CURRENT_PLAYER : integer range 0 to NB_PLAYERS - 1 := 0;
        variable STATE_GAME_PLAYERS_BOMB_CHECK_CURRENT_STATE : STATE_GAME_PLAYERS_BOMB_CHECK_STATE := PROCESS_START_STATE;
        
        -- STATE_GAME_GRID_UPDATE
        type STATE_GAME_GRID_UPDATE_STATE is (
            PROCESS_START_STATE,
            PROCESS_WAITING_FIRST_RESULT,
            PROCESS_CHECK
        );
        
        variable STATE_GAME_GRID_UPDATE_CURRENT_POSITION : grid_position := (0,0);
        variable STATE_GAME_GRID_UPDATE_CURRENT_STATE : STATE_GAME_GRID_UPDATE_STATE := PROCESS_START_STATE;
    begin
        if rising_edge(CLK) then
            case GAME_STATE is
                when STATE_GAME_PLAYERS_BOMB_CHECK =>
                    case STATE_GAME_PLAYERS_BOMB_CHECK_CURRENT_STATE is
                        when PROCESS_START_STATE =>
                            STATE_GAME_PLAYERS_BOMB_CHECK_CURRENT_PLAYER := 0;
                            s_bomb_check_ended <= '0';
                            STATE_GAME_PLAYERS_BOMB_CHECK_CURRENT_STATE := PROCESS_START_PLAYER_CHECK;
                        when PROCESS_START_PLAYER_CHECK =>
                            if players_fifo_empty(STATE_GAME_PLAYERS_BOMB_CHECK_CURRENT_PLAYER) = '0' then
                                players_fifo_read_en(STATE_GAME_PLAYERS_BOMB_CHECK_CURRENT_PLAYER) <= '1';
                                STATE_GAME_PLAYERS_BOMB_CHECK_CURRENT_STATE := PROCESS_NEXT_ACTION_LOADED;
                            else
                                STATE_GAME_PLAYERS_BOMB_CHECK_CURRENT_PLAYER := (STATE_GAME_PLAYERS_BOMB_CHECK_CURRENT_PLAYER + 1) mod NB_PLAYERS;
                            end if;
                        when PROCESS_LOADING_PLAYER_NEXT_ACTION =>
                            players_fifo_read_en(STATE_GAME_PLAYERS_BOMB_CHECK_CURRENT_PLAYER) <= '0';
                            STATE_GAME_PLAYERS_BOMB_CHECK_CURRENT_STATE := PROCESS_NEXT_ACTION_LOADED;
                        when PROCESS_NEXT_ACTION_LOADED =>
                            -- Check the data
                            case players_fifo_data_out(STATE_GAME_PLAYERS_BOMB_CHECK_CURRENT_PLAYER).category is
                                when PLANT_NORMAL_BOMB =>
                                    out_grid_position <= players_grid_position(STATE_GAME_PLAYERS_BOMB_CHECK_CURRENT_PLAYER);
                                    out_block <= (BOMB_BLOCK_0, 0, 0, players_fifo_data_out(STATE_GAME_PLAYERS_BOMB_CHECK_CURRENT_PLAYER).created, STATE_GAME_PLAYERS_BOMB_CHECK_CURRENT_PLAYER);
                                    out_write <= '1';
                                when others => null;
                            end case;
    
                            STATE_GAME_PLAYERS_BOMB_CHECK_CURRENT_STATE := PROCESS_ACTION_PROCESSED;
                        when PROCESS_ACTION_PROCESSED =>
                            out_write <= '0';
                            if STATE_GAME_PLAYERS_BOMB_CHECK_CURRENT_PLAYER = NB_PLAYERS - 1 then
                                STATE_GAME_PLAYERS_BOMB_CHECK_CURRENT_STATE := PROCESS_END_STATE;
                            else
                                STATE_GAME_PLAYERS_BOMB_CHECK_CURRENT_PLAYER := (STATE_GAME_PLAYERS_BOMB_CHECK_CURRENT_PLAYER + 1) mod NB_PLAYERS;
                                STATE_GAME_PLAYERS_BOMB_CHECK_CURRENT_STATE := PROCESS_START_PLAYER_CHECK;
                            end if;
                        when PROCESS_END_STATE =>
                            s_bomb_check_ended <= '1';
                            STATE_GAME_PLAYERS_BOMB_CHECK_CURRENT_STATE := PROCESS_START_STATE;
                        when others => null;
                    end case;
                when STATE_GAME_GRID_UPDATE =>
                    case STATE_GAME_GRID_UPDATE_CURRENT_STATE is
                        when PROCESS_START_STATE =>
                            STATE_GAME_GRID_UPDATE_CURRENT_POSITION := (0, 0);
                            STATE_GAME_GRID_UPDATE_CURRENT_STATE := PROCESS_WAITING_FIRST_RESULT;
                        when PROCESS_WAITING_FIRST_RESULT =>
                            STATE_GAME_GRID_UPDATE_CURRENT_POSITION := INCR_POSITION_LINEAR(STATE_GAME_GRID_UPDATE_CURRENT_POSITION);
                            STATE_GAME_GRID_UPDATE_CURRENT_STATE := PROCESS_CHECK;
                        when PROCESS_CHECK =>
                            case in_read_block.category is 
                                when others => null;
                            end case;
    
                            STATE_GAME_GRID_UPDATE_CURRENT_POSITION := INCR_POSITION_LINEAR(STATE_GAME_GRID_UPDATE_CURRENT_POSITION);
                        when others => null;
                    end case;

                    out_grid_position <= STATE_GAME_GRID_UPDATE_CURRENT_POSITION;
                when others => null;
            end case;
        end if;
    end process;
end architecture;
