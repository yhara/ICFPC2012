# coding: utf-8

class LambdaLifter
  class TestMine < Test::Unit::TestCase

    ROBOT_CENTERED_MAP = <<-'EOD'
#####
#   #
# R #
#   #
#####
        EOD

    setup do
      @original_map = <<-'EOD'.freeze
#######
#R\*. #
#####L#
      EOD
      @mine = Mine.new(@original_map)
    end

    should "valid_pos?が呼ばれたとき、マップ範囲内なら真を返す" do
      assert @mine.valid_pos?(Pos[1, 1])
      assert !@mine.valid_pos?(Pos[0, 0])
      assert @mine.valid_pos?(Pos[1, 3])
      assert !@mine.valid_pos?(Pos[1, 4])
      assert !@mine.valid_pos?(Pos[10, 1])
    end

    # 冗長だが、スコアの計算全てに使用する定数なので前提が間違っていな
    # いことを確認。
    should "加算される各スコアがルール通りであること" do
      assert_equal Mine::GIVEN_SCORES[:each_move],              -1
      assert_equal Mine::GIVEN_SCORES[:collect_lambda],         25
      assert_equal Mine::GIVEN_SCORES[:collected_lambda_abort], 25
      assert_equal Mine::GIVEN_SCORES[:collected_lambda_win],   50
    end

    should "マップ定義からシンボルの２次元配列を作れること" do
      desc = <<-'EOD'
#######
#R\*. #
#####L#
      EOD

      expected = [
        [:wall, :wall,  :wall,   :wall, :wall,  :wall,  :wall],
        [:wall, :robot, :lambda, :rock, :earth, :empty, :wall],
        [:wall, :wall,  :wall,   :wall, :wall,  :closed_lift,  :wall],
      ]

      mine = Mine.new(desc)

      assert_equal expected, mine.raw_map
    end

    context "newが呼ばれたとき" do
      should "岩の位置を知っていること" do
        @mine = Mine.new(<<-'EOD')
####
# *#
#R*#
####
        EOD
        assert_equal [Pos.new(3, 3), Pos.new(3, 2)], @mine.rocks
      end

      should "ラムダ入りの岩の位置を知っていること" do
        @mine = Mine.new(<<-'EOD')
####
# @#
#R@#
####
        EOD
        assert_equal [Pos.new(3, 3), Pos.new(3, 2)], @mine.higher_order_rocks
      end

      should "無指定の場合も洪水に関する情報を取得すること" do
        mine = Mine.new(<<-'EOD')
#####
#   #
# R #
#   #
#####
        EOD
        assert_equal 0, mine.water
        assert_equal 0, mine.flooding
        assert_equal 10, mine.waterproof
        assert_equal 0, mine.number_of_flooding
        assert_equal 0, mine.number_of_waterproof
      end

      should "すべて指定された洪水に関する情報を取得すること" do
        mine = Mine.new(<<-'EOD')
###########
#....R....#
#.*******.#
#.\\\\\\\.#
#.       .#
#..*\\\*..#
#.#*\\\*#.#
#########L#

Water 42
Flooding 42
Waterproof 42
        EOD
        assert_equal 42, mine.water
        assert_equal 42, mine.flooding
        assert_equal 42, mine.waterproof
        assert_equal 0, mine.number_of_flooding
        assert_equal 0, mine.number_of_waterproof
      end

      should "洪水の指定されたWaterの情報を取得すること" do
        mine = Mine.new(<<-'EOD')
###########
#....R....#
#.*******.#
#.\\\\\\\.#
#.       .#
#..*\\\*..#
#.#*\\\*#.#
#########L#

Water 42
        EOD
        assert_equal 42, mine.water
        assert_equal 0, mine.flooding
        assert_equal 10, mine.waterproof
        assert_equal 0, mine.number_of_flooding
        assert_equal 0, mine.number_of_waterproof
      end

      should "洪水の指定されたFloodingの情報を取得すること" do
        mine = Mine.new(<<-'EOD')
###########
#....R....#
#.*******.#
#.\\\\\\\.#
#.       .#
#..*\\\*..#
#.#*\\\*#.#
#########L#

