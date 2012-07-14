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
      lambdas = [Pos.new(10, 10), Pos.new(2, 10)]
      while !lambdas.empty?
        next_lambda_idx = nearest_point_index(robot, lambdas)
        break if next_goal_idx.nil?
        next_lambda = lambdas.delete_at(goal_idx)

        next_pos = next_pos(robot, next_lambda)
        # TODO: limitを設ける
        while next_pos != next_lambda
          next_pos = next_pos(robot, next_lambda)
        end
      end

      return @sequence
    end

    # return index
    def nearest_point_index(cur, points)
      return nil if points.empty?
      return 0 if points.size == 1
      return points.map.with_index{|point, i|
        [point.x - cur.x + point.y - cur.y, i]
      }.sort_by{|interval, _| interval }.first[1]
    end

    def next_pos(robot, next_pos)
      am = available_moves(robot)
      next_move_idx = nearest_point_index(robot, am)
      raise "You don't move anywhere." if next_move_idx.nil?
      next_point = am.delete_at(next_move_idx)
      @visited[next_position.to_s] = true
      @sequence << next_position
      return next_point
    end

    def available_moves(robot)
      # TODO: 壁、危険な位置、範囲による移動の制限
      am = [
        [robot[0]+1, robot[1]],
        [robot[0]-1, robot[0]],
        [robot[0], robot[1]+1],
        [robot[0], robot[1]-1],]
      return am.select{|a| @visited[a.to_s].nil? }
    end
  end
end
