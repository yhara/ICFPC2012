class LambdaLifter
  def self.run
    mine = Mine.new(ARGF.read)
    solver = Solver.new(mine)
    print solver.solve
  end
end

require_relative 'lambda_lifter/pos'
require_relative 'lambda_lifter/solver'
require_relative 'lambda_lifter/mine'
require_relative 'lambda_lifter/robot'
