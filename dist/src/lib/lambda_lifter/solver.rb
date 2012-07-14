# -*- coding: utf-8 -*-
class LambdaLifter
  class Solver
    def initialize
      @started_at = Time.now
      @visited = {}
    end

    def solve(mine)
      @current_mine = mine
      @sequence = []

      # mine.robot_pos
      robot = Pos.new(2, 2)
      # mine.lambda_postions
      lambdas = [Pos.new(5, 5), Pos.new(2, 5)]
      while !lambdas.empty?
        next_lambda_idx = nearest_point_index(lambdas, robot)
        break if next_lambda_idx.nil?
        next_lambda = lambdas.delete_at(next_lambda_idx)

        robot = next_pos(robot, next_lambda)
        # TODO: limitを設ける
        while robot != next_lambda
          robot = next_pos(robot, next_lambda)
        end
      end

      return @sequence
    end

    private
    # 指定位置への最短距離のポイントのindexを返す。
    def nearest_point_index(points, goal)
      return nil if points.empty?
      return 0 if points.size == 1
      return points.map.with_index{|point, i|
        [((goal.x - point.x).abs + (goal.y - point.y).abs), i]
      }.sort_by{|interval, _| interval }.first[1]
    end

    def next_pos(robot, goal)
      am = available_moves(robot)
      next_move_idx = nearest_point_index(am, goal)
      if next_move_idx.nil?
        raise "You don't move anywhere."
      end
      next_position = am.delete_at(next_move_idx)
      @visited[next_position] = true
      @sequence << next_position
      return next_position
    end

    def available_moves(robot)
      # TODO: 壁、危険な位置、範囲による移動の制限
      am = [
        Pos.new(robot.x+1, robot.y),
        Pos.new(robot.x-1, robot.y),
        Pos.new(robot.x, robot.y+1),
        Pos.new(robot.x, robot.y-1),]
      return am.select{|a| @visited[a].nil? }.
        select{|a| a.x >= 1 && a.y >= 1 && a.x <= 5 && a.y <= 5 }
        # TODO:暫定的な範囲
    end
  end
end
