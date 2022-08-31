local updateInterval = 1
local perfHUDs = {}

local function listIsEmpty(list)
	for _, _ in pairs(list) do
		return false
	end
	return true
end

local function round(number, decimalPlaces)
	local multiplier = 10^(decimalPlaces or 0)
	return math.floor(number * multiplier + 0.5) / multiplier
end

local function posHashToString(posHash)
	return minetest.pos_to_string(minetest.get_position_from_hash(posHash))
end

local function createPerfHUD(playerName)
	local player = minetest.get_player_by_name(playerName)
	if player ~= nil then
		return player:hud_add({
			hud_elem_type = "text",
			name = "perfhud",
			position = { x = 0.5, y = 1 },
			alignment = { x = 0, y = -1 },
			offset = { x = 0, y = -100 },
			number = 0xFFFF00,
			text = "Loading...",
			z_index = 999,
		})
	else
		return nil
	end
end

local function removePerfHUD(playerName)
	local player = minetest.get_player_by_name(playerName)
	if player ~= nil and perfHUDs[playerName] ~= nil then
		return player:hud_remove(perfHUDs[playerName])
	else
		return nil
	end
end

local function getPerfString()
	local perfStr = ""
	-- ## mesecons_debug ## --
	if minetest.get_modpath("mesecons_debug") and mesecons_debug ~= nil then
		if mesecons_debug.context_store ~= nil then
			local top_ctx, top_hash
			for hash, ctx in pairs(mesecons_debug.context_store) do
				if not top_ctx or top_ctx.avg_micros_per_second < ctx.avg_micros_per_second then
					top_ctx = ctx
					top_hash = hash
				end
			end
			if top_ctx ~= nil and top_hash ~= nil then
				perfStr = perfStr.."Most laggy Mesecons chunk: "..posHashToString(top_hash).." (penalty: "..tostring(round(top_ctx.penalty, 2))..")\n"
			end
		end
	end
	-- ## biome_lib ## --
	if minetest.get_modpath("biome_lib") and biome_lib ~= nil and biome_lib.block_log ~= nil then
		local queueLength = 0
		if biome_lib.block_log[1] ~= nil then
			queueLength = #biome_lib.block_log
		end
		perfStr = perfStr.."biome_lib queue length: "..queueLength.."\n"
	end
	-- ## No data available... ## --
	if perfStr == "" then
		perfStr = "No data available..."
	end
	return perfStr
end

minetest.register_chatcommand("perfhud", {
	description = "Toggles the performance HUD.",
	privs = { interact = true },
	func = function(playerName, params)
		if perfHUDs[playerName] ~= nil then
			removePerfHUD(playerName)
			perfHUDs[playerName] = nil
			minetest.log("action", playerName.." disabled the performance HUD.")
			return true, "Performance HUD disabled."
		else
			local HID = createPerfHUD(playerName)
			if HID ~= nil then
				perfHUDs[playerName] = HID
				minetest.log("action", playerName.." enabled the performance HUD.")
				return true, "Performance HUD enabled."
			else
				minetest.log("error", playerName.." tried to enabled the performance HUD, but HUD could not get created...")
				return false, "Error: Could not create HUD."
			end
		end
	end,
})

minetest.register_on_leaveplayer(function(player, timedOut)
	local playerName = player:get_player_name()
	if playerName ~= nil and playerName ~= "" then
		if perfHUDs[playerName] ~= nil then
			perfHUDs[playerName] = nil
		end
	end
end)

local function updateHUDs()
	if not listIsEmpty(perfHUDs) then
		local perfString = getPerfString()
		for playerName, HID in pairs(perfHUDs) do
			local player = minetest.get_player_by_name(playerName)
			if player ~= nil then
				player:hud_change(HID, "text", perfString)
			end
		end
	end
	minetest.after(updateInterval, updateHUDs)
end

minetest.after(updateInterval, updateHUDs)