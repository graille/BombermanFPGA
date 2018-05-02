library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.PROJECT_TYPES_PKG.all;

entity player is
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
        out_hitbox : out vector;

        out_plant_bomb : out std_logic := '0';

        out_player_status : out player_status_type
    );
end player;

architecture player of player is
    constant PLAYER_INITIAL_POSITION : vector := (0,0);
    constant DEFAULT_HITBOX : vector := (3276, 3276);
    constant DEFAULT_SPEED : integer := 1;

    -- Players states
    signal player_alive : player_status := '1'; -- 1 = alive, 0 = dead

    -- Players informations
    signal player_position : vector := PLAYER_INITIAL_POSITION;
    signal player_speed : integer range 0 to 2**12 - 1;
    signal player_power : integer range 0 to 15 := 1;
    signal player_hitbox : vector := DEFAULT_HITBOX;

    signal player_max_bombs : integer range 0 to 31 := 1;
    signal player_nb_bombs : integer range 0 to 31 := 0;
    signal player_can_plant_bomb : std_logic := '1';

    -- Bonus
    signal player_god_mode : std_logic := '0'; --
    signal player_wall_hack : std_logic := '0';
    signal player_lives : integer range 0 to 3;

    -- Malus
    signal player_inversed_commands : std_logic := '0';
begin
    process(clk)
        constant player_god_mode_duration : integer := 5000;
        variable player_god_mode_activation : positive range 0 to 2**21 - 1 := 0;

        constant player_wall_hack_duration : integer := 10000;
        variable player_wall_hack_activation : positive range 0 to 2**21 - 1 := 0;

        constant player_no_bombs_duration : integer := 7000;
        variable player_no_bombs_activation : positive range 0 to 2**21 - 1 := 0;

        constant player_hitbox_change_duration : integer := 10000;
        variable player_hitbox_change_activation : positive range 0 to 2**21 - 1 := 0;
    begin
        if rising_edge(clk) then
            if rst = '1' then
                player_position <= PLAYER_INITIAL_POSITION;
                player_speed <= DEFAULT_SPEED;
                player_power <= 1;
                player_hitbox <= DEFAULT_HITBOX;

                player_max_bombs <= 1;
                player_nb_bombs <= 0;
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

                if (in_millisecond - player_hitbox_change_activation) mod player_hitbox_change_duration = 0 then
                    player_hitbox <= DEFAULT_HITBOX;
                end if;

                case in_next_block is
                    when 10|11|12 =>
                        if player_lives = 1 then
                            player_alive <= '0';
                        end if;

                        player_lives <= player_lives - 1;
                    when 13 => -- Speed Bonus
                        if player_speed < 2**12 - 1;
                            player_speed <= player_speed * 2;
                        end if;
                    when 14 => -- Power Bonus
                        if player_power < 15 then
                            player_power <= player_power + 1;
                        end if;
                    when 15 => -- Add bomb Bonus
                        if player_max_bombs < 31 then
                            player_max_bombs <= player_max_bombs + 1;
                        end if;
                    when 16 => -- God mode
                        player_god_mode <= '1';
                        player_god_mode_activation := in_millisecond;
                    when 17 => -- Wall hack
                        player_wall_hack <= '1';
                        player_wall_hack_activation := in_millisecond;
                    when 18 => -- Add live
                        if player_lives < 3 then
                            player_lives <= player_lives + 1;
                        end if;
                    when 19 => -- Reduce player size
                        player_hitbox <= (1000,1000);
                        player_hitbox_change_activation := in_millisecond;
                    -- Malus
                    when 20 => -- Disable bomb planting
                        player_can_plant_bomb <= '0';
                        player_no_bombs_activation := in_millisecond;
                    when 21 => -- Activate inversed command
                        player_inversed_commands <= '1';
                    when 22 => -- Increase player size
                        player_hitbox <= (DEFAULT_HITBOX(0) * 2, DEFAULT_HITBOX(0) * 2);
                        player_hitbox_change_activation := in_millisecond;
                end case;
            end if;
        end if;
    end process;

    process(clk)
        variable real_speed : integer range -2**13 to 2**13 - 1;
    begin
        if rising_edge(clk) then
            if rst = '1' then
            else
                out_plant_bomb <= '0';

                -- Select speed
                case player_descriptor.inversed_commands is
                    when '0' =>
                        real_speed := player_descriptor.speed;
                    when '1' =>
                        real_speed := -player_descriptor.speed;
                    when others => null;
                end case;

                -- Update position
                case in_io is
                    when CONTROL_FORWARD =>
                        if in_dol(0) = '1' or player_wall_hack = '1' then
                            player_position(0) = player_position(0) - speed;
                        end if;
                    when CONTROL_BACK =>
                        if in_dol(2) = '1' or player_wall_hack = '1' then
                            player_position(0) = player_position(0) + speed;
                        end if;
                    when CONTROL_LEFT =>
                        if in_dol(3) = '1' or player_wall_hack = '1' then
                            player_position(1) = player_position(1) - speed;
                        end if;
                    when CONTROL_RIGHT =>
                        if in_dol(1) = '1' or player_wall_hack = '1' then
                            player_position(1) = player_position(1) + speed;
                        end if;
                    when CONTROL_BOMB =>
                        if player_nb_bombs < player_nb_max_bombs and player_can_plant_bomb = '1' then
                            player_nb_bombs <= player_nb_bombs + 1;
                            out_plant_bomb <= '1';
                        end if;
                    when others => null;
                end case;
            end if;
        end if;
    end process;

    out_power <= player_power;
    out_position <= player_position;
    out_hitbox <= player_hitbox;


end player;
