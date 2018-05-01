library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.PROJECT_TYPES_PKG.all;

entity game_controller is
    generic(
        ROWS : integer := 12;
        COLS : integer := 16;
        FREQUENCY : integer := 10**8;
        NB_PLAYERS : integer := 4
    );
    port(
        clk, rst : in std_logic;
    
        game_end : out std_logic := '0';
        game_winner : out integer range 0 to NB_PLAYERS - 1;
        
        
        i_out_ram : out integer range 0 to ROWS - 1;
        j_out_ram : out integer range 0 to COLS - 1;
        data_out_ram : out block_type
        
        --grid : out td_array_cube_types(ROWS - 1 downto 0, COLS - 1 downto 0)
    );
end game_controller;

architecture behavioural of game_controller is
    -- Cubes types
    -- 0 = empty block
    -- 1..3 = unbreakable block type 0,1,2
    -- 4..6 = breakeable block type 0,1,2

    -- 7..9 = Bombs type 0,1,2
    -- 10-14 : Explosion
    -- from 15 to 31 : Bonus of malus blocks
    constant EMPTY_BLOCK : block_type := (0,0,0);
    constant UNBREAKABLE_BLOCK_0 : block_type := (1,0,0);
    constant UNBREAKABLE_BLOCK_1 : block_type := (2,0,0);
    signal cubes_grid : td_array_cube_types(ROWS - 1 downto 0, COLS - 1 downto 0);

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
    type players_bonus_type is array(NB_PLAYERS - 1 downto 0) of player_status_type;
    signal player_status_array : players_bonus_type := (others => (others => (others => 0)));

    constant player_hitbox : vector := (3276, 3276);

    -- Physic engine signals
    signal i, i_copy : integer range 0 to ROWS - 1 := 0;
    signal j, j_copy : integer range 0 to COLS - 1 := 0;
    signal phy_position: vector := (others => 0);

    -- Players states
    signal players_collision : players_status_type := (others => '1');

    -- Components
    component collision_detector_rect_rect
    port(
        o_pos, t_pos : in vector;
        o_dim, t_dim : in vector;
        is_colliding : out std_logic
    );
    end component;
    
    component millisecond_counter is
        generic(
            DATA_LENGTH : integer := 21; -- 21 bits = 34 minutes
            FREQUENCY : integer := 100000000
        );
        port(
            CLK, RST : in std_logic;
            timer : out integer range 0 to 2**DATA_LENGTH - 1
        );
    end component;
    
    signal millisecond : positive range 0 to 2**21 - 1;
begin

--grid <= cubes_grid;
phy_position <= (to_integer(to_unsigned(i, 16) sll 12), to_integer(to_unsigned(j, 16) sll 12));

PHY_ENGINES_GENERATOR : for k in 0 to NB_PLAYERS - 1 generate
    PHY_ENGINE:collision_detector_rect_rect
    port map(
        o_pos => players_positions(k),
        o_dim => player_hitbox,
        t_pos => phy_position,
        t_dim => (4096, 4096),
        is_colliding => players_collision(k)
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
    constant millisec_per_move : positive := 1000;
begin
    if rising_edge(CLK) then
        if rst = '1' then
            i <= 0; j <= 0;
            GAME_STATE <= STATE_MAP_INIT;
            game_end <= '0';
            game_winner <= 0;
        else
            if GAME_STATE = STATE_MENU_LOADING then
                GAME_STATE <= STATE_MAP_INIT;
            elsif GAME_STATE = STATE_MAP_INIT then
                -- Generate borders
                if (j = 0 or j = COLS - 1) or (i = 0 or i = ROWS - 1) then
                    cubes_grid(i, j) <= UNBREAKABLE_BLOCK_0;
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
            elsif GAME_STATE = STATE_GAME then
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
            elsif GAME_STATE = STATE_DEATH_MODE then
                if (millisecond mod millisec_per_move) = 0 then
                    cubes_grid(i, j) <= UNBREAKABLE_BLOCK_0;

                    if i = ROWS - 1 and j = COLS - 1 then
                        GAME_STATE <= STATE_GAME_OVER;
                    else
                        if j = COLS - 1 then
                            j <= 0;
                            i <= i + 1;
                        else
                            j <= j + 1;
                        end if;
                    end if;
                else
                    
                end if;
            elsif GAME_STATE = STATE_GAME_OVER then
                game_end <= '1';
                game_winner <= 0; -- TODO
            end if;
        end if;
    end if;
end process;


-- Copy register into RAM
process(CLK)
begin
    if rising_edge(CLK) then
        if i_copy = ROWS - 1 and j_copy = COLS - 1 then
            j_copy <= 0; i_copy <= 0;
        else
            if j_copy = COLS - 1 then
                j_copy <= 0;
                i_copy <= i_copy + 1;
            else
                j_copy <= j_copy + 1;
            end if;
        end if;
    end if;
end process;

i_out_ram <= i_copy;
j_out_ram <= j_copy;
data_out_ram <= cubes_grid(i_copy, j_copy);

end architecture;