Flooding 42
        EOD
        assert_equal 0, mine.water
        assert_equal 42, mine.flooding
        assert_equal 10, mine.waterproof
        assert_equal 0, mine.number_of_flooding
        assert_equal 0, mine.number_of_waterproof
      end

      should "洪水の指定されたWaterproofの情報を取得すること" do
        mine = Mine.new(<<-'EOD')
###########
#....R....#
#.*******.#
#.\\\\\\\.#
#.       .#
#..*\\\*..#
#.#*\\\*#.#
#########L#

Waterproof 42
        EOD
        assert_equal 0, mine.water
        assert_equal 0, mine.flooding
        assert_equal 42, mine.waterproof
        assert_equal 0, mine.number_of_flooding
        assert_equal 0, mine.number_of_waterproof
      end

      should "トランポリンの情報を取得すること" do
        mine = Mine.new(<<-'EOD')
##L###########
#.....R#.**..#
#.*A...#..1..#
#.*....#.  \.#
#.\\\..#...\.#
#2.....**B...#
##############

Trampoline A targets 1
Trampoline B targets 2
        EOD
        trampolines = {:trampoline_a => Pos.new(4, 5),
                       :trampoline_b => Pos.new(10, 2)}
        targets = {:target_1 => Pos.new(11, 5),
                   :target_2 => Pos.new(2, 2)}
        trampoline_relationships = {:trampoline_a => :target_1,
                                    :trampoline_b => :target_2}
        assert_equal trampolines, mine.trampolines
        assert_equal targets, mine.targets
        assert_equal trampoline_relationships, mine.trampoline_relationships
      end

      should "洪水の情報が混ざっていてもトランポリンの情報を取得すること" do
        mine = Mine.new(<<-'EOD')
##L###########
#.....R#.**..#
#.*A...#..1..#
#.*....#.  \.#
#.\\\..#...\.#
#2.....**B...#
##############

Trampoline A targets 1
Waterproof 42
Trampoline B targets 2
        EOD
        trampolines = {:trampoline_a => Pos.new(4, 5),
                       :trampoline_b => Pos.new(10, 2)}
        targets = {:target_1 => Pos.new(11, 5),
                   :target_2 => Pos.new(2, 2)}
        trampoline_relationships = {:trampoline_a => :target_1,
                                    :trampoline_b => :target_2}
        assert_equal 42, mine.waterproof
        assert_equal trampolines, mine.trampolines
        assert_equal targets, mine.targets
        assert_equal trampoline_relationships, mine.trampoline_relationships
      end

      should "ヒゲ、カミソリに関する情報を取得すること" do
        map = <<-'EOD'
########
#.R..  #
#!   .!#
#\\.W. L
########
EOD
        param = <<-'EOD'

Growth 15
Razors 1
        EOD
        mine = Mine.new(map + param)
        assert_equal 15, mine.growth
        assert_equal map, mine.ascii_map
      end
    end

    should "mine[x, y]でその座標にあるものを返すこと" do
      assert_equal :wall, @mine[1, 1] 
      assert_equal :robot, @mine[2, 2] 
      assert_equal :lambda, @mine[3, 2] 
      assert_equal :out_of_map, @mine[0, 0]
    end

    should "hashのkeyとして指定できること" do
      mine2 = Mine.new(<<-'EOD')
#######
#R\*. #
#####L#
      EOD
      assert_equal @mine.hash, mine2.hash
      assert_equal true, @mine.eql?(mine2)

      h = {}
      h[@mine] = true
      h[mine2] = true
      assert_equal 1, h.size
    end

    should "ascii_mapでマップの文字列表現を返すこと" do
      assert_equal @original_map, @mine.ascii_map

      original_map_2 = <<-'EOD'.freeze
