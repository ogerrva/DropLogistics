-- Initialization
script.on_init(function()
    storage.active_inserters = storage.active_inserters or {}
end)

script.on_configuration_changed(function()
    storage.active_inserters = storage.active_inserters or {}
end)

local allowed_inserters = {
    ["inserter"] = true,              -- Amarelo
    ["long-handed-inserter"] = true   -- Vermelho
}

-- Count items on the ground within a small area
local function count_items_on_ground(surface, position)
    local area = {
        {position.x - 0.5, position.y - 0.5},
        {position.x + 0.5, position.y + 0.5}
    }
    return surface.count_entities_filtered{
        area = area,
        type = "item-entity"
    }
end

-- GUI Management: Opens the interface and ensures old elements are destroyed
script.on_event(defines.events.on_gui_opened, function(event)
    local player = game.players[event.player_index]
    local entity = event.entity

    storage.active_inserters = storage.active_inserters or {}

    if entity and entity.valid and allowed_inserters[entity.name] then
        -- CRITICAL FIX: Destroy the entire frame to remove any old UI leftovers
        if player.gui.relative["drop_logistics_frame"] then
            player.gui.relative["drop_logistics_frame"].destroy()
        end

        local frame = player.gui.relative.add{
            type = "frame",
            name = "drop_logistics_frame",
            caption = "Direct Logistics",
            anchor = {
                gui = defines.relative_gui_type.inserter_gui,
                position = defines.relative_gui_position.right
            }
        }

        local is_on = storage.active_inserters[entity.unit_number] ~= nil
        local button_style = is_on and "confirm_button" or "button"
        local button_text = is_on and "Trash: ON" or "Trash: OFF"

        frame.add{
            type = "button",
            name = "btn_toggle_drop",
            caption = button_text,
            style = button_style,
            tags = {unit_number = entity.unit_number}
        }
    end
end)

-- Button Interaction
script.on_event(defines.events.on_gui_click, function(event)
    if event.element.name == "btn_toggle_drop" then
        local unit_number = event.element.tags.unit_number
        local player = game.players[event.player_index]
        local entity = player.opened 

        if entity and entity.valid and entity.unit_number == unit_number then
            if storage.active_inserters[unit_number] then
                storage.active_inserters[unit_number] = nil
                event.element.caption = "Trash: OFF"
                event.element.style = "button"
            else
                storage.active_inserters[unit_number] = entity
                event.element.caption = "Trash: ON"
                event.element.style = "confirm_button"
            end
        end
    end
end)

-- Main logic loop: fixed at 5 items limit
script.on_nth_tick(10, function()
    if not storage.active_inserters then return end

    for id, inserter in pairs(storage.active_inserters) do
        if not inserter.valid then
            storage.active_inserters[id] = nil
        else
            local hand = inserter.held_stack
            if hand and hand.valid_for_read then
                local surface = inserter.surface
                local drop_pos = inserter.drop_position
                
                -- Check for ground limit before spilling
                if count_items_on_ground(surface, drop_pos) < 5 then
                    local dropped_items = surface.spill_item_stack{
                        position = drop_pos,
                        stack = hand,
                        enable_looting = true,
                        force = inserter.force,
                        allow_belts = false
                    }
                    
                    if dropped_items and #dropped_items > 0 then
                        for _, item_entity in pairs(dropped_items) do
                            item_entity.order_deconstruction(inserter.force)
                        end
                        hand.clear()
                    end
                end
            end
        end
    end
end)

-- Cleanup when entity is removed
local function on_removed(event)
    local entity = event.entity
    if entity and entity.valid and entity.unit_number then
        if storage.active_inserters and storage.active_inserters[entity.unit_number] then
            storage.active_inserters[entity.unit_number] = nil
        end
    end
end

script.on_event(defines.events.on_entity_died, on_removed)
script.on_event(defines.events.on_player_mined_entity, on_removed)
script.on_event(defines.events.on_robot_mined_entity, on_removed)