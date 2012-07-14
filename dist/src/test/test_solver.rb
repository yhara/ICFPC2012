# coding: utf-8
class LambdaLifter
  class TestSolver < Test::Unit::TestCase
    should "solveはA∗探索でlambdaへ向かう:まだ値は決め打ち..." do
      except = [[2, 3], [2, 4], [2, 5], [3, 5], [4, 5], [5, 5]].map do |x, y|
        Pos.new(x, y)
      end
      assert_equal except, LambdaLifter::Solver.new.solve(nil)
    end
  end
end