####
#RO#
####
      EOD
      mine_2 = Mine.new(original_map_2)
      assert_equal original_map_2, mine_2.ascii_map, "Open Lambda Lift確認"
    end

    context "step!が呼ばれたとき" do
      should "コマンドRでロボットを右に動かすこと" do
        mine = Mine.new(ROBOT_CENTERED_MAP)
        mine.step!("R")
        assert_equal [:wall, :empty, :empty, :robot, :wall], mine.raw_map[2]
      end

      should "コマンドLでロボットを左に動かすこと" do
        mine = Mine.new(ROBOT_CENTERED_MAP)
        mine.step!("L")
        assert_equal [:wall, :robot, :empty, :empty, :wall], mine.raw_map[2]
      end

      should "コマンドUでロボットを上に動かすこと" do
        mine = Mine.new(ROBOT_CENTERED_MAP)
        mine.step!("U")
        assert_equal [:wall, :empty, :robot, :empty, :wall], mine.raw_map[1]
      end

      should "コマンドDでロボットを下に動かすこと" do
        mine = Mine.new(ROBOT_CENTERED_MAP)
        mine.step!("D")
        assert_equal [:wall, :empty, :robot, :empty, :wall], mine.raw_map[3]
      end

      should "コマンドWでロボットが動かないこと" do
        mine = Mine.new(ROBOT_CENTERED_MAP)
        mine.step!("W")
        assert_equal [:wall, :empty, :robot, :empty, :wall], mine.raw_map[2]
      end

      should "コマンドRLでロボットが元の位置に戻ること" do
        mine = Mine.new(ROBOT_CENTERED_MAP)
        mine.step!("R")
        assert_equal [:wall, :empty, :empty, :robot, :wall], mine.raw_map[2]
        mine.step!("L")
        assert_equal [:wall, :empty, :robot, :empty, :wall], mine.raw_map[2]
      end

      should "存在しないコマンドは例外が発生すること" do
        mine = Mine.new(ROBOT_CENTERED_MAP)
        assert_raise(UnknownCommandError) do
          mine.step!("(")
        end
      end

      should "ロボットの移動に成功するとスコアが-1減ること" do
        mine = Mine.new(ROBOT_CENTERED_MAP)
        mine.step!("R")
        assert_equal -1, mine.score
        mine.step!("L")
        assert_equal -2, mine.score
        mine.step!("U")
        assert_equal -3, mine.score
        mine.step!("D")
        assert_equal -4, mine.score
        mine.step!("W")
        assert_equal -4, mine.score
      end

      should "ラムダ上に移動したらスコアが25加算されること" do
        mine = Mine.new(<<-'EOD')
#######
#R\\  #
#####L#
      EOD
        mine.step!("R")
        expected_score = Mine::GIVEN_SCORES[:each_move] +
                         Mine::GIVEN_SCORES[:collect_lambda]
        assert_equal expected_score, mine.score

        mine.step!("R")
        expected_score += Mine::GIVEN_SCORES[:each_move] +
                          Mine::GIVEN_SCORES[:collect_lambda]
        assert_equal expected_score, mine.score
      end

      should "ロボットの移動に伴い岩が移動すること" do
        mine = Mine.new(<<-'EOD')
#######
# *R* #
#######
        EOD
        assert_equal [:wall, :empty, :rock, :robot, :rock, :empty, :wall],
                     mine.raw_map[1]
        assert_equal [Pos[3, 2], Pos[5, 2]], mine.rocks.sort
        mine.step!("L")
        assert_equal [:wall, :rock, :robot, :empty, :rock, :empty, :wall],
                     mine.raw_map[1]
        assert_equal [Pos[2, 2], Pos[5, 2]], mine.rocks.sort
        mine.step!("R")
        mine.step!("R")
        assert_equal [:wall, :rock, :empty, :empty, :robot, :rock, :wall],
                     mine.raw_map[1]
        assert_equal [Pos[2, 2], Pos[6, 2]], mine.rocks.sort
      end

      should "岩が落下すること" do
        mine = Mine.new(<<-'EOD')
R##
#*#
# #
###
        EOD
        assert_equal [:wall, :rock,  :wall], mine.raw_map[1]
        assert_equal [Pos[2, 3]], mine.rocks
        mine.step!("W")
        assert_equal [:wall, :empty, :wall], mine.raw_map[1]
        assert_equal [:wall, :rock,  :wall], mine.raw_map[2]
        assert_equal [Pos[2, 2]], mine.rocks
      end

      should "岩が左右に崩落すること" do
        mine = Mine.new(<<-'EOD')
