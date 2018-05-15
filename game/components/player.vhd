library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.PROJECT_PARAMS_PKG.all;
use work.PROJECT_TYPES_PKG.all;
use work.PROJECT_PLAYER_ACTIONS_PKG.all;
use work.PROJECT_DIRECTION_PKG.all;
use work.PROJECT_BLOCKS_PKG.all;

entity player is
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
end player;

architecture player of player is
    constant PLAYER_INITIAL_POSITION : vector := (0,0);
    constant DEFAULT_SPEED : integer := 1;

    -- Players states
    signal player_alive : std_logic := '1'; -- 1 = alive, 0 = dead

    -- Players informations
    signal player_position : vector := PLAYER_INITIAL_POSITION;
    signal player_speed : integer range 0 to 2**12 - 1;
    signal player_power : integer range 0 to MAX_PLAYER_POWER := 1;

    signal player_max_bombs : integer range 0 to 31 := 1;
    signal player_nb_bombs : integer range 0 to 31 := 0;
    signal player_can_plant_bomb : std_logic := '1';

    -- Bonus
    signal player_god_mode : std_logic := '0'; --
    signal player_wall_hack : std_logic := '0';
    signal player_lives : integer range 0 to 3;

    -- Malus
    signal player_inversed_commands : std_logic := '0';

    signal player_state : state_type;
    signal player_direction : direction_type;

    -- Commands
    -- TODO
    constant CONTROL_FORWARD : io_signal := x"ff";
    constant CONTROL_BACK : io_signal := x"fe";
    constant CONTROL_LEFT : io_signal := x"fb";
    constant CONTROL_RIGHT : io_signal := x"fa";

    constant CONTROL_BOMB : io_signal := x"f1";

begin
    process(clk)
        constant player_god_mode_duration : integer := 5000;
        variable player_god_mode_activation : millisecond_count := 0;

        constant player_wall_hack_duration : integer := 10000;
        variable player_wall_hack_activation : millisecond_count := 0;

        constant player_no_bombs_duration : integer := 7000;
        variable player_no_bombs_activation : millisecond_count := 0;
    begin
        if rising_edge(clk) then
            if rst = '1' then
                player_speed <= DEFAULT_SPEED;
                player_power <= 1;

                player_max_bombs <= 1;
                player_can_plant_bomb <= '1';

                player_god_mode <= '0';
                player_wall_hack <= '0';
                player_lives <= 1;

                player_inversed_commands <= '0';
            else
                if (in_millisecond - player_god_mode_activation) mod player_god_mode_duration = 0 then
                    player_god_mode <= '0';
                end if;

                if (in_millisecond - player_wall_hack_activation) mod player_wall_hack_duration = 0 then
                    player_wall_hack <= '0';
                end if;

                if (in_millisecond - player_no_bombs_activation) mod player_no_bombs_duration = 0 then
                    player_can_plant_bomb <= '1';
                end if;

                case in_next_block.category is
                    when EXPLOSION_BLOCK_JUNCTION | EXPLOSION_BLOCK_MIDDLE | EXPLOSION_BLOCK_END =>
                        if player_lives = 1 then
                            player_alive <= '0';
                        end if;

                        player_lives <= player_lives - 1;
                    when BONUS_SPEED_BLOCK => -- Speed Bonus
                        if player_speed < 2**12 - 1 then
                            player_speed <= player_speed * 2;
                        end if;
                    when BONUS_ADD_POWER_BLOCK => -- Power Bonus
                        if player_power < 15 then
                            player_power <= player_power + 1;
                        end if;
                    when BONUS_ADD_BOMB_BLOCK => -- Add bomb Bonus
                        if player_max_bombs < 31 then
                            player_max_bombs <= player_max_bombs + 1;
                        end if;
                    when BONUS_GODMODE_BLOCK => -- God mode
                        player_god_mode <= '1';
                        player_god_mode_activation := in_millisecond;
                    when BONUS_WALLHACK_BLOCK => -- Wall hack
                        player_wall_hack <= '1';
                        player_wall_hack_activation := in_millisecond;
                    when BONUS_LIFE_BLOCK => -- Add live
                        if player_lives < 3 then
                            player_lives <= player_lives + 1;
                        end if;
                    -- Malus
                    when MALUS_DISABLE_BOMBS_BLOCK => -- Disable bomb planting
                        player_can_plant_bomb <= '0';
                        player_no_bombs_activation := in_millisecond;
                    when MALUS_INVERSED_COMMANDS_BLOCK => -- Activate inversed command
                        player_inversed_commands <= '1';
                    when MALUS_REMOVE_POWER_BLOCK => -- Power Bonus
                        if player_power > 0 then
                            player_power <= player_power - 1;
                        end if;
                    when others => null;
                end case;
            end if;
        end if;
    end process;

    ----------------------------------------------------------------------------
    -- COMMANDS CONTROLLER PROCESS
    ----------------------------------------------------------------------------

    process(clk)
        variable real_speed : integer range -2**13 to 2**13 - 1;
    begin
        if rising_edge(clk) then
            if rst = '1' then
                player_position <= PLAYER_INITIAL_POSITION;
                player_nb_bombs <= 0;
            else
                out_action <= EMPTY_PLAYER_ACTION;

                -- Select speed
                case player_inversed_commands is
                    when '0' =>
                        real_speed := player_speed;
                    when '1' =>
                        real_speed := -player_speed;
                    when others => null;
                end case;

                -- Update position
                case in_io is
                    when CONTROL_FORWARD =>
                        if in_dol(D_UP) = '1' or player_wall_hack = '1' then
                            player_position.X <= player_position.X - real_speed;
                        end if;
                    when CONTROL_BACK =>
                        if in_dol(D_DOWN) = '1' or player_wall_hack = '1' then
                            player_position.X <= player_position.X + real_speed;
                        end if;
                    when CONTROL_LEFT =>
                        if in_dol(D_LEFT) = '1' or player_wall_hack = '1' then
                            player_position.Y <= player_position.Y - real_speed;
                        end if;
                    when CONTROL_RIGHT =>
                        if in_dol(D_RIGHT) = '1' or player_wall_hack = '1' then
                            player_position.Y <= player_position.Y + real_speed;
                        end if;
                    when CONTROL_BOMB =>
                        if (player_nb_bombs < player_max_bombs) and (player_can_plant_bomb = '1') then
                            player_nb_bombs <= player_nb_bombs + 1;
                            out_action <= (PLANT_NORMAL_BOMB, in_millisecond);
                        end if;
                    when others => null;
                end case;
            end if;
        end if;
    end process;

    out_player_status <= (player_state, player_direction);
    out_power <= player_power;
    out_position <= player_position;
end player;
