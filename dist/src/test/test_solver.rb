# coding: utf-8
class LambdaLifter
  class TestSolver < Test::Unit::TestCase
    include Solver::Util

    should "mini1.mapという回答不可能な小さいマップがハイスコアでabortすること" do
      desc = <<-'EOD'.freeze
######
#  *R#
L* .\#
######
      EOD
      m = Mine.new(desc)
      s = Solver.new(m)
      # ハイスコア状態でabort
      assert_equal "DA", s.solve
    end

    should "mini2.mapという回答可能な小さいマップが解けること" do
      desc = <<-'EOD'.freeze
######
#.* R#
L ..\#
######
      EOD
      m = Mine.new(desc)
      s = Solver.new(m)
      # ハイスコア状態でabort
      assert_equal "DLLLL", s.solve
    end

    should "solveでSIGINTを受け取ったとき@solverがnilでも動作する" do
      desc = <<-'EOD'.freeze
#######
#..***#
#..\\\#
#...**#
#.*.*\#
LR....#
#######
      EOD
      m = Mine.new(desc)
      s = Solver.new(m)
      s.instance_variable_set(:@solver, nil)
      s.send(:handle_sigint)
      assert_equal true, s.instance_variable_get(:@trapped_sigint)
    end

# exit 0 を呼ぶためコメントアウト
#     should "solveでSIGINTを受け取ったとき@solverがnilでも動作する" do
#
#       desc = <<-'EOD'.freeze
# #######
# #..***#
# #..\\\#
# #...**#
# #.*.*\#
# LR....#
# #######
#       EOD
#       m = Mine.new(desc)
#       s = Solver.new(m)
#       s.instance_variable_set(:@solver, nil)
#       s.send(:handle_sigint)
#       assert_equal true, s.instance_variable_get(:@trapped_sigint)
#     end

    context "マンハッタン探索のソルバは" do
      should "limit_commands_exceeded?がサイズオーバーの時にtrueを返す" do
        desc = <<-'EOD'.freeze
###
LR#
###
      EOD
        m = Mine.new(desc)
        s = Solver::DrFoolishManhattan.new(m)
        s.instance_variable_set(:@commands, (0..(m.width * m.height+1)).map.to_a)
        assert_equal true, s.send(:limit_commands_exceeded?)
      end

      should "solve_to_checkpointでcheckpointまでの経路をA*探索で導くこと" do
        desc = <<-'EOD'.freeze
######
#. *R#
#  \.#
#\ * #
L  .\#
######
      EOD
        m = Mine.new(desc)
        s = Solver::DrFoolishManhattan.new(m)
        assert_equal true, s.send(:solve_to_checkpoint, Pos.new(5, 2))
      end
    end

    context "確実に到達不可能な地点を見つけるとき" do
      include Solver::FindUnreachable

      should "ある地点が到達不能と仮定して、囲まれていることを判定できること" do
        m = Mine.new(<<-'EOD')
R    *#
#   *\#
#######
        EOD
        assert_equal true, closed_with_static_objects?(m, m.lambdas.first, m.robot.pos)

        m = Mine.new(<<-'EOD')
##### 
#   ###
#     #
# R** #
# *.\*#
#**  *#
#######
        EOD
        assert_equal true, closed_with_static_objects?(m, m.lambdas.first, m.robot.pos)

        m = Mine.new(<<-'EOD')
##### 
#   ###
#   * #
# R*\*#
# ****#
#*****#
#######
        EOD
        assert_equal false, closed_with_static_objects?(m, m.lambdas.first, m.robot.pos)

      end

      should "ある地点が到達不能と仮定して、囲まれていないことを判定できること" do
        m = Mine.new(<<-'EOD')
R   * #
#  *\*#
#######
        EOD
        assert_equal false, closed_with_static_objects?(m, m.lambdas.first, m.robot.pos)

        m = Mine.new(<<-'EOD')