R#####
#*  *#
#*  *#
######
        EOD
        assert_equal [:wall, :rock, :empty, :empty, :rock, :wall],
                     mine.raw_map[1]
        assert_equal [:wall, :rock, :empty, :empty, :rock, :wall],
                     mine.raw_map[2]
        assert_equal Set[Pos[2, 2], Pos[2, 3], Pos[5, 2], Pos[5, 3]],
                     Set[*mine.rocks]
        mine.step!("W")
        assert_equal [:wall, :empty, :empty, :empty, :empty, :wall],
                     mine.raw_map[1]
        assert_equal [:wall, :rock,  :rock,  :rock,  :rock,  :wall],
                     mine.raw_map[2]
        assert_equal Set[Pos[2, 2], Pos[3, 2], Pos[4, 2], Pos[5, 2]],
                     Set[*mine.rocks]
      end

      should "先にupdateされたlayoutが後のupdateに影響されないこと" do
        mine = Mine.new(<<-'EOD')
R####
#* *#
#* *#
#####
        EOD
        assert_equal [:wall, :rock, :empty, :rock, :wall],
                     mine.raw_map[1]
        assert_equal [:wall, :rock, :empty, :rock, :wall],
                     mine.raw_map[2]
        assert_equal Set[Pos[2, 2], Pos[2, 3], Pos[4, 2], Pos[4, 3]],
                     Set[*mine.rocks]
        mine.step!("W")
        assert_equal [:wall, :empty, :empty, :empty, :wall],
                     mine.raw_map[1]
        assert_equal [:wall, :rock,  :rock,  :rock,  :wall],
                     mine.raw_map[2]
        assert_equal Set[Pos[2, 2], Pos[3, 2], Pos[4, 2]],
                     Set[*mine.rocks]
      end

      should "ラムダの上の岩は右側に崩落すること" do
        mine = Mine.new(<<-'EOD')
R####
# * #
# \ #
#####
        EOD
        assert_equal [:wall, :empty, :rock,   :empty, :wall],
                     mine.raw_map[1]
        assert_equal [:wall, :empty, :lambda, :empty, :wall],
                     mine.raw_map[2]
        assert_equal [Pos[3, 3]], mine.rocks
        mine.step!("W")
        assert_equal [:wall, :empty, :empty,  :empty, :wall],
                     mine.raw_map[1]
        assert_equal [:wall, :empty, :lambda, :rock,  :wall],
                     mine.raw_map[2]
        assert_equal [Pos[4, 2]], mine.rocks
      end

      should "ラムダの上の岩は左側に崩落しないこと" do
        mine = Mine.new(<<-'EOD')
R###
# *#
# \#
####
        EOD
        assert_equal [:wall, :empty, :rock,   :wall],
                     mine.raw_map[1]
        assert_equal [:wall, :empty, :lambda, :wall],
                     mine.raw_map[2]
        assert_equal [Pos[3, 3]], mine.rocks
        mine.step!("W")
        assert_equal [:wall, :empty, :rock,  :wall],
                     mine.raw_map[1]
        assert_equal [:wall, :empty, :lambda, :wall],
                     mine.raw_map[2]
        assert_equal [Pos[3, 3]], mine.rocks
      end

      should "ロボットによる岩の移動と更新による岩の移動は区別されていること" do
        mine = Mine.new(<<-'EOD')
#####
#R* #
# * #
#####
        EOD
        assert_equal [:wall, :robot, :rock,   :empty, :wall],
                     mine.raw_map[1]
        assert_equal [:wall, :empty, :rock,   :empty, :wall],
                     mine.raw_map[2]
        assert_equal [Pos[3, 2], Pos[3, 3]], mine.rocks.sort
        mine.step!("R")
        assert_equal [:wall, :empty, :robot,  :empty, :wall],
                     mine.raw_map[1]
        assert_equal [:wall, :empty, :rock,   :rock,  :wall],
                     mine.raw_map[2]
        assert_equal [Pos[3, 2], Pos[4, 2]], mine.rocks.sort
      end

      should "水位が上昇すること" do
        mine = Mine.new(<<-'EOD')
