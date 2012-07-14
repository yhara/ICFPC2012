# -*- coding: utf-8 -*-
class LambdaLifter
  class Solver
    def initialize(mine)
      @mine = mine
      @cmdqueue = []
      # TODO: メモリサイズの懸念。ある程度のサイズになったらtruncateすべき。
      @cmd_mine_cache = {}
      @dead_cmd_route = {}
      @checkpoint_watermarks = []
      @checkpoint_route = []
      @dead_checkpoint_route = {}
      # TODO: ハイスコアを一緒に覚えておきSIGINTが送られたらその命令列
      # を送る。"A"が必要なものか、それ以外のものかを区別。
      @highscore = []
      @trapped_sigint = false
      Signal.trap(:INT){ handle_sigint }
    end

    # コマンドの列を文字列で返す。
    # 例："DLLRA"
    def solve
      loop do
        # TODO: finished?になってもよりよいスコアを求める
        return @cmdqueue.join if @mine.finished?
        checkpoint = find_checkpoint
        return highscore if not checkpoint
        is_solved = solve_to_checkpoint(checkpoint)
        checkpoint!(checkpoint) if is_solved
      end
    end

    private
    # checkpointまでの経路を解く
    def solve_to_checkpoint(checkpoint)
      next_pos = nil
      while next_pos != checkpoint
        return highscore if @trapped_sigint
        cmd = judge_next_command(checkpoint)
        if cmd
          @cmdqueue << cmd
          if m = cached_mine(@cmdqueue)
            @mine = m
          else
            @mine.step!(cmd)
          end
          if @mine.losing?
            rollback!
            if not possible_checkpoint?(@checkpoint_route)
              return false
            end
          else
            cache_mine(@cmdqueue, @mine)
          end
        else
          # 実行可能なコマンドがない
          rollback!
          if not possible_checkpoint?(@checkpoint_route)
            return false
          end
        end
        next_pos = @mine.robot.pos
      end
      return true
    end

    # 次の目的地を探す
    # TODO: すでに試した場所だったら異なるcheckpointを設定
    # TODO: 簡単わかる無理そうなlambdaを検出する
    #       (たとえば岩にふさがっているものなど）
    def find_checkpoint
      checkpoint = nearest_point(@mine.lambdas, @mine.robot.pos)
      checkpoint = @mine.lift if checkpoint.nil?
      return checkpoint
    end

    # 次のrobotの命令を判断
    # 今のところ直線の最短距離のみ
    # TODO: 命令が制限を超えるようなケース
    #       道中で取れるラムダがあれば取っておく
    def judge_next_command(goal)
      next_position = nearest_point(movable_positions(@mine.robot), goal)
      return nil if next_position.nil?
      return @mine.robot.command_to(next_position)
    end

    # 指定位置への最短距離のポイントを返す。
    # TODO: 障害物も考慮した最短距離にしたい
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
      return (robot.movable_positions + [robot.pos]).
        select{|a| possible_route?(@cmdqueue + [robot.command_to(a)]) }
    end

    # 1つ前のmineにロールバック
    def rollback!
      @dead_cmd_route[@cmdqueue] = true
      cmd = @cmdqueue.pop
      # 成功のケースがないcheckpointを記録
      if !@checkpoint_watermarks.empty? &&
          @cmdqueue.size < @checkpoint_watermarks.last
        @dead_cmd_route[@checkpoint_route] = true
        @checkpoint_watermarks.pop
      end
      @mine = cached_mine(@cmdqueue)
    end

    # 可能性のあるrouteか？
    def possible_route?(cmdqueue)
      return false if @dead_cmd_route[cmdqueue]
      return true
    end

    # 可能性のあるcheckpointか？
    def possible_checkpoint?(check_route)
      return false if @dead_checkpoint_route[check_route]
      return true
    end

    def cached_mine(cmdqueue)
      @cmd_mine_cache[cmdqueue]
    end

    def cache_mine(cmdqueue, mine)
      @cmd_mine_cache[cmdqueue] = mine.dup
    end

    def checkpoint!(point)
      @checkpoint_watermarks << @cmdqueue.size
      @checkpoint_route << point
    end

    def handle_sigint
      exit 0 if @highscore.empty?
      @trapped_sigint = true
    end

    def highscore
      @highscore + ["A"]
    end
  end
end
