-- Configuration 2: Electric Boogaloo (the first part is in the Configuration object)
--
-- Old Assets
-- ----------
--
-- This is for assets and your name generator. Your old assets config is *sort of* drop in.
-- Just make sure you modify it to include the new fields.
--
-- Major differences are the discriminator field, and that you don't need blank tables for
-- things that don't need specific discriminators (except all). I also recommend that you stop 
-- doing asset prep in this file and just pre-prepare all the assets yourself, as it's a very
-- intensive step for a config file (can take over a minute in worst case...) and will delay
-- your NPCs. Plus, you only need to do it once.
--
-- Hair and accessories are still their regular IDs, as they cannot be pre-prepared due to them
-- being instances. Justice will handle this for you.

return {
	-- Discriminators can be anything, as long as they're a table-indexed value.
	-- This means you can use newproxy(), other tables(!), numbers, etc.
	discriminators = { "male", "female" },
	
	-- Names will be generated from this list. This *used* to be a function, but is now just a
	-- list of discriminators since that seems to have been the most popular use. These defaults
	-- are taken from the top 1000 baby names in the UK (my country!) except for the neutral names,
	-- which was taken from.. some random website.
	names = {
		all = {
			"Grey",
			"Ellison",
			"Flynn",
			"Amos",
			"Dorian",
			"Harper",
			"Wyatt",
			"Cameron",
		},
		male = {
			"Oliver",
			"George",
			"Noah",
			"Arthur",
			"Harry",
			"Leo",
			"Muhammad",
			"Jack",
			"Charlie",
			"Oscar",
			"Jacob",
			"Henry",
			"Thomas",
			"Freddie",
			"Alfie",
			"Theo",
			"William",
			"Theodore",
			"Archie",
			"Joshua",
		},
		female = {
			"Olivia",
			"Amelia",
			"Isla",
			"Ava",
			"Ivy",
			"Freya",
			"Lily",
			"Florence",
			"Mia",
			"Willow",
			"Rosie",
			"Sophia",
			"Isabella",
			"Grace",
			"Daisy",
			"Sienna",
			"Poppy",
			"Elsie",
			"Emily",
			"Ella",
		}
	},
	
	-- Faces now support tables as well, meaning you can use those funny swappable bits from
	-- morscore. I've included one as a demo. For regular faces (and custom), use the texture
	-- ID.
	faces = {
		all = {
			20418518,  -- Eer...
			20722053,  -- Shiny Teeth
			26424652,  -- Know-It-All Grin
			226216895, -- Laughing Fun
			243755928, -- Just Trouble
			31117192,  -- Skeptic
			20337265,  -- Disbelief
			23931977,  -- Awkward....
			209715003, -- Suspicious
			209713384, -- Joyful Smile
			141728515, -- Tired Face
			236455674, -- Happy Wink
		},
		male = {
			657217430, -- Drill Sergeant
			255828374, -- Serious Scar Face
			209714802, -- Raig Face
			277939506, -- Furious George
			398670843, -- Nouveau George
		},
		female = {
			209713952, -- Smiling Girl
			334655813, -- Miss Scarlet
			416829065, -- Anime Surprise
			280987381, -- Super Happy Joy
			{ 2801687922, 2801594656, 2801785860, 2801732091 }, -- morscore style face
		}
	},
	
	-- Standard accessory IDs. Justice will import these automatically.
	hair = {
		all = {},
		male = {
			32278814,   -- Trecky Hair
			13477818,   -- Normal Boy Hair
			80922374,   -- Chestnut Spikes
			26658141,   -- Messy Hair
			62743701,   -- Stylish Brown Hair
			4875445470, -- Black Short Parted Hair
			5644883846, -- Cool Boy Hair
			5921587347, -- Brown Curly Hair For Amazing People
			6310032618, -- Black Messy Side Part
			6128248269, -- Black Mullet
			5461545832, -- Blonde Messy Wavy Hair
			6026462825, -- Cool Boy Brown Hair
			323476364,  -- Brown Scene Hair
			4735347390, -- Brown Floof Hair
			6187500468, -- Brown Mullet
		},
		female = {
			5890690147, -- Popstar Hair
			5897464879, -- Blonde Popstar Hair
			5945436918, -- Light Brown Ethereal Hairstyle
			5945433814, -- Blonde Ethereal Hairstyle
			6066575453, -- Curly iconic hair for iconic people in blonde
			6309005259, -- HollywoodLocks in Pink Ombre
			6188729655, -- Blonde Adorable Braided Hair
		}
	},
	
	clothes = {
		-- { shirt, pants } templates
		all = {
			{ 2726208427, 2726208955 }, -- Wick
			{ 2966670286, 2966672001 }, -- Bryce
			{ 292025046, 292632276 },   -- White Tuxedo
			{ 268437110, 268437153 },   -- The Businessman
			{ 289792369, 289792419 },   -- The Private Contractor
			{ 703050473, 703050780 },   -- The Peacoat
			{ 6254472413, 6264952678 }, -- Williams Suit
			{ 6254471893, 6264952160 }, -- Wayne Suit
			{ 6254471472, 6264951480 }, -- Victor Madrazzo Suit
			{ 6254469434, 6264946791 }, -- Thomas Suit
		},
		female = {
			{ 6322087731, 6322092597 }, -- Secretary (it's Pandemonica from Helltaker)
		}
	},
	
	accessories = {
		all = {
			-1,         -- special one so that some NPCs just don't get accessories for variety
			4507911797, -- Sleek Tactical Shades
			11884330,   -- Nerd Glasses
			22070802,   -- Secret Kid Wizard Glasses
			74970669,   -- Eyepatch
			20642008,   -- Bandit
			5728016218, -- White Sponge Mask
			4143016822, -- Vintage Glasses
			5891250919, -- Rosey Gold Vintage Glasses
			4545294588, -- Sleek Vintage Glasses
			4258680288, -- Black Aesthetical Glasses
			4965516845, -- Transfer Student Glasses
		},
		male = {
			158066137,  -- Andrew's Beard
			987022351,  -- Master of Disguise Mustache
			4940496302, -- Full Brown Stubble
			4995497755, -- Stubble Beard
			4315331611, -- Imperial Beard
			5700473228, -- Sponge Mask - Male Star
		},
		female = {
			4300266038, -- Earring Hoops
			6054184925, -- Elegant Low Hair Bow White
			5318235356, -- White Aesthetic Headband
			6305581728, -- Pink Heart Lollipop
		}
	},
	
	-- Just BrickColors.
	skin = {
		all = {
			BrickColor.new("Light orange"),
			BrickColor.new("Dark orange"),
			BrickColor.new("Burnt Sienna"),
			BrickColor.new("Pastel brown"),
			BrickColor.new("Reddish brown"),
			BrickColor.new("Dirt brown"),
			BrickColor.new("Pastel yellow"),
			BrickColor.new("Bright orange"),
		}
	}
}