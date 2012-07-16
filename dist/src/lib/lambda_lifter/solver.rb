# -*- coding: utf-8 -*-
require "set"

class LambdaLifter
  class Solver
    def initialize(mine)
      @mine = mine
      @highscore = {score: 0, cmd: "A"}
      Signal.trap(:INT){ handle_sigint }
      @try_solvers = [DrManhattan.new(@mine.dup)]
#      @try_solvers = [DrFoolishManhattan.new(@mine.dup)]
    end

    # コマンドの列を文字列で返す。
    # 例："DLLRA"
    def solve
      loop do
        return highscore_cmd if @trapped_sigint
        @solver = @try_solvers.pop
        @solver.solve
        if @highscore[:score] <= @solver.highscore[:score]
          @highscore = @solver.highscore
        end
        if @try_solvers.empty?
          return highscore_cmd
        end
      end
    rescue
      raise if LambdaLifter.debug? || defined? Bundler
      return highscore_cmd
    end

    def handle_sigint
      @solver.handle_sigint if not @solver.nil?
      @trapped_sigint = true
    end

    def highscore_cmd
      @highscore[:cmd]
    end

    module Util
      def log(msg)
        LambdaLifter.logger.info(msg)
      end

      # fromからtoまでの直線距離のpos配列を返す
      def poss_from_to(mine, from, to)
        res = []
        [:x, :y].cycle.each_with_object(res) do |move_to, poss|
          cur = poss.last || from
          if move_to == :x
            if cur.x < to.x
              cur = Pos[cur.x+1, cur.y]
            elsif cur.x > to.x
              cur = Pos[cur.x-1, cur.y]
            else
              next
            end
          else
            if cur.y < to.y
              cur = Pos[cur.x, cur.y+1]
            elsif cur.y > to.y
              cur = Pos[cur.x, cur.y-1]
            else
              next
            end
          end
          break if cur == to
          poss << cur
        end
        return res
      end

      # 直線距離の間の壁の枚数
      def wall_cnt_from_to(from, to)
        return poss_from_to(@mine, from, to).
          select{|pos| @mine[pos] == :wall }.size
      end

      def calc_distance_map(pos)
        @cached_distance_map ||= {}
        return @cached_distance_map[pos] if @cached_distance_map[pos]
        map = []
        stack = [[{pos: pos, dist: 0}]]
        until stack.empty?
          s = stack.pop
          s.each do |cell|
            base = cell[:dist]
            pos = cell[:pos]
            next if map[pos.x] && map[pos.x][pos.y]
            map[pos.x] ||= []
            map[pos.x][pos.y] ||= base
            stack << [{pos: Pos[pos.x-1, pos.y-1], dist: base+2},
              {pos: Pos[pos.x-1, pos.y+1], dist: base+2},
              {pos: Pos[pos.x+1, pos.y-1], dist: base+2},
              {pos: Pos[pos.x+1, pos.y+1], dist: base+2},
              {pos: Pos[pos.x+1, pos.y+1], dist: base+2},
              {pos: Pos[pos.x-1, pos.y], dist: base+1},
              {pos: Pos[pos.x+1, pos.y], dist: base+1},
              {pos: Pos[pos.x, pos.y-1], dist: base+1},
              {pos: Pos[pos.x, pos.y+1], dist: base+1},
            ].select{|cell| ![:wall, :out_of_map].include?(@mine[pos]) }
          end
        end

        # DEBUG用
        # @mine.ascii_map! do |pos|
        #   if map[pos.x] && map[pos.x][pos.y]
        #     map[pos.x][pos.y].to_s.background(:red).color(:white)
        #   else
        #     " ".to_s.background(:black).color(:white)
        #   end
        # end
        @cached_distance_map[pos] = map
        return map
      end

      def ascii_map(opts)
        @mine.ascii_map!
      end
    end

    # 確実に到達不可能な地点を見つける
    module FindUnreachable
      DIRECTIONS = [Pos[1, 0], Pos[-1, 0], Pos[0, 1], Pos[0, -1]]

      def unreachable?(pos)
        return closed_with_static_objects?(@mine, pos, @mine.robot.pos)
      end

      # 壁と岩を単純に境界として、区切られている空間を
      # Posの配列で返す。区切られていない場合はnilを返す。
      def space_bounded_by_rocks_and_walls(mine, from, to)
        is_boundary = lambda{|pos|
          [:rock, :wall].include? mine[pos]
        }
        boundary = Set.new
        internal_space = Set.new
        visited = Set.new
        queue = [from]
        until queue.empty?
          pos = queue.shift
          return nil if pos == to  # 区切られてなかった
          visited << pos
          internal_space << pos
          DIRECTIONS.each do |diff|
            newpos = pos + diff
            if is_boundary[newpos]
              boundary << newpos
            else
              if !visited.include?(newpos) && mine.valid_pos?(newpos) 
                queue.push(newpos)
              end
            end
          end
        end
        return [internal_space, boundary]
      end

      # ある岩と壁で囲まれた地点に対し、
      # 確実にstaticなもので囲まれているかどうかを返す。
      def closed_with_static_objects?(mine, from, to)
        internal_space, boundary = space_bounded_by_rocks_and_walls(mine, from, to)
        return false if internal_space.nil? || boundary.nil?

        static = {}
        # 空間の内部は、emptyを除き、staticであると仮定する
        internal_space.each{|pos|
          static[pos] = true unless mine[pos] == :empty
        }
        # デバッグ用
        dump = lambda{
          mine.each_pos_from_top_left do |pos|
            print Mine::LAYOUTS.invert[mine[pos]]
            print(if static.key?(pos) then static[pos] ? '!' : '.'
                  else " " end)
          end
        }
        is_static = lambda{|pos|
          if static.key?(pos)
            true
          else
            ret = case mine[pos]
                  when :wall, :out_of_space 
                    true
                  when :rock
                    never_fall = (is_static[pos + [-1, -1]] || is_static[pos + [-1, 0]]) &&  # 左下・左のいずれか
                                  is_static[pos + [ 0, -1]] &&                              # 真下
                                 (is_static[pos + [+1, -1]] || is_static[pos + [+1, 0]])     # 右下・右のいずれか
                    never_pushed = is_static[pos + [-1, 0]] || is_static[pos + [+1, 0]]  # 左右いずれか
                    never_fall && never_pushed
                  else
                    false
                  end
            static[pos] = ret; ret
          end
        }

        # Note: 下から順に調べた方がいいのでsortしている
        return boundary.sort.all?{|pos|
          is_static[pos] #.tap{|ret| dump[] if !ret}
        }
      end
    end
  end
end

require_relative "solver/dr_foolish_manhattan"
require_relative "solver/dr_manhattan"
