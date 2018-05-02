use work.PROJECT_TYPES_PKG.all;

package PROJECT_PLAYER_ACTIONS_PKG is
    -- Declare associated types
    type player_action_category is (
        EMPTY_ACTION,
        PLANT_NORMAL_BOMB
    );
    
    type player_action is record
        category  : player_action_category;
        created   : millisecond_count;
    end record;

    constant EMPTY_PLAYER_ACTION : player_action := (EMPTY_ACTION, 0);
end package;
