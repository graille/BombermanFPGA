library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.PROJECT_PARAMS_PKG.all;
use work.PROJECT_DIRECTION_PKG.all;
use work.PROJECT_TYPES_PKG.all;

package PROJECT_POS_FUNCTIONS_PKG is
    -- These functions are used to navigate into the game grid
    function INCR_POSITION_LINEAR(pos: in grid_position)
        return grid_position;

    function INCR_POSITION_BORDER(pos: in grid_position)
        return grid_position;

    function INCR_POSITION_CIRCULAR(pos: in grid_position; iteration: integer)
        return grid_position;

    function DECR_POSITION_LINEAR(pos: in grid_position)
        return grid_position;

    function NB_PLAYERS_ALIVE(players_alive: in std_logic_vector)
        return integer;
end package;

package body PROJECT_POS_FUNCTIONS_PKG is
    -- Linear increment
    function INCR_POSITION_LINEAR(pos : in grid_position)
        return grid_position is
    begin
        if pos = (GRID_ROWS - 1, GRID_COLS - 1) then
            return (0, 0);
        elsif pos.j = (GRID_COLS - 1) then
            return (pos.i + 1, 0);
        else
            return (pos.i, pos.j + 1);
        end if;
    end INCR_POSITION_LINEAR;

    function INCR_POSITION_BORDER(pos : in grid_position)
        return grid_position is
    begin
        if pos = (GRID_ROWS - 1, GRID_COLS - 1) then
            return (0, 0);
        elsif pos.i > 0 and pos.i < GRID_ROWS - 1 then
            if pos.j = 0 then
                return (pos.i, GRID_ROWS - 1);
            else
                return (pos.i + 1, 0);
            end if;
        elsif pos.i = 0 then
            if pos.j < GRID_COLS - 1 then
                return (pos.i, pos.j + 1);
            else
                return (pos.i + 1, 0);
            end if;
        else
            if pos.j < GRID_COLS - 1 then
                return (pos.i, pos.j + 1);
            end if;
        end if;
    end INCR_POSITION_BORDER;

    -- Linear decrement
    function DECR_POSITION_LINEAR(pos : in grid_position)
        return grid_position is
    begin
        if pos = (0, 0) then
          return (GRID_ROWS - 1, GRID_COLS - 1);
        elsif pos.j = 0 then
          return (pos.i - 1, GRID_COLS - 1);
        else
          return (pos.i, pos.j - 1);
        end if;
    end DECR_POSITION_LINEAR;

    -- Circular increment
    function INCR_POSITION_CIRCULAR(pos : in grid_position; iteration: integer)
    return grid_position is
        variable current_segment : integer := 0;
        variable add_segment : integer range 0 to GRID_COLS + GRID_ROWS - 1 := GRID_COLS;
    begin
        for k in 0 to 15 loop
            if (iteration + 1) >= (GRID_COLS * GRID_ROWS) - 1 then
                return (0, 0);
            elsif (iteration + 1) >= current_segment and (iteration + 1) < current_segment + add_segment then
                case (k mod 4) is
                    when 0 => return (pos.i, pos.j + 1);
                    when 1 => return (pos.i + 1, pos.j);
                    when 2 => return (pos.i, pos.j - 1);
                    when 3 => return (pos.i - 1, pos.j);
                end case;
            else
                if (k mod 2) = 0 then
                    add_segment := GRID_ROWS - (k mod 4);
                else
                    add_segment := GRID_COLS - (k mod 4);
                end if;
            end if;
        end loop;
    end INCR_POSITION_CIRCULAR;

    --
    function NB_PLAYERS_ALIVE(players_alive: in std_logic_vector)
        return integer is
        variable nb_alive : integer range 0 to NB_PLAYERS - 1 := 0;
    begin
        for k in 0 to NB_PLAYERS - 1 loop
            if players_alive(k) = '1' then
                nb_alive := nb_alive + 1;
            end if;
        end loop;
        return nb_alive;
    end NB_PLAYERS_ALIVE;
end package body;
