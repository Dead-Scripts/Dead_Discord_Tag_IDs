Config = {
	Prefix = '^9[^1Dead-Tags^9] ^3',
	TagsForStaffOnly = false, -- "DiscordTagIDs.Use.Tag-Toggle"
	ShowOwnTag = true, -- Should the tag also be shown for own user?
	UseDiscordName = true,
	ShowDiscordDescrim = false, -- Should it show Badger#0002 ?
	RequiresLineOfSight = true, -- Requires the player be in their line of sight for tags to be shown
	FormatDisplayName = "{PLAYER_NAME} [{SERVER_ID}]",
	UseKeyBind = true, -- It will only show on keybind pressed or toggled
	UseKeyBindToggle = true, -- It will only show when the keybind is toggled, turning this to false will make the tags only shown when the keybind is held down
	KeyBindToggleDefaultShow = true, -- By default, the tags will be shown unless toggled off if this is true
	KeyBind = 10, -- Pageup -- USE https://docs.fivem.net/docs/game-references/controls/ for keycodes
	roleList = {
		{1, "~g~Member ~w~"},  
		{1, "~b~Developer ~w~"},
		{1, "~r~STAFF ~w~"},  
		{1, "~RGB~FOUNDER ~w~"}, 
	},
	HUD = {
		Display = true,
		Format = '~p~Active Headtag: {HEADTAG}',
		x = .75,
		y = .50,
		Scale = .55
	},
}