players = {}
minetest.register_on_joinplayer(function(player)
    players[player:get_player_name()] = {in_use = 0, timers={}}
end)
config =
    modlib.conf.import(
    "magic_potions",
    {
        type = "table",
        children = {
            tiers = {
                keys = {
                    type = "string"
                },
                values = {
                    type = "number",
                    range = {0, 7}
                }
            },
            max_in_use = {
                type = "number",
                range = {0, 10}
            }
        }
    }
)
modlib.table.add_all(getfenv(1), config)
function register_potion(potion_def)
    for tier, tier_def in pairs(tiers) do
        local def = {}
        local effect = potion_def.effect(tier_def)
        def.on_use = function(stack, player)
            local player_data = players[player:get_player_name()]
            local player_in_use = player_data.in_use
            if player_in_use == max_in_use then
                minetest.chat_send_player(
                    player:get_player_name(),
                    minetest.get_color_escape_sequence("#FF0000") ..
                        "You can only use " .. max_in_use .. " potions at a time!"
                )
                return
            end
            player_data.in_use = player_in_use + 1
            effect(player)
            local timer = hud_timers.add_timer(
                player:get_player_name(),
                {
                    name = potion_def.name .. " Potion",
                    duration = potion_def.duration * tier_def,
                    color = potion_def.color,
                    rounding_steps = 1
                }
            )
            player_data.timers[timer] = true
            timer.on_complete = function(playername)
                local player_in_use = players[player:get_player_name()]
                player_in_use.timers[timer] = nil
                player_in_use.in_use = player_in_use.in_use - 1
                potion_def.reverse(playername)
            end
            local pos = player:getpos()
            local pr = 0.2
            minetest.add_particlespawner(
                {
                    amount = 30,
                    time = 1.5,
                    minvel = {x = -pr, y = 0.1, z = -pr},
                    maxvel = {x = pr, y = 0.5, z = pr},
                    minacc = {x = -0.05, y = 0.1, z = -0.05},
                    maxacc = {x = 0.05, y = 0.05, z = 0.05},
                    minexptime = 2,
                    maxexptime = 6,
                    minsize = 0.2,
                    maxsize = 1,
                    collisiondetection = false,
                    vertical = false,
                    texture = "magic_potions_particle_white.png^[multiply:#" .. potion_def.color,
                    minpos = pos,
                    maxpos = pos
                }
            )
            stack:take_item()
            return stack
        end
        def.inventory_image =
            "magic_potions_liquid.png^[multiply:#" ..
            potion_def.color .. "^magic_potions_vessel_" .. tier .. ".png^[makealpha:255,0,255"
        def.description = tier:sub(1, 1):upper() .. tier:sub(2) .. " " .. potion_def.name .. " Potion"
        def.stack_max = max_in_use
        minetest.register_craftitem("magic_potions:" .. tier .. "_" .. potion_def.name:lower() .. "_potion", def)
    end
end

local physic_reverses = {}

function player_physics_effect(attribute, gain_func_builder)
    local reverses = {}
    physic_reverses[attribute] = reverses
    return function(tier)
        local gain_func = gain_func_builder(tier)
        return function(player)
            local physics = player:get_physics_override()
            local gain = gain_func(physics[attribute], tier)
            local queue = reverses[player:get_player_name()]
            if queue then
                table.insert(queue, gain)
            else
                reverses[player:get_player_name()] = {gain}
            end
            physics[attribute] = physics[attribute] + gain
            player:set_physics_override(physics)
        end
    end
end

function player_physics_reverse(attribute)
    local reverses = physic_reverses[attribute]
    return function(playername)
        local gains = reverses[playername]
        local player = minetest.get_player_by_name(playername)
        local physics = player:get_physics_override()
        physics[attribute] = physics[attribute] - table.remove(gains, 1)
        player:set_physics_override(physics)
    end
end

function register_physics_potion(name, color, func, lowername)
    lowername = lowername or name:lower()
    register_potion(
        {
            name = name,
            color = color,
            duration = 5,
            effect = player_physics_effect(lowername, func),
            reverse = player_physics_reverse(lowername)
        }
    )
end

register_physics_potion(
    "Speed",
    "DDDD00",
    function(t)
        return function(x)
            return t / 7
        end
    end
)
register_physics_potion(
    "Jump",
    "FF01FF",
    function(t)
        return function(x)
            return t / 7
        end
    end
)
register_physics_potion(
    "Fly",
    "333333",
    function(t)
        return function(x)
            return -x * t / 14
        end
    end,
    "gravity"
)

function regen_effects(property, effect_name)
    local affected = {}
    getfenv(1)[effect_name .. "s"] = affected

    getfenv(1)[effect_name] = function(tier)
        local gain = tier * 0.2
        local reverses = {}
        physic_reverses[effect_name] = reverses
        return function(player)
            local name = player:get_player_name()
            local queue = reverses[name]
            if queue then
                table.insert(queue, gain)
            else
                reverses[name] = {gain}
            end
            affected[name] = affected[name] or {total = 0, outstanding = 0}
            affected[name].total = affected[name].total + gain
        end
    end

    getfenv(1)[effect_name .. "_reverse"] = function()
        local reverses = physic_reverses[effect_name]
        return function(playername)
            local gains = reverses[playername]
            local total = affected[playername].total - table.remove(gains, 1)
            if #gains == 0 then
                affected[playername] = nil
            end
            affected[playername].total = total
        end
    end

    minetest.register_on_joinplayer(
        function(player)
            affected[player:get_player_name()] = {total = 0, outstanding = 0}
        end
    )

    minetest.register_on_leaveplayer(
        function(player)
            local name = player:get_player_name()
            affected[name] = nil
        end
    )
    minetest.register_globalstep(
        function(dtime)
            for name, effect in pairs(affected) do
                effect.outstanding = effect.outstanding + dtime * effect.total
                local eff = math.floor(effect.outstanding)
                if eff > 0 then
                    local player = minetest.get_player_by_name(name)
                    if player and (property ~= "hp" or player:get_hp() > 0) then
                        player["set_" .. property](
                            player,
                            math.min(
                                player:get_properties()[property .. "_max"],
                                player["get_" .. property](player) + eff
                            ),
                            "magic_potions:" .. effect_name
                        )
                    end
                    effect.outstanding = effect.outstanding - eff
                end
            end
        end
    )
end

minetest.register_on_leaveplayer(
    function(player)
        local name = player:get_player_name()
        for _, prop in pairs({"speed", "jump", "gravity", "healing", "breathing"}) do
            physic_reverses[prop][name] = nil
        end
        players[name] = nil
    end
)

regen_effects("hp", "healing")

register_potion(
    {
        name = "Healing",
        color = "00FF00",
        duration = 10,
        effect = healing,
        reverse = healing_reverse
    }
)

regen_effects("breath", "breathing")

register_potion(
    {
        name = "Air",
        color = "AAAAFF",
        duration = 10,
        effect = breathing,
        reverse = breathing_reverse
    }
)

function clear_potions(player)
    local name = player:get_player_name()
    for timer, _ in pairs(players[name].timers) do
        timer.time_left = -1
    end
    hud_timers.maintain_timers(hud_timers.timers[player:get_player_name()], 0, player)
end

minetest.register_on_dieplayer(clear_potions)
minetest.register_on_leaveplayer(clear_potions)