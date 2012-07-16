# -*- coding: utf-8 -*-
class LambdaLifter
  class Solver
    # バカなマンハッタン探索
    class DrFoolishManhattan
      include Util
      include FindUnreachable
  
      # 探索する深さのMAX係数
      @@giveup_depth_factor = 5
  
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
      end
      attr_reader :highscore
  
      def solve
        res = "A"
        log("---------- start(#{self.class.name}) ----------")
        res = loop do
          break highscore_cmd if @trapped_sigint
          break @commands.join if @mine.finished?
          sleep 0.1 if LambdaLifter.debug?
          checkpoint = find_checkpoint
          # ルートがない？
          if checkpoint.nil?
            log("solve: none route")
            # すべて探索しきった？
            break highscore_cmd if @check_route.empty?
            @passed_check_routes << @check_route.dup
            next rollback_checkpoint!
          end
          is_solved = solve_to_checkpoint(checkpoint)
          if is_solved
            checkpoint!(checkpoint)
            @passed_check_routes << @check_route.dup
          else
            # 失敗したcheckpointは探索済みとし
            @passed_check_routes << @check_route + [checkpoint]
          end
        end
        log("---------- end(#{self.class.name}) ----------")
        log("commands: #{res}")
        @highscore[:cmd] = res
      end
  
      def handle_sigint
        @trapped_sigint = true
      end
  
      def highscore_cmd
        @highscore[:cmd] + "A"
      end
  
      private
      # checkpointまでの経路を解く
      def solve_to_checkpoint(checkpoint)
        log("solve_to_checkpoint: #{checkpoint}")
        next_pos = nil
        depth = 0
        start_pos = @mine.robot.pos
        start_cmd_size = @commands.join.size
        limit = solve_depth_limit(checkpoint)
        while next_pos != checkpoint
          depth = (@commands.join.size - start_cmd_size)
          return false if @trapped_sigint
          if depth <= limit
            success = exec_next_command(checkpoint)
            log(
              "cmd: #{@commands.join}\n" +
              "route: #{check_route_to_key(@check_route + [checkpoint])}\n" +
              "passed_check_routes: #{@passed_check_routes.inspect}\n" +
              "depth <= limit: #{depth} < #{limit}\n" +
              "next_pos == checkpoint: #{@mine.robot.pos} == #{checkpoint}")
            ascii_map(cp: checkpoint) if LambdaLifter.debug?
          else
            log("solve_to_checkpoint: too deep")
            success = nil
          end
          # 実行可能コマンドなし
          if not success
            rollback!
            if start_pos == @mine.robot.pos &&
              (start_cmd_size == @commands.join.size)
              return false
            end
          end
          next_pos = @mine.robot.pos
        end
        return true
      end

      # 次の目的地を探す
      def find_checkpoint
        possible_lambdas = @mine.lambdas.select do |l|
          possible_check_route?(@check_route + [l])
        end
        checkpoint = judge_next_checkpoint(possible_lambdas, @mine.robot.pos)
        if checkpoint.nil? && @mine.lambdas.empty? && !unreachable?(@mine.lift)
          checkpoint = @mine.lift
        end
        log("find_checkpoint: possible_lambdas=<#{possible_lambdas}> checkpoint=<#{checkpoint}> check_route=<#{@check_route}>")
        return checkpoint
      end
  
      # 次のrobotの命令を判断
      # 今のところ直線の最短距離のみ
      # 以前のmapと変化がない場合はnil
      def exec_next_command(goal)
        sdl(@mine) if defined? sdl
        sleep 0.5 if LambdaLifter.debug?
        next_position = judge_next_robot_position(movable_positions(@mine.robot), goal)
        return false if limit_commands_exceeded?
        cmd = next_position.nil? ? nil : @mine.robot.command_to(next_position)
        return false if cmd.nil?
        # ヒゲ対応: ヒゲがあったら剃っておく
        if @mine.razors > 0 &&
            movable_positions(@mine.robot).any?{|pos| @mine[pos] == :beard }
          cmd = "S"
        end
        @commands << cmd
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

      # ポイントの内、次に移動するチェックポイントを決定
      def judge_next_checkpoint(points, goal)
        log("judge_next_checkpoint: " +
          "positions=<#{points.map{|pos| @mine.robot.command_to(pos)}}>, " +
          "dead_cmd=<#{@dead_cmd_routes.inspect}>")
        return nil if points.empty?
        return points.first if points.size == 1
        return nearest_checkpoint(points, goal)
      end

      # ポイントの内、次に移動するポイントを決定
      def judge_next_robot_position(points, goal)
        log("judge_next_robot_position: " +
          "positions=<#{points.map{|pos| @mine.robot.command_to(pos)}}>, " +
          "dead_cmd=<#{@dead_cmd_routes.inspect}>")
        return nil if points.empty?
        return points.first if points.size == 1
        neary_lambda = points.find{|pos| @mine[pos] == :lambda }
        return neary_lambda if neary_lambda
        return nil if (@mine.lambdas + [@mine.lift]).any?{|pos| unreachable?(pos)}
        return nearest_robot_position(points, goal)
      end
  
      # 最も近いポジションを探索
      def nearest_position(poss, from)
        poss.map.with_index{|point, i|
          [manhattan_distance(point, from), point]
        }.sort_by{|distance, _| distance }.first[1]
      end
      alias :nearest_checkpoint :nearest_position
      alias :nearest_robot_position :nearest_position
  
      # 移動可能な位置
      def movable_positions(robot)
        return (robot.movable_positions + [robot.pos]).
          select{|a| possible_route?(@commands + [robot.command_to(a)]) }
      end
  
      # 1つ前のmineにロールバック
      def rollback!
        log("rollback!: #{@commands.join} -> #{@commands[0..-2].to_a.join} wts=<#{@checkpoint_watermarks}>")
        @dead_cmd_routes << @commands.join
        cmd = @commands.pop
        # 成功のケースがないcheckpointを記録
        if !@checkpoint_watermarks.empty? &&
            @commands.size < @checkpoint_watermarks.last
          log("rollback!: with checkpoint, cmd=<#{@commands.join}> wt=<#{@checkpoint_watermarks.last}>")
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
  
      # 現在より1つ前のcheckpointへrollback
      def rollback_checkpoint!
        rollback_cnt = @checkpoint_watermarks[-2].to_i
        log("rollback_checkpoint!: rollback_cnt=<#{rollback_cnt}>")
        (@commands.size - rollback_cnt + 1).times{ rollback! }
      end
  
      # 可能性のあるrouteか？
      def possible_route?(commands)
        return !@dead_cmd_routes.include?(commands.join)
      end
  
      # 可能性のあるcheckpointのrouteか？
      def possible_check_route?(check_route)
        # すでに通過したroute
        return false if @passed_check_routes.include?(check_route)
        # return false if unreachable_pos(check_route.last)
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
        log("checkpoint!: point=<#{point}>, current_route=<#{@check_route}>")
        @checkpoint_watermarks << @commands.size
        @check_route << point
      end
  
      def changed_mine?(cur, prev)
        return prev.lambdas != cur.lambdas ||
          prev.rocks != cur.rocks ||
          prev[cur.robot.pos] == :earth
      end
  
      def check_route_to_key(route)
        route.map(&:to_s).join("->")
      end
  
      def limit_commands_exceeded?
        l = (@mine.width * @mine.height)
        @commands.size > l
      end
  
      def manhattan_distance(from, to)
        return ((to.x - from.x).abs + (to.y - from.y).abs)
      end
  
      def solve_depth_limit(checkpoint)
        normal = manhattan_distance(@mine.robot.pos, checkpoint) * @@giveup_depth_factor
        if @mine.lift.eql?(checkpoint)
          return normal * 2
        else
          return normal
        end
      end
    end
  end
end