#####
#   #
# R #
#   #
#####

Water 0
Flooding 1
Waterproof 5
        EOD
        assert_equal 0, mine.water
        mine.step!("L")
        assert_equal 1, mine.water
        mine.step!("R")
        assert_equal 2, mine.water
        mine.step!("L")
        assert_equal 3, mine.water
      end

      should "ロボットが水中に連続でいる回数を数えること" do
        mine = Mine.new(<<-'EOD')
#####
#   #
# R #
#   #
#####

Water 5
Flooding 10
Waterproof 5
        EOD
        mine.step!("R")
        assert_equal 1, mine.number_of_waterproof
        mine.step!("L")
        assert_equal 2, mine.number_of_waterproof
        mine.step!("R")
        assert_equal 3, mine.number_of_waterproof
      end

      should "ロボットが水中から出た時に水中での回数がクリアされること" do
        mine = Mine.new(<<-'EOD')
#####
#   #
#   #
# R #
#####

Water 2
Flooding 10
Waterproof 5
        EOD
        mine.step!("R")
        assert_equal 1, mine.number_of_waterproof
        mine.step!("L")
        assert_equal 2, mine.number_of_waterproof
        mine.step!("U")
        assert_equal 0, mine.number_of_waterproof
      end
    end

    should "ロボットがトランポリンの上に来たらターゲットへ移動すること" do
      mine = Mine.new(<<-'EOD')
#####
#1B #
#   #
#2RA#
#####

Trampoline A targets 1
Trampoline B targets 2
      EOD
      assert_equal 3, mine.robot.x
      assert_equal 2, mine.robot.y
      mine.step!("R")
      assert_equal 2, mine.robot.x
      assert_equal 4, mine.robot.y
      mine.step!("R")
      assert_equal 2, mine.robot.x
      assert_equal 2, mine.robot.y
    end

    should "トランポリンの関連付けが複数の場合は移動後に複数クリアされること" do
      mine = Mine.new(<<-'EOD')
#####
#1B #
#   #
# RA#
#####

Trampoline A targets 1
Trampoline B targets 1
      EOD
      mine.step!("R")

result_map = <<-EOD
#####
#R  #
#   #
#   #
#####
        EOD
      assert_equal result_map, mine.ascii_map
    end

    should "ターゲットはトランポリンから飛ばないと壁なので移動できないこと" do
      mine = Mine.new(<<-'EOD')
#####
#A  #
#   #
# R1#
#####

Trampoline A targets 1
      EOD
      mine.step!("R")

result_map = <<-EOD
#####
#A  #
#   #
# R1#
#####
        EOD
      assert_equal result_map, mine.ascii_map
    end

    should "ラムダの上にRがきたらlamdasは消えること" do
      @mine = Mine.new(<<-'EOD')
#######
#R\*. #
#####L#
      EOD
      @mine.step!("R")
      assert_equal true, @mine.lambdas.empty?
    end

    context "カミソリについて" do
      setup do 
        @mine = Mine.new(<<-'EOD')
#####
#R! #
###\L

Growth 10
Razors 0
        EOD
      end

      should "シンボルの２次元配列が作られること" do
        expected = [:wall, :robot, :razors, :empty, :wall]
        assert_equal expected, @mine.raw_map[1]
      end

      context "Robotが重なった場合" do
        should "@map.razorsが1加算されること" do
          assert_equal 0, @mine.razors
          @mine.step!('R')
          assert_equal 1, @mine.razors
        end

        should "Robotの通過後emptyになること" do
          @mine.step!('R')
          @mine.step!('R')
          expected = [:wall, :empty, :empty, :robot, :wall]
          assert_equal expected, @mine.raw_map[1]
          assert_equal 1, @mine.razors
        end
      end

      context "岩との関係性" do
      setup do
        @mine = Mine.new(<<-'EOD')
R####
# * #
# ! #
###\L

