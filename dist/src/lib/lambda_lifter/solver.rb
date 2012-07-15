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
      @check_route = []
      @dead_check_route = {}
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
      cur_check_route = @check_route.dup
      while next_pos != checkpoint
        return highscore if @trapped_sigint
        success = exec_next_command(checkpoint)
        if not success
          # コマンド実行失敗
          rollback!
          return false if cur_check_route != @check_route
        end
        debugger if @cmdqueue.join == "LDLLDRRDRL"
        puts @mine.ascii_map
        next_pos = @mine.robot.pos
      end
      return true
    end

    # 次の目的地を探す
    # TODO: 簡単わかる無理そうなlambdaを検出する
    #       (たとえば岩にふさがっているものなど）
    def find_checkpoint
      possible_lambdas = @mine.lambdas.select do |l|
        possible_check_route?(@check_route + [l])
      end
      checkpoint = nearest_point(possible_lambdas, @mine.robot.pos)
      if checkpoint.nil? && @mine.lambdas.empty?
        checkpoint = @mine.lift
      end
      return checkpoint
    end

    # 次のrobotの命令を判断
    # 今のところ直線の最短距離のみ
    # 以前のmapと変化がない場合はnil
    # TODO: 命令が制限を超えるようなケース
    #       道中で取れるラムダがあれば取っておく
    def exec_next_command(goal)
      next_position = nearest_point(movable_positions(@mine.robot), goal)
      cmd = next_position.nil? ? nil : @mine.robot.command_to(next_position)
      if cmd
        @cmdqueue << cmd
        if m = cached_mine(@cmdqueue)
          @mine = m
        else
          @mine.step!(cmd)
        end
        if @mine.losing? || unchanged_mine?(@mine)
          return false
        else
          cache_mine(@cmdqueue, @mine)
        end
      end
      return true
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
      @dead_cmd_route[@cmdqueue.join] = true
      cmd = @cmdqueue.pop
      # 成功のケースがないcheckpointを記録
      if !@checkpoint_watermarks.empty? &&
          @cmdqueue.size < @checkpoint_watermarks.last
        @dead_check_route[check_route_to_key(@check_route)] = true
        @checkpoint_watermarks.pop
        expire_cache_mine(@check_route)
        @check_route.pop
      end
      @mine = cached_mine(@cmdqueue)
    end

    # 可能性のあるrouteか？
    def possible_route?(cmdqueue)
      return false if @dead_cmd_route[cmdqueue.join]
      return true
    end

    # 可能性のあるcheckpointのrouteか？
    def possible_check_route?(check_route)
      return false if @dead_check_route[check_route_to_key(check_route)]
      return true
    end

    def cached_mine(cmdqueue)
      (@check_route.size-1).downto(0) do |i|
        cache = (@cmd_mine_cache[check_route_to_key(@check_route[0..i])] ||= {})
        m = cache[cmdqueue.join]
        return m if not m.nil?
      end
      return nil
    end

    def cache_mine(cmdqueue, mine)
      cache = (@cmd_mine_cache[check_route_to_key(@check_route)] ||= {})
      cache[cmdqueue.join] = (mine.dup)
    end

    def expire_cache_mine(check_route)
      @cmd_mine_cache.delete(check_route_to_key(check_route))
    end

    def checkpoint!(point)
      @checkpoint_watermarks << @cmdqueue.size
      @check_route << point
    end

    def handle_sigint
      exit 0 if @highscore.empty?
      @trapped_sigint = true
    end

    def highscore
      @highscore + ["A"]
    end

    def unchanged_mine?(cur)
      return false if @cmdqueue.size <= 2
      prev_mine = cached_mine(@cmdqueue[0..-2])
      return false if prev_mine.nil?
      return prev_mine.eql?(cur)
    end

    def check_route_to_key(route)
      route.map(&:to_s).join("->")
    end
  end
end
