# -*- coding: utf-8 -*-
require "set"

class LambdaLifter
  class Solver
    def initialize(mine)
      @mine = mine
      # ["L", "R"] など
      @commands = []
      # コマンド実行時のmineのキャッシュ
      # {"(1, 1)" => {"L" => mine}, "(1, 1)->(2, 1)" => {"LL" => mine}}
      @cmd_mine_cache = {}
      # コマンド実行時に失敗したもの
      # Set["LLD", ...]
      @dead_cmd_routes = Set.new
      # commandsのcheckpointに到達した地点のindex
      # [1, 5, 10, 12]
      @checkpoint_watermarks = []
      # すでに通ったcheckpointの配列
      # [(1, 2), (2, 3)]
      @check_route = []
      # 探索し尽くしたcheck_route
      # Set["(1, 2)->(2, 3)", ...]
      @passed_check_routes = Set.new
      # ハイスコア
      @highscore = {score: 0, cmd: ""}
      @trapped_sigint = false
      # 通ったマスセット（変化が起きるとクリアされる）
      @visited_poss = Set.new
      Signal.trap(:INT){ handle_sigint }
    end

    # コマンドの列を文字列で返す。
    # 例："DLLRA"
    def solve
      loop do
        # TODO: finished?になってもよりよいスコアを求める
        return highscore if @trapped_sigint
        return @commands.join if @mine.finished?
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
        # p [:solve, @commands.join]
        # puts @mine.ascii_map
        if not success
          # コマンド実行失敗
          rollback!
          return false if cur_check_route != @check_route
        end
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
      checkpoint = @mine.lift if checkpoint.nil? && @mine.lambdas.empty?
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
      return false if cmd.nil?
      @commands << cmd
      #p [:exe_commands, @commands.join]
      if m = cached_mine(@commands)
        @mine = m
      else
        cache_mine(@commands[0..-2], @mine)
        @visited_poss << @mine.robot.pos
        prev = @mine
        @mine = @mine.dup
        @mine.step!(cmd)
        @visited_poss.clear if changed_mine?(@mine, prev)
        
        if @highscore[:score] < @mine.score
          @highscore[:score] = @mine.score
          @highscore[:cmd] = @commands.join
        end
      end
      #puts @mine.ascii_map
      if @mine.losing? || @visited_poss.include?(@mine.robot.pos)
        return false
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
        select{|a| possible_route?(@commands + [robot.command_to(a)]) }
    end

    # 1つ前のmineにロールバック
    def rollback!
      # p [:rollback!]
      @dead_cmd_routes << @commands.join
      cmd = @commands.pop
      # 成功のケースがないcheckpointを記録
      if !@checkpoint_watermarks.empty? &&
          @commands.size < @checkpoint_watermarks.last
        @passed_check_routes << check_route_to_key(@check_route)
        @checkpoint_watermarks.pop
        expire_cache_mine(@check_route)
        @check_route.pop
      end
      m = cached_mine(@commands)
      if m.nil?
        raise "cached mine not found: key => #{@commands.join}," +
          " checkroute => #{check_route_to_key(@check_route)}"
      end
      @visited_poss.clear if changed_mine?(m, @mine)
      @mine = m
    end

    # 可能性のあるrouteか？
    def possible_route?(commands)
      return !@dead_cmd_routes.include?(commands.join)
    end

    # 可能性のあるcheckpointのrouteか？
    def possible_check_route?(check_route)
      # すでに通過したroute
      return false if @passed_check_routes.include?(check_route_to_key(check_route))
      return true
    end

    def cached_mine(commands)
      (@check_route.size).downto(1) do |i|
        cache = @cmd_mine_cache[check_route_to_key(@check_route[0..(i-1)])] || {}
        m = cache[commands.join]
        return m if not m.nil?
      end
      if @check_route.empty?
        cache = @cmd_mine_cache[""] || {}
        m = cache[commands.join]
        return m
      end
      return nil
    end

    def cache_mine(commands, mine)
      cache = (@cmd_mine_cache[check_route_to_key(@check_route)] ||= {})
      cache[commands.join] = mine
    end

    def expire_cache_mine(check_route)
      @cmd_mine_cache.delete(check_route_to_key(check_route))
    end

    def checkpoint!(point)
      @checkpoint_watermarks << @commands.size
      @passed_check_routes << check_route_to_key(@check_route)
      @check_route << point
    end

    def handle_sigint
      @trapped_sigint = true
    end

    def highscore
      @highscore[:cmd] + "A"
    end

    def changed_mine?(cur, prev)
      # p [:lambdas, prev.lambdas, cur.lambdas]
      # p [:rocks, prev.rocks, cur.rocks]
      # p [:here]
      # puts prev.ascii_map
      # puts cur.ascii_map
      # p [:end, prev, cur]
      return prev.lambdas != cur.lambdas ||
        prev.rocks != cur.rocks
    end

    def check_route_to_key(route)
      route.map(&:to_s).join("->")
    end
  end
end
