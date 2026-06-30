class_name Levels
## Hand-authored levels as ASCII grids. Each entry: { name, [unlock], grid }.
## See level.gd for the tile legend. These are deliberately simple starting
## rooms — open them in the editor's running game and tweak freely.

const DATA := [
	{
		"name": "1-1  First Steps",
		"grid": [
			"                                ",
			"                                ",
			"            CCC                 ",
			"          ########              ",
			"                                ",
			"        C           C           ",
			"     ######      ######         ",
			"                                ",
			" P                          E   ",
			"#####   #####   #####   ########",
			"#####   #####   #####   ########",
			"#####   #####   #####   ########",
		],
	},
	{
		"name": "1-2  Higher Ground",
		"unlock": "double",
		"grid": [
			"                            E   ",
			"                         ###### ",
			"                                ",
			"                   ########      ",
			"             C                  ",
			"          #######               ",
			"                      #####     ",
			"      C                         ",
			"    #######        K            ",
			"                #######         ",
			"         #####                  ",
			"  C                             ",
			" P                              ",
			"################################",
		],
	},
	{
		"name": "1-3  Dash Across",
		"unlock": "dash",
		"grid": [
			"                                ",
			"          S                     ",
			"        #######                 ",
			"                                ",
			"              C                 ",
			"    C                      C    ",
			"                                ",
			" P  K                       E   ",
			"######  XXXX  ######  XXXX  #####",
			"######        ######        #####",
			"######  ^^^^  ######  ^^^^  #####",
			"################################",
		],
	},
]
