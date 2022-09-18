local function tier(default)
	return {
		type = "number",
		range = { min = 0, max = 7 },
		int = true,
		default = default
	}
end
return {
	type = "table",
	entries = {
		tiers = {
			type = "table",
			entries = {
				minor = tier(3),
				ordinary = tier(5),
				strong = tier(7)
			}
		},
		max_in_use = {
			type = "number",
			range = { min = 0, max = 10 },
			default = 5,
			description = "How many potions can be used at a time"
		}
	}
}