# coding: utf-8
class LambdaLifter
  class TestSolver < Test::Unit::TestCase
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
      s.solve
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

    should "limit_commands_exceeded?がサイズオーバーの時にtrueを返す" do
      desc = <<-'EOD'.freeze
###
LR#
###
      EOD
      m = Mine.new(desc)
      s = Solver.new(m)
      s.instance_variable_set(:@commands, (0..(m.width * m.height+1)).map.to_a)
      assert_equal true, s.send(:limit_commands_exceeded?)
    end

    should "contest1.mapのsolve" do
      desc = <<-'EOD'.freeze
######
#. *R#
#  \.#
#\ * #
L  .\#
######
      EOD
      m = Mine.new(desc)
      s = Solver.new(m)
      assert_equal "LDLLDRRDRLULLDL", s.solve
    end

    should "contest3.mapのsolve" do
      pend
      desc = <<-'EOD'.freeze
########
#..R...#
#..*...#
#..#...#
#.\.\..L
####**.#
#\.....#
#\..* .#
########
      EOD
      m = Mine.new(desc)
      s = Solver.new(m)
      assert_equal "LDLLDRRDRLULLDL", s.solve
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
      s = Solver.new(m)
      assert_equal true, s.send(:solve_to_checkpoint, Pos.new(5, 2))
    end

    should "contest2.mapのsolve" do
      pend
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
      assert_equal "LDLLDRRDRLULLDL", s.solve
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
    end
  end
end
