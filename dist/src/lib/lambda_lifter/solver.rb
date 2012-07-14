# -*- coding: utf-8 -*-
class LambdaLifter
  class Solver
    def initialize(mine)
      @mine = mine
      @started_at = Time.now
      @cmdqueue = []
      @memo = {}
      # TODO: ハイスコアを一緒に覚えておきSIGINTが送られたらその命令列
      # を送る
      @highscore = nil
    end

    # コマンドの列を文字列で返す。
    # 例："DLLRA"
    def solve
      while next_goal = find_next_goal
        next_pos = nil
        while next_pos != next_goal
          cmd = judge_next_command(next_goal)
          if cmd 
            @cmdqueue << cmd
            @mine.step!(cmd)
            rollback! if @mine.losing?
            @memo[@cmdqueue] = @mine.dup
          else
            # 実行可能なコマンドがない
            rollback!
          end
          next_pos = @mine.robot.pos
        end
      end
      return @cmdqueue.join
    end

    private
    # 次の目的地を探す
    # TODO: すでに試した場所だったら異なるnext_goalを設定
    # TODO: 簡単わかる無理そうなlambdaを検出する
    #       (たとえば岩にふさがっているものなど）
    # TODO: finished?になってもよりよいスコアを求める
    def find_next_goal
      return nil if @mine.finished?
      next_goal = nearest_point(@mine.lambdas, @mine.robot.pos)
      next_goal = @mine.lift if next_goal.nil?
      return next_goal
    end

    # 次のrobotの命令を判断
    # 今のところ直線の最短距離のみ
    # TODO: 障害物も考慮した最短距離にしたい
    #       命令が制限を超えるようなケース
    def judge_next_command(goal)
      next_position = nearest_point(movable_positions(@mine.robot), goal)
      return nil if next_position.nil?
      return @mine.robot.command_to(next_position)
    end

    # 指定位置への最短距離のポイントを返す。
    def nearest_point(points, goal)
      return nil if points.empty?
      return points.first if points.size == 1
      index = points.map.with_index{|point, i|
        [((goal.x - point.x).abs + (goal.y - point.y).abs), i]
      }.sort_by{|interval, _| interval }.first[1]
      return nil if index.nil?
      return points[index]
    end

    # 移動可能な位置
    def movable_positions(robot)
      return (robot.movable_positions + robot.pos).
        select{|a| possible_route?(@cmdqueue + robot.command_to(a)) }
    end

    # 1つ前のmineにロールバック
    def rollback!
      @cmdqueue.pop
      @mine = @memo[@cmdqueue]
    end

    def possible_route?(cmdqueue)
      return false if @memo[cmdqueue] == false
      return true
    end
  end
end
