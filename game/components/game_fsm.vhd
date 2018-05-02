library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.PROJECT_PARAMS_PKG.all;
use work.PROJECT_TYPES_PKG.all;
use work.PROJECT_GAME_STATES_PKG.all;

entity game_fsm is
    port(
        clk, rst : in std_logic;
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
end game_fsm;

architecture behavioural of game_fsm is
    constant CONTINUE_COMMAND : io_signal := x"0f";

    signal GAME_STATE, NEXT_GAME_STATE : game_state_type := STATE_START;
begin
    -- Flip flop used to store the current state
    process(clk, rst)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                GAME_STATE <= STATE_START;
            else
                GAME_STATE <= NEXT_GAME_STATE;
            end if;
        end if;
    end process;
    out_game_state <= GAME_STATE;

    -- State machin
    process(rst, in_io,
        s_start_finished, s_grid_initialized, s_death_mode_ended,
        s_bomb_check_ended, s_bomb_will_explode,
        s_players_dog_updated, in_clk_count, in_millisecond)
    begin
        if rst = '1' then
            GAME_STATE <= STATE_START;
        else
            case GAME_STATE is
                when STATE_START =>
                    if s_start_finished = '1' then
                        NEXT_GAME_STATE <= STATE_MENU_LOADING;
                    end if;
                when STATE_MENU_LOADING =>
                    if in_io = CONTINUE_COMMAND then
                        NEXT_GAME_STATE <= STATE_MAP_INIT;
                    end if;
                when STATE_MAP_INIT =>
                    if s_grid_initialized = '1' then
                        NEXT_GAME_STATE <= STATE_GAME;
                    end if;
                when STATE_GAME | STATE_DEATH_MODE =>
                    if (GAME_STATE = STATE_GAME) and (in_millisecond - NORMAL_MODE_DURATION > 0) then
                        NEXT_GAME_STATE <= STATE_DEATH_MODE;
                    elsif (GAME_STATE = STATE_DEATH_MODE) and (s_death_mode_ended = '1') then
                        NEXT_GAME_STATE <= STATE_GAME_OVER;
                    else
                        NEXT_GAME_STATE <= STATE_GAME_PLAYERS_BOMB_CHECK;
                        -- Begin the check cycle
                            -- Players Bombs (N_PLAYERS cycles)
                            -- Grid check
                                -- > Bomb explode
                            -- Players DOL check
                            -- If game over state
                                -- > Place over
                    end if;
                -------------------
                when STATE_GAME_PLAYERS_BOMB_CHECK =>
                    if s_bomb_check_ended = '1' then
                        NEXT_GAME_STATE <= STATE_GAME_GRID_UPDATE;
                    end if;
                when STATE_GAME_GRID_UPDATE =>
                    if s_bomb_will_explode = '1' then
                        NEXT_GAME_STATE <= STATE_GAME_BOMB_EXPLODE;
                    end if;
                when STATE_GAME_BOMB_EXPLODE =>
                    if s_bomb_has_exploded = '1' then
                        NEXT_GAME_STATE <= STATE_GAME_CHECK_PLAYERS_DOG;
                    end if;
                when STATE_GAME_CHECK_PLAYERS_DOG =>
                    if s_players_dog_updated = '1' then
                        NEXT_GAME_STATE <= STATE_GAME_CHECK_PLAYERS_DOG;
                    end if;
                ------------
                when STATE_GAME_OVER =>
                    if in_io = CONTINUE_COMMAND then
                        NEXT_GAME_STATE <= STATE_START;
                    end if;
                when others => null;
            end case;
        end if;
    end process;

end architecture;