Growth 10
Razors 0
        EOD
        end

        should "カミソリの上の岩は動かないこと" do
          @mine.step!('W')
          expected = [:wall, :empty, :rock, :empty, :wall]
          assert_equal expected, @mine.raw_map[1]
        end
      end
    end

    context "dupが呼ばれたとき" do
      should "内部のmapを複製すること" do
        mine2 = @mine.dup

        assert_equal @mine.raw_map, mine2.raw_map
        assert_not_equal @mine.raw_map.object_id, mine2.raw_map.object_id
      end

      should "内部のrobotを複製すること" do
        mine2 = @mine.dup

        assert_equal @mine.robot, mine2.robot
        assert_not_equal @mine.robot.object_id, mine2.robot.object_id
      end

      should "内部のlambdasを複製すること" do
        mine2 = @mine.dup

        assert_equal @mine.lambdas, mine2.lambdas
        assert_not_equal @mine.lambdas.object_id, mine2.lambdas.object_id
      end

      should "内部のtrampolinesを複製すること" do
        mine = Mine.new(<<-'EOD')
######
#1  A#
#    #
# R  #
######

Trampoline A targets 1
        EOD
        mine2 = mine.dup

        assert_equal mine.trampolines, mine2.trampolines
        assert_not_equal mine.trampolines.object_id,
                         mine2.trampolines.object_id
      end

      should "内部のtargetsを複製すること" do
        mine = Mine.new(<<-'EOD')
######
#1  A#
#    #
# R  #
######

Trampoline A targets 1
        EOD
        mine2 = mine.dup

        assert_equal mine.targets, mine2.targets
        assert_not_equal mine.targets.object_id, mine2.targets.object_id
      end

      should "内部のtrampoline_relationshipsを複製すること" do
        mine = Mine.new(<<-'EOD')
######
#1  A#
#    #
# R  #
######

Trampoline A targets 1
        EOD
        mine2 = mine.dup

        assert_equal mine.trampoline_relationships,
                     mine2.trampoline_relationships
        assert_not_equal mine.trampoline_relationships.object_id,
                         mine2.trampoline_relationships.object_id
      end

      should "その他の情報を複製すること" do
        mine2 = @mine.dup

        assert_equal @mine.width, mine2.width
        assert_equal @mine.height, mine2.height
        assert_equal @mine.lift, mine2.lift
        assert_equal @mine.commands, mine2.commands
        assert_equal @mine.rocks, mine2.rocks
        assert_equal @mine.score, mine2.score
        assert_equal @mine.water, mine2.water
        assert_equal @mine.flooding, mine2.flooding
        assert_equal @mine.number_of_flooding, mine2.number_of_flooding
        assert_equal @mine.waterproof, mine2.waterproof
        assert_equal @mine.number_of_waterproof, mine2.number_of_waterproof
        assert_not_equal @mine.commands.object_id, mine2.commands.object_id
        assert_not_equal @mine.rocks.object_id, mine2.rocks.object_id
        assert_not_equal @mine.lambdas.object_id, mine2.lambdas.object_id
      end
    end

    context "finished?が呼ばれたとき" do
      context ":winingについて" do
        should "勝利条件を満たした場合に:winningを返すこと" do
          mine = Mine.new(<<-'EOD')
#####
#R\L#
#####
        EOD
          mine.step!("R")
          mine.step!("R")
          assert_equal :winning, mine.finished?
        end

      end

      context ":abortについて" do
        should "Aコマンドを使用した場合に:abortを返すこと" do
          mine = Mine.new(<<-'EOD')
#####
#R  #
#####
        EOD
          mine.step!("A")
          assert_equal :abort, mine.finished?
        end

        should "ラムダを1つ回収していた場合、スコアが25加算されること" do
          mine = Mine.new(<<-'EOD')
