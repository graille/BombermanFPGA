library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.PROJECT_PARAMS.all;
use work.PROJECT_TYPES_PKG.all;

entity game_controller is
    generic(
        SEED_LENGTH : integer := 16
    );
    port(
        clk, rst : in std_logic;
        seed : in std_logic_vector(SEED_LENGTH - 1 downto 0);

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

    -- Players positions
    type players_grid_position_type is array(NB_PLAYERS - 1 downto 0) of grid_position;
    signal players_grid_position : players_grid_position_type := (others => (others => 0));

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

            in_clk_count : clk_count;
            in_millisecond : millisecond_count;

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
            CONTROL_FORWARD : io_signal;
            CONTROL_BACK : io_signal;
            CONTROL_LEFT : io_signal;
            CONTROL_RIGHT : io_signal;

            CONTROL_BOMB : io_signal
        );
        port(
            clk, rst : in std_logic;
            in_millisecond : in positive range 0 to 2**21 - 1;
            in_io : in io_signal;
            in_dol : in dol_type;
            in_next_block : in block_category_type;

            out_position : out vector;
            out_is_alive : out std_logic := '1';
            out_power : out integer range 0 to 15 - 1;
            out_plant_bomb : out std_logic := '0';
            out_hitbox : out vector;

            out_player_status : out player_status_type
        );
    end component;
begin

    --grid <= cubes_grid;
    phy_position <= (to_integer(to_unsigned(i, 16) sll 12), to_integer(to_unsigned(j, 16) sll 12));

    PLAYERS_ATTRIBUTES_GENERATOR : for k in 0 to NB_PLAYERSS - 1 generate
        PLAYER:player
        generic map (

        )
        port map(

        );

        process()
        begin

        end process;

        PHY_ENGINE:collision_detector_rect_rect
        port map(
            o_pos => players_positions(k),
            o_dim => player_hitbox,
            t_pos => phy_position,
            t_dim => DEFAULT_BLOCK_SIZE,
            is_colliding => players_collision(k)
        );

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

    PLAYERS_ACTION:STD_FIFO
    generic map (
        DATA_WIDTH => 8;
        FIFO_DEPTH => 256
    )
    port map(
        CLK => CLK,
        RST => RST,
        WriteEn => ,
        DataIn => ,
        ReadEn => ,
        DataOut =>
        Empty =>
        Full =>
    );

    process(CLK)
        constant millisec_per_move : positive := 1000;
    begin
        if rising_edge(CLK) then
            if rst = '1' then
                i <= 0; j <= 0;
                GAME_STATE <= STATE_MAP_INIT;
                game_end <= '0';
                game_winner <= 0;
            else
                case GAME_STATE is
                    when STATE_START =>
                        GAME_STATE <= STATE_MENU_LOADING;
                    when STATE_MENU_LOADING =>
                        GAME_STATE <= STATE_MAP_INIT;
                    when STATE_MAP_INIT =>
                        -- Generate borders
                        if (j = 0 or j = COLS - 1) or (i = 0 or i = ROWS - 1) then
                            block_out_ram <= UNBREAKABLE_BLOCK_0;
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
                            else
                                j <= j + 1;
                            end if;
                        end if;

                    when => STATE_GAME_OVER then
                        game_end <= '1';
                        game_winner <= 0; -- TODO
                end case;
            end if;
        end if;
    end process;

    process(CLK)
        variable i : integer range 0 to ROWS - 1 := 0;
        variable j : integer range 0 to COLS - 1 := 0;
    begin
        if rising_edge(CLK)
            if GAME_STATE = STATE_GAME | STATE_DEATH_MODE =>
                case cubes_grid(i,j).category is
                    when others => null;
                    -- TODO
                end case;

                if i = ROWS - 1 and j = COLS - 1 then
                    i <= 0; j <= 0;
                else
                    if j = COLS - 1 then
                        j <= 0;
                        i <= i + 1;
                    else
                        j <= j + 1;
                    end if;
                end if;
            end if;
        end if;

    end process;

    process(CLK)
        variable current_player : integer range 0 to NB_PLAYERS - 1 := 0;

        constant PROCESS_START_STATE : integer := 0;
        constant PROCESS_START_PLAYER_CHECK : integer := 1;
        constant PROCESS_LOADING_PLAYER_NEXT_ACTION : integer := 2;
        constant PROCESS_NEXT_ACTION_LOADED : integer := 3;
        constant PROCESS_END_STATE : integer := 4;

        subtype process_state_type is (
            PROCESS_START_STATE,
            PROCESS_START_PLAYER_CHECK,
            PROCESS_LOADING_PLAYER_NEXT_ACTION,
            PROCESS_NEXT_ACTION_LOADED,
            PROCESS_ACTION_PROCESSED,
            PROCESS_END_STATE
        );

        variable current_state : process_state_type;
    begin
        if rising_edge(CLK)
            if GAME_STATE = STATE_GAME_PLAYERS_BOMB_CHECK then
                case current_state is
                    when PROCESS_START_STATE =>
                        current_player := 0;
                        s_bomb_check_ended <= '0';
                        current_state := PROCESS_START_PLAYER_CHECK;
                    when PROCESS_START_PLAYER_CHECK =>
                        if players_fifo_empty(current_player) = '0' then
                            players_fifo_read_en(current_player) <= '1';
                            current_state := PROCESS_NEXT_ACTION_LOADED
                        else
                            current_player := (current_player + 1) mod NB_PLAYERS;
                        end if;
                    when PROCESS_LOADING_PLAYER_NEXT_ACTION =>
                        players_fifo_read_en(current_player) <= '0';
                        current_state := PROCESS_NEXT_ACTION_LOADED;
                    when PROCESS_NEXT_ACTION_LOADED =>
                        -- Check the data
                        case players_fifo_data_out(current_player) is
                            when PLANT_NORMAL_BOMB =>
                                out_grid_position <= players_grid_position(current_player);
                                out_block <= (BOMB_BLOCK_0, 0, 0, millisecond, current_player);
                                out_write <= '1';
                        end case;

                        current_state := PROCESS_ACTION_PROCESSED;
                    when PROCESS_ACTION_PROCESSED =>
                        out_write <= '0';
                        if current_player = NB_PLAYERS - 1 then
                            current_state := PROCESS_END_STATE;
                        else
                            current_player := (current_player + 1) mod NB_PLAYERS;
                            current_state := PROCESS_START_PLAYER_CHECK;
                        end if;
                    when PROCESS_END_STATE =>
                        s_bomb_check_ended <= '1';
                        current_state := PROCESS_START_STATE;
                end case;
            end if;
        end if;
    end process;

    -- STATE_GAME_CHECK_PLAYERS_DOG
    process(CLK)
        variable current_position : grid_position := (0,0);
    begin
        if rising_edge(CLK)
            if GAME_STATE = STATE_GAME_GRID_UPDATE then
                
            end if;
        end if;
    end process;

    process(CLK)
    begin
        if rising_edge(CLK)
        end if;
    end process;

    process(CLK)
    begin
        if rising_edge(CLK)
        end if;
    end process;

end architecture;
