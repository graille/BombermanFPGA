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

        out_i : out integer range 0 to ROWS - 1;
        out_j : out integer range 0 to COLS - 1;
        out_block : out block_type;
        out_write : out std_logic

        --grid : out td_array_cube_types(ROWS - 1 downto 0, COLS - 1 downto 0)
    );
end game_controller;

architecture behavioural of game_controller is
    constant EMPTY_BLOCK : block_type := (0,0,0);


    signal GAME_STATE : integer range 0 to 2**3 - 1 := STATE_MENU_LOADING;

    -- Physic engine signals
    signal i : integer range 0 to ROWS - 1 := 0;
    signal j : integer range 0 to COLS - 1 := 0;
    signal phy_position: vector := (others => 0);

begin

--grid <= cubes_grid;
phy_position <= (to_integer(to_unsigned(i, 16) sll 12), to_integer(to_unsigned(j, 16) sll 12));



PHY_ENGINES_GENERATOR : for k in 0 to NB_PLAYERSS - 1 generate
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
                when STATE_GAME | STATE_DEATH_MODE =>
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
                when => STATE_GAME_OVER then
                    game_end <= '1';
                    game_winner <= 0; -- TODO
            end case;
        end if;
    end if;
end process;

end architecture;