#####
#R\ #
#####
        EOD
          mine.step!("R")
          before_finished_score = mine.score
          mine.step!("A")
          assert_equal :abort, mine.finished?
          expected_score = Mine::GIVEN_SCORES[:each_move] +
                           Mine::GIVEN_SCORES[:collect_lambda] +
                           Mine::GIVEN_SCORES[:collected_lambda_abort]
          assert_equal expected_score, mine.score
          assert_equal mine.score - before_finished_score,
                       Mine::GIVEN_SCORES[:collected_lambda_abort]
        end

        should "ラムダを2つ回収していた場合、スコアが50加算されること" do
          mine = Mine.new(<<-'EOD')
#####
#R\\#
#####
        EOD
          mine.step!("R")
          mine.step!("R")
          before_finished_score = mine.score
          mine.step!("A")
          assert_equal :abort, mine.finished?
          expected_score = Mine::GIVEN_SCORES[:each_move] * 2 +
                           Mine::GIVEN_SCORES[:collect_lambda] * 2 +
                           Mine::GIVEN_SCORES[:collected_lambda_abort] * 2
          assert_equal expected_score, mine.score
          assert_equal mine.score - before_finished_score,
                       Mine::GIVEN_SCORES[:collected_lambda_abort] * 2
        end
      end

      context ":losingについて" do
        should "ロボットが移動してマップ更新後、ロボットの頭上にある岩が移動していた場合は:losing" do
          mine = Mine.new(<<-'EOD')
###
#*#
# #
#R#
###
          EOD
          mine.step!("W")
          assert_equal :losing, mine.finished?

          mine = Mine.new(<<-'EOD')
###
#*#
#R#
# #
###
          EOD
          mine.step!("D")
          assert_equal :losing, mine.finished?

          mine = Mine.new(<<-'EOD')
#####
#*  #
#*  #
#. R#
#####
          EOD
          mine.step!("L")
          assert_equal :losing, mine.finished?
        end

        should "ロボットが移動してマップ更新後、ロボットの頭上に岩があってもその岩が移動していない場合はfalse" do
          mine = Mine.new(<<-'EOD')
###
#*#
# #
#R#
###
          EOD
          mine.step!("U")
          assert_equal false, mine.finished?

          mine = Mine.new(<<-'EOD')
###
#*#
#R#
# #
###
          EOD
          mine.step!("W")
          assert_equal false, mine.finished?
        end
      end

      should "falseを返すこと" do
        mine = Mine.new(<<-'EOD')
#####
#R  #
#####
        EOD
        assert_equal false, mine.finished?
      end
    end

    should "サンプルのmap2の正答手順実施後のレイアウトが問題ないこと" do
      mine = Mine.new(<<-'EOD')
#######
#..***#
#..\\\#
#...**#
#.*.*\#
LR....#
#######
        EOD

      "RRUDRRULURULLLLDDDL".each_char do |cmd|
        mine.step!(cmd)
      end

result_map = <<-EOD
#######
#..   #
#  *  #
# ..  #
#   **#
R ****#
#######
        EOD
      assert_equal result_map, mine.ascii_map
      assert_equal 281, mine.score
      # TODO: 勝利条件の判定
    end

    context "scoreが呼ばれたとき" do
      setup do 
        @mine = Mine.new(<<-'EOD')
#####
# R\L
#####
        EOD
      end

      should "初期状態では0点であること" do
        assert_equal 0, @mine.score
      end

      should "1手動くごとに1点減ること" do
        @mine.step!("L")
        assert_equal -1, @mine.score
      end

      should "Waitしたときに1点減ること" do
        pend
        @mine.step!("W")
        assert_equal -1, @mine.score
      end

      should "無理な方向に移動しようとしたきに1点減ること" do
        pend
        @mine.step!("U")
        assert_equal -1, @mine.score
      end

      should "ラムダ1つにつき25点が入ること" do
        @mine.step!("R")
        assert_equal 25 - 1, @mine.score
      end

      should "Abort時、ラムダ1つにつき25点が入ること" do
        @mine.step!("R")
        @mine.step!("A")
        assert_equal (25 - 1) + 25, @mine.score
      end

      should "winning時、ラムダ1つにつき50点が入ること" do
        @mine.step!("R")
        @mine.step!("R")
        assert_equal (25 - 1 - 1) + 50, @mine.score
      end
    end
  end
end
