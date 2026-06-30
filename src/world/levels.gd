class_name Levels
## Levels grouped into themed worlds. Each world carries a colour theme used
## for its sky/parallax background and tile tint; flat() flattens the worlds
## into the linear list Game progresses through (and tags each level with its
## world + theme + flat_index).
##
## Tile legend:
##   #  solid      P  spawn      E  exit       C  coin      S  secret star
##   ^  spikes     K  checkpoint X  crumble    O  spring    G  bonus gem
##   B  blob enemy -  h-platform | v-platform  @  gravity portal

static func worlds() -> Array:
	return [
		{
			"name": "Jelly Meadows",
			"theme": {
				"sky_top": Color(0.42, 0.70, 0.96),
				"sky_bottom": Color(0.78, 0.92, 0.82),
				"tile": Color(0.34, 0.66, 0.42),
				"accent": Color(1.0, 0.95, 0.6),
			},
			"levels": [
				{
					"name": "Hello Bouncy World",
					"grid": [
						"                                ",
						"                                ",
						"              S                 ",
						"            #######             ",
						"                                ",
						"       C    C    C              ",
						"                                ",
						"                     C   C      ",
						"          O                     ",
						" P       ####          ####   E ",
						"################################",
						"################################",
					],
				},
				{
					"name": "Spring Fling",
					"grid": [
						"                                ",
						"                       G        ",
						"                    #######     ",
						"          S                     ",
						"        #######                 ",
						"                                ",
						"    O           O               ",
						"   ####        ####         E   ",
						" P                ^^^      #####",
						"################################",
						"################################",
					],
				},
				{
					"name": "Double Trouble",
					"unlock": "double",
					"grid": [
						"                            E   ",
						"                         ###### ",
						"                                ",
						"              S                 ",
						"           #######              ",
						"                   G            ",
						"      C        #######          ",
						"   #######                      ",
						"          C                     ",
						" P   O                          ",
						"################################",
						"################################",
					],
				},
				{
					"name": "Meadow Finale",
					"grid": [
						"                                ",
						"        S                       ",
						"      ######                    ",
						"                    G           ",
						"                 ######         ",
						"    O        O                  ",
						"   ###      ###       O         ",
						" P     ^^^^      ^^^^ ###     E ",
						"################################",
						"################################",
					],
				},
			],
		},
		{
			"name": "Bubblegum Caverns",
			"theme": {
				"sky_top": Color(0.24, 0.16, 0.40),
				"sky_bottom": Color(0.52, 0.30, 0.60),
				"tile": Color(0.56, 0.34, 0.64),
				"accent": Color(1.0, 0.60, 0.88),
			},
			"levels": [
				{
					"name": "Cave-In",
					"grid": [
						"                                ",
						"                                ",
						"            S                   ",
						"          ######                ",
						"                     G          ",
						"                  -             ",
						"     C       C        C         ",
						"                                ",
						" P     B          B          E  ",
						"################################",
						"################################",
					],
				},
				{
					"name": "Dash Dash Dash",
					"unlock": "dash",
					"grid": [
						"                                ",
						"          S                     ",
						"        ######                  ",
						"                       G        ",
						"                    ######      ",
						"     C      C       C           ",
						"                                ",
						" P    ^^^^^^^^      B        E  ",
						"################################",
						"################################",
					],
				},
				{
					"name": "Blob Bash",
					"grid": [
						"                                ",
						"                      G         ",
						"                   ######       ",
						"         S                      ",
						"       ######                   ",
						"                                ",
						"    O        B       O      C   ",
						"   ###      ###     ###         ",
						" P      B        B          E   ",
						"################################",
						"################################",
					],
				},
				{
					"name": "Cavern Crawl",
					"grid": [
						"                                ",
						"        S                       ",
						"      ######          G         ",
						"                   ######       ",
						"    -          B                ",
						"            ######              ",
						"  C     K          O       C    ",
						"       ####       ###           ",
						" P  ^^^      B         ^^^   E  ",
						"################################",
						"################################",
					],
				},
			],
		},
		{
			"name": "Gravity Lab",
			"theme": {
				"sky_top": Color(0.05, 0.14, 0.20),
				"sky_bottom": Color(0.10, 0.30, 0.34),
				"tile": Color(0.20, 0.46, 0.52),
				"accent": Color(0.40, 1.0, 0.90),
			},
			"levels": [
				{
					"name": "Upside Down",
					"grid": [
						"                                ",
						"      ##############            ",
						"      C   C   G  @ C            ",
						"                                ",
						"         S                      ",
						"                                ",
						"   C            C          C    ",
						" P     @                     E  ",
						"################################",
						"################################",
					],
				},
				{
					"name": "Flip Out",
					"grid": [
						"                                ",
						"   ###############              ",
						"   C    @     C   G             ",
						"                                ",
						"          S          C          ",
						"                                ",
						"   C        B         C    C    ",
						" P    @          ^^^      B   E ",
						"################################",
						"################################",
					],
				},
				{
					"name": "Lab Rats",
					"grid": [
						"                                ",
						"      ##############            ",
						"   G  C   @    C   C @          ",
						"                                ",
						"        S         -             ",
						"                                ",
						"    C       B          C        ",
						" P     @        B       @     E ",
						"################################",
						"################################",
					],
				},
				{
					"name": "The Final Descent",
					"grid": [
						"                                ",
						"    #################           ",
						"    C   @   G   C   @           ",
						"                                ",
						"        S        B              ",
						"      ######                    ",
						"  C      K     O        C       ",
						"        ###   ###               ",
						" P  ^^^    @    B    ^^^  @   E ",
						"################################",
						"################################",
					],
				},
			],
		},
		{
			"name": "Devil's Playground",
			"theme": {
				"sky_top": Color(0.16, 0.04, 0.07),
				"sky_bottom": Color(0.34, 0.07, 0.10),
				"tile": Color(0.50, 0.18, 0.20),
				"accent": Color(1.0, 0.40, 0.32),
			},
			"levels": [
				{
					"name": "Trust Issues",
					"grid": [
						"                                ",
						"          S                     ",
						"        ######                  ",
						"                                ",
						"     C      C       C    G      ",
						"                                ",
						"                                ",
						"                                ",
						" P    ?                     E   ",
						"####ff###f####ff##f###ff###f####",
						"^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^",
						"################################",
					],
				},
				{
					"name": "Pop Quiz",
					"grid": [
						"                                ",
						"   !        !          !        ",
						"                                ",
						"          S          G          ",
						"        ######     ######       ",
						"                                ",
						"     C        C         C       ",
						"                                ",
						" P    v     v      v     v    E ",
						"################################",
						"################################",
					],
				},
				{
					"name": "The Devil's Descent",
					"grid": [
						"                                ",
						"       !          !             ",
						"        S              G        ",
						"      ######        ######      ",
						"                                ",
						"   C       C          C         ",
						"                                ",
						"                                ",
						" P  v      v   ?    v        E  ",
						"###ff####f#####ff###f####ff#####",
						"^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^",
						"################################",
					],
				},
			],
		},
	]

static func world_count() -> int:
	return worlds().size()

## Flattened, progression-ordered level list. Each entry is its level dict plus
## "world", "world_name", "theme", and "flat_index".
static func flat() -> Array:
	var out: Array = []
	var ws := worlds()
	for wi in ws.size():
		var w: Dictionary = ws[wi]
		for lv in w["levels"]:
			var e: Dictionary = (lv as Dictionary).duplicate(true)
			e["world"] = wi
			e["world_name"] = w["name"]
			e["theme"] = w["theme"]
			e["flat_index"] = out.size()
			out.append(e)
	return out
