package PROJECT_PLAYER_ACTIONS_PKG is
    -- Actions
    constant PLANT_NORMAL_BOMB : integer := 0;

    -- Declare associated types
    subtype player_action_category is (PLANT_BOMB);
    type player_action is record
        category            : player_action_category;
        created             : millisecond_count;
    end record;

    constant EMPTY_PLAYER_ACTION : player_action := (0, 0);
end package
