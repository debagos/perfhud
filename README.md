# PerfHUD
This is a small Mod that adds an `/perfhud` command that can be executed by everyone who has the `interact` privilege.

The command creates a little HUD in the bottom of the screen with yellow text that shows these informations (if available):

1. Current max lag reported by the engine (in seconds)
2. Most laggy Mesecons chunk and current penalty there (needs the `mesecons_debug` mod)
3. biome_lib queue length (needs the `biome_lib` mod)
4. RAM used by Lua

You can set how fast the HUD gets updated by the `perfhud_update_interval` setting. Valid intervals are between 0.5 and 5 seconds.