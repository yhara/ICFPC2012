# -*- coding: utf-8 -*-
require "set"

class LambdaLifter
  class Solver
    def initialize(mine)
      @mine = mine
      @highscore = {score: 0, cmd: "A"}
      Signal.trap(:INT){ handle_sigint }
      @try_solvers = [DrFoolishManhattan.new(@mine.dup)]
    end

    # コマンドの列を文字列で返す。
    # 例："DLLRA"
    def solve
      loop do
        return highscore_cmd if @trapped_sigint
        solver = @try_solvers.pop
        solver.solve
        if @highscore[:score] <= solver.highscore[:score]
          @highscore = solver.highscore
        end
        if @try_solvers.empty?
          return highscore_cmd
        end
      end
    end

    def handle_sigint
      @solver.handle_sigint
      @trapped_sigint = true
    end

    def highscore_cmd
      @highscore[:cmd]
    end

    module Util
      def log(msg)
        LambdaLifter.logger.info(msg)
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
p        end
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
