-- ## 'perfhud' ## --
local modName = minetest.get_current_modname()

-- ## How often should we check for updates? ## --
local updateInterval = math.min(math.max(0.5, minetest.settings:get("perfhud_update_interval") or 1), 5)

-- ## Checking a boolean is better than checking for a mod path every update cycle... ## --
local mod_available_mesecons_debug = false
local mod_available_biome_lib = false

-- ## List that holds the HUD ids for all players that have the HUD enabled ## --
local perfHUDs = {}

-- ## Function to check if a list is empty ## --
local function listIsEmpty(list)
	for _, _ in pairs(list) do
		return false
	end
	return true
end

-- ## Function to round a number to given decimal places ## --
local function round(number, decimalPlaces)
	local multiplier = 10^(decimalPlaces or 0)
	return math.floor(number * multiplier + 0.5) / multiplier
end

-- ## Function that converts a position hash into an actuall position and returns it as a string ## --
local function posHashToString(posHash)
	return minetest.pos_to_string(minetest.get_position_from_hash(posHash))
end

-- ## Function that takes a number which represents Kilobytes and returns a string that adds the suffix, additionally convertes the Kilobytes into Megabytes (if that's suitable) ## --
local function KBtoStr(KB)
	if math.abs(KB) >= 1024 then
		return tostring(math.floor(KB / 1024)).." MB"
	else
		return tostring(math.floor(KB)).." KB"
	end
end

-- ## Function to create a HUD ## --
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

-- ## Function to remove a HUD ## --
local function removePerfHUD(playerName)
	local player = minetest.get_player_by_name(playerName)
	if player ~= nil and perfHUDs[playerName] ~= nil then
		player:hud_remove(perfHUDs[playerName])
	end
end

local function getPerfString()
	local perfStr = ""
	-- ## Get lag in seconds reported by the engine and add it to the string ## --
	local max_lag = minetest.get_server_max_lag()
	if max_lag ~= nil then
		perfStr = "Max lag: "..round(max_lag, 2).."s\n"
	end
	-- ## Get mesecons_debug data and add it to the string ## --
	if mod_available_mesecons_debug and mesecons_debug ~= nil then
		if mesecons_debug.context_store ~= nil then
			local top_ctx, top_hash
			for hash, ctx in pairs(mesecons_debug.context_store) do
				if not top_ctx or top_ctx.avg_micros_per_second < ctx.avg_micros_per_second then
					top_ctx = ctx
					top_hash = hash
				end
			end
			if top_ctx ~= nil and top_ctx.penalty ~= nil and top_hash ~= nil then
				perfStr = perfStr.."Most laggy Mesecons chunk: "..posHashToString(top_hash).." (penalty: "..round(top_ctx.penalty, 2)..")\n"
			end
		end
	end
	-- ## Get biome_lib data and add it to the string ## --
	if mod_available_biome_lib and biome_lib ~= nil and biome_lib.block_log ~= nil then
		local queueLength = 0
		if biome_lib.block_log[1] ~= nil then
			queueLength = #biome_lib.block_log
		end
		perfStr = perfStr.."Biome Lib queue length: "..queueLength.."\n"
	end
	-- ## Check how much RAM Lua is using ## --
	perfStr = perfStr.."Lua uses "..KBtoStr(collectgarbage("count")).." RAM"
	return perfStr
end

-- ## Register chat command ## --
minetest.register_chatcommand("perfhud", {
	description = "Toggles the performance HUD.",
	privs = { interact = true },
	func = function(playerName, params)
		if perfHUDs[playerName] ~= nil then
			-- ## We need to disable/remove the HUD ## --
			removePerfHUD(playerName)
			perfHUDs[playerName] = nil
			minetest.log("action", playerName.." disabled the performance HUD.")
			return true, "Performance HUD disabled."
		else
			-- ## We need to add/create the HUD ## --
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

-- ## Remove HUD id from list if player leaves the server ## --
minetest.register_on_leaveplayer(function(player, timedOut)
	local playerName = player:get_player_name()
	if playerName ~= nil and playerName ~= "" then
		if perfHUDs[playerName] ~= nil then
			perfHUDs[playerName] = nil
		end
	end
end)

-- ## Update all HUDs function ## --
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

-- ## Check if third party mods are available/enabled and start first timer afterwards ## --
minetest.register_on_mods_loaded(function()
	if minetest.get_modpath("mesecons_debug") ~= nil then
		mod_available_mesecons_debug = true
		minetest.log("info", "["..modName.."] 'mesecons_debug' mod available.")
	else
		minetest.log("info", "["..modName.."] 'mesecons_debug' mod NOT available.")
	end
	if minetest.get_modpath("biome_lib") ~= nil then
		mod_available_biome_lib = true
		minetest.log("info", "["..modName.."] 'biome_lib' mod available.")
	else
		minetest.log("info", "["..modName.."] 'biome_lib' mod NOT available.")
	end
	minetest.after(updateInterval, updateHUDs)
end)