##### 
#   ###
#   * #
# R* *#
# *.\ #
#**  *#
#######
        EOD
        assert_equal false, closed_with_static_objects?(m, m.lambdas.first, m.robot.pos)

        m = Mine.new(<<-'EOD')
##### 
#   ###
#   * #
# R*\*#
#  ***#
#     #
#######
        EOD
        assert_equal false, closed_with_static_objects?(m, m.lambdas.first, m.robot.pos)
      end

      should "トランポリンがあるときに、囲まれていないことを判定できること" do
        m = Mine.new(<<-'EOD')
#######
# R A #
#######
# 1 \ #
#######

Trampoline A targets 1
        EOD
        assert_equal false, closed_with_static_objects?(m, m.lambdas.first, m.robot.pos)
      end

      should "トランポリンがあるときに、囲まれていることを判定できること" do

        m = Mine.new(<<-'EOD')
#######
# R 1 #
#######
# A \ #
#######

Trampoline A targets 1
        EOD
        assert_equal true, closed_with_static_objects?(m, m.lambdas.first, m.robot.pos)
      end

      should "contest8で無限ループにならないこと" do
        m = Mine.new(<<-'EOD')
##############       
#\\... ......#       
###.#. ...*..#       
  #.#. ... ..#       
### #.   \ ..#       
#. .#..... **####### 
#.#\#..... ..\\\*. # 
#*\\#.###. ####\\\ # 
#\\.#.     ...## \ # 
#\#.#..... ....# \ # 
###.#..... ....#   ##
#\\.#..... ....#\   #
########.. ..###*####
#......... .........#
#......... ....***..#
#..\\\\\ # ####.....#
#........*R..\\\   .#
##########L##########
        EOD
        assert_equal false, closed_with_static_objects?(m, m.lambdas.first, m.robot.pos)
      end
    end

    should "poss_from_toは壁を考慮しないfromからtoまでのposを返す" do
        m = Mine.new(<<-'EOD')
####### 
#     #
#   * #
#*R*\*#
#  ***#
#  #  #
#######
        EOD
      assert_equal([Pos[3, 2], Pos[3, 3], Pos[4, 3],
        Pos[4, 4], Pos[5, 4], Pos[5, 5]],
        poss_from_to(m, Pos[2, 2], Pos[6, 5]))
      assert_equal([Pos[3, 2], Pos[3, 3], Pos[4, 3],
        Pos[4, 4], Pos[5, 4], Pos[5, 5]].reverse,
        poss_from_to(m, Pos[6, 5], Pos[2, 2]))
      assert_equal([Pos[3, 2], Pos[4, 2]],
        poss_from_to(m, Pos[2, 2], Pos[5, 2]))
    end

    should "wall_cnt_from_toはfromからtoまでの直線上の壁の数を返す" do
      m = Mine.new(<<-'EOD')
####### 
# #   #
#   * #
#*R*###
####**#
#  ## #
#######
        EOD
      s = Solver::DrFoolishManhattan.new(m)
      
      assert_equal(2, s.wall_cnt_from_to(Pos[2, 2], Pos[6, 2]))
    end

    should "calc_distance_mapは指定位置からの距離マップを作成する" do
      m = Mine.new(<<-'EOD')
####### 
# #    
#   * #
#*R*###
##  **#
#  #  #
#######
        EOD
      s = Solver::DrFoolishManhattan.new(m)
      map = s.calc_distance_map(Pos[2, 2])
      assert_equal 0, map[2][2]
      assert_equal 8, map[6][2]
      assert_equal 8, map[6][6]

      desc = <<-'EOD'.freeze
############
#..*.R..*..#
#..A....B..######
#....2.. ..#\\\C#
#......* *.#\\\1#
########L########

Trampoline A targets 1
Trampoline B targets 1
Trampoline C targets 2
      EOD
      m = Mine.new(desc)
      s = Solver::DrFoolishManhattan.new(m)
      map = s.calc_distance_map(Pos[15, 2])
      assert_equal 1, map[4][4]
      assert_equal 2, map[4][5]
    end
  end
end
