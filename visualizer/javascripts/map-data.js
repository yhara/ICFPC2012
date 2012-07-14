// 記号が表すもの
//
//       R => Robot
//       # => Wall
//       . => Earch
//       L => Closed-Lift
//       * => Rock
//       / => Lambda (本当は\)
// [SPACE] => Empty
//

var MapData = {
  sample1: [["######"],
	    ["#. *R#"],
	    ["#  /.#"],
	    ["#/ * #"],
	    ["L  ./#"],
	    ["######"]
	   ].join("\n"),

  sample2: [["#######"],
	    ["#..***#"],
	    ["#..///#"],
	    ["#...**#"],
	    ["#.*.*/#"],
	    ["LR....#"],
	    ["#######"]
	   ].join("\n"),

  sample3: [["########"],
	    ["#..R...#"],
	    ["#..*...#"],
	    ["#..#...#"],
	    ["#././..L"],
	    ["####**.#"],
	    ["#/.....#"],
	    ["#/..* .#"],
	    ["########"]
	   ].join("\n"),

  sample4: [["#########"],
	    ["#.*..#/.#"],
	    ["#./..#/.L"],
	    ["#.R .##.#"],
	    ["#./  ...#"],
	    ["#../  ..#"],
	    ["#.../  ##"],
	    ["#..../ /#"],
	    ["#########"]
	   ].join("\n"),

  sample5: [["############"],
	    ["#..........#"],
	    ["#.....*....#"],
	    ["#..//////..#"],
	    ["#.     ....#"],
	    ["#..///////.#"],
	    ["#../..    .#"],
	    ["#../.. ....#"],
	    ["#..... ..* #"],
	    ["#..### ### #"],
	    ["#...R#/#//.#"],
	    ["######L#####"]
	   ].join("\n"),

  sample6: [["###############"],
	    ["#///.......** #"],
	    ["#//#.#####...##"],
	    ["#//#.....*##. #"],
	    ["#/#####/...## #"],
	    ["#/......####* #"],
	    ["#/.######* #./#"],
	    ["#/.#. *...##.##"],
	    ["#/##. ..  *...#"],
	    ["#/...... L#.#.#"],
	    ["###########.#.#"],
	    ["#/..........#.#"],
	    ["##.##########.#"],
	    ["#R.#/.........#"],
	    ["###############"]
	   ].join("\n"),

  sample7: [["    #######"],
	    ["    ##    *#"],
	    ["     ##R  *##"],
	    ["      ##////##"],
	    ["       ##....##"],
	    ["      ##../ . ##"],
	    ["     ## . L .  ##"],
	    ["    ##///# #////##"],
	    ["   ######   #######"]
	   ].join("\n"),

  sample8: [["##############"],
	    ["#//... ......#"],
	    ["###.#. ...*..#"],
	    ["  #.#. ... ..#"],
	    ["### #.   / ..#"],
	    ["#. .#..... **#######"],
	    ["#.#/#..... ..///*. #"],
	    ["#*//#.###. ####/// #"],
	    ["#//.#.     ...## / #"],
	    ["#/#.#..... ....# / #  "],
	    ["###.#..... ....#   ##"],
	    ["#//.#..... ....#/   # "],
	    ["########.. ..###*####"],
	    ["#......... .........#"],
	    ["#......... ....***..#"],
	    ["#..///// # ####.....#"],
	    ["#........*R..///   .#"],
	    ["##########L##########"]
	   ].join("\n"),

  sample9: [["        #L#######"],
	    ["        #*** // #"],
	    ["        #/// .. #"],
	    ["#########.##    ##########"],
	    ["#......./ ..........*   .#"],
	    ["#*******/......#....#// .#"],
	    ["###/.///...**..#....... *#"],
	    ["#*****//  .//..##     #/.#"],
	    ["######### ....  ##########"],
	    ["        #       #"],
	    ["        ####*####      "],
	    ["        #.......#"],
	    ["#########  ////*##########"],
	    ["#*//  **#     *..*/ /////#"],
	    ["#./**/*** .....**.# //##/#"],
	    ["#/R......     .//.. /////#"],
	    ["##########################"]
	   ].join("\n"),

  sample10: [["#############################"],
	     ["#........................../#"],
	     ["#..//###...#....        ###.#"],
	     ["#../*///.. #.... ..##//../#.#"],
	     ["#../*/.... #.... ..#/#....#.#"],
	     ["#.../###.. #.... ....#....#.#"],
	     ["#... ..... ..... .####......#"],
	     ["#//. #....           .......#"],
	     ["#... #..#. .....*/ ##.......#"],
	     ["#.#....... ...#..  ....######"],
	     ["#. ...#... ...#./  ....#..* #"],
	     ["##........ ...#.. #....#.#//#"],
	     ["#.....*... .....*/#//.....*.#"],
	     ["#.***.* .......*/****.....#.#"],
	     ["#.///.. ................   .#"],
	     ["#.#####    .######    ##### #"],
	     ["#....//.................... #"],
	     ["#....****...#.##.....////../#"],
	     ["#....////...#.........*..../#"],
	     ["#....////...#.//.    #/###./#"],
	     ["#....     ..#.... ...#////. #"],
	     ["#........ ..#.... ...#..... #"],
	     ["#........         ........#R#"],
	     ["###########################L#"]
	     ].join("\n")
};
