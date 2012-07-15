require "logger"

class LambdaLifter
  def self.run
    mine = Mine.new(ARGF.read)
    solver = Solver.new(mine)
    print solver.solve
  end

  def self.logger
    if debug?
      @@logger ||= Logger.new(nil)
    else
      @@logger ||= Logger.new("log/debug.log")
    end
    return @@logger
  end

  def self.debug?
    !!ENV["DEBUG"]
  end
end

require_relative 'lambda_lifter/pos'
require_relative 'lambda_lifter/solver'
require_relative 'lambda_lifter/mine'
require_relative 'lambda_lifter/robot'
