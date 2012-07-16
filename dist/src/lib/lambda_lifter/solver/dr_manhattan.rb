# -*- coding: utf-8 -*-
class LambdaLifter
  class Solver
    # 少し賢いマンハッタン探索
    class DrManhattan < DrFoolishManhattan
      def nearest_checkpoint(poss, from)
        log("nearest_checkpoint: poss=<#{poss}>, from=<#{from}, #{@mine[from]}>")
        poss.map.with_index{|pos, i|
          map = calc_distance_map(pos)
          [(map[from.x] && map[from.x][from.y]).to_i, pos]
        }.sort_by{|distance, _| distance }.first[1]
      end

      def nearest_robot_position(poss, goal)
        log("nearest_robot_position: poss=<#{poss}>, from=<#{goal}, #{@mine[goal]}>")
        map = calc_distance_map(goal)
        poss.map.with_index{|pos, i|
          [(map[pos.x] && map[pos.x][pos.y]).to_i, pos]
        }.sort_by{|distance, _| distance }.first[1]
      end

      def judge_next_robot_position(points, goal)
        point = super
        if LambdaLifter.debug?
          @mine.ascii_map! do |pos|
            map = calc_distance_map(goal)
            if map[pos.x] && map[pos.x][pos.y]
              s = map[pos.x][pos.y].to_s.ljust(2)
              next s.background(:red).color(:white) if pos == point
              s = points.include?(pos) ? s.background(:green).color(:white) : s.background(:black).color(:white)
            else
              "".ljust(2)
            end
          end
        end
        return point
      end
      
      def ascii_map(opts)
        # map = calc_distance_map(opts[:cp])
        # @mine.ascii_map! do |pos|
        #   ps = []
        #   ps << (@visited_poss.include?(pos) ? " ".background(:green) : " ")
        #   if map[pos.x] && map[pos.x][pos.y]
        #     ps << map[pos.x][pos.y].to_s.ljust(2).background(:red).color(:white)
        #   else
        #     ps << " ".ljust(2).to_s.background(:black).color(:white)
        #   end
        #   ps.join
        # end
      end
    end
  end
end
