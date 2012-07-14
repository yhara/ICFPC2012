class LambdaLifter
  def self.run
    solver = Solver.new
    mine = Mine.new
    solver.solve(mine)
  end
end

require_relative 'lambda_lifter/pos'
require_relative 'lambda_lifter/solver'
require_relative 'lambda_lifter/mine'

if $0 == __FILE__
  # TODO: LambdaLifter.run
  puts("A")
end
