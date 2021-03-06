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
end package;

package body PROJECT_POS_FUNCTIONS_PKG is
    -- Linear increment
    function INCR_POSITION_LINEAR(pos : in grid_position)
        return grid_position is
        variable result : grid_position := DEFAULT_GRID_POSITION;
    begin
        if pos = DEFAULT_LAST_GRID_POSITION then
            result := (0, 0);
        elsif pos.j = (GRID_COLS - 1) then
            result := (pos.i + 1, 0);
        else
            result := (pos.i, pos.j + 1);
        end if;
        
        return result;
    end INCR_POSITION_LINEAR;

    function INCR_POSITION_BORDER(pos : in grid_position)
        return grid_position is
        variable result : grid_position := DEFAULT_GRID_POSITION;
    begin
        if pos = DEFAULT_LAST_GRID_POSITION then
            result := DEFAULT_GRID_POSITION;
        elsif pos.i > 0 and pos.i < GRID_ROWS - 1 then
            if pos.j = 0 then
                result := (pos.i, GRID_COLS - 1);
            else
                result := (pos.i + 1, 0);
            end if;
        elsif pos.i = 0 then
            if pos.j < GRID_COLS - 1 then
                result := (pos.i, pos.j + 1);
            else
                result := (pos.i + 1, 0);
            end if;
        else
            if pos.j < GRID_COLS - 1 then
                result := (pos.i, pos.j + 1);
            end if;
        end if;
        
        return result;
    end INCR_POSITION_BORDER;

    -- Linear decrement
    function DECR_POSITION_LINEAR(pos : in grid_position)
        return grid_position is
        variable result : grid_position := DEFAULT_GRID_POSITION;
    begin
        if pos = (0, 0) then
          result := (GRID_ROWS - 1, GRID_COLS - 1);
        elsif pos.j = 0 then
          result := (pos.i - 1, GRID_COLS - 1);
        else
          result := (pos.i, pos.j - 1);
        end if;
        
        return result;
    end DECR_POSITION_LINEAR;

    -- Circular increment
    function INCR_POSITION_CIRCULAR(pos : in grid_position; iteration: integer)
    return grid_position is
        variable current_segment : integer := 0;
        variable add_segment : integer range 0 to GRID_COLS + GRID_ROWS - 1 := GRID_COLS;
        variable result : grid_position := DEFAULT_GRID_POSITION;
    begin
        for k in 0 to 15 loop
            if (iteration + 1) >= (GRID_COLS * GRID_ROWS) - 1 then
                result := (0, 0);
            elsif (iteration + 1) >= current_segment and (iteration + 1) < current_segment + add_segment then
                case (k mod 4) is
                    when 0 => result := (pos.i, pos.j + 1);
                    when 1 => result := (pos.i + 1, pos.j);
                    when 2 => result := (pos.i, pos.j - 1);
                    when 3 => result := (pos.i - 1, pos.j);
                end case;
            else
                if (k mod 2) = 0 then
                    add_segment := GRID_ROWS - (k mod 4);
                else
                    add_segment := GRID_COLS - (k mod 4);
                end if;
            end if;
        end loop;
        
        return result;
    end INCR_POSITION_CIRCULAR;
end package body;
