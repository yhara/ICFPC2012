# -*- coding: utf-8 -*-
class LambdaLifter
  class Solver
    # 少し賢いマンハッタン探索
    class DrManhattan < DrFoolishManhattan
      def nearest_checkpoint(poss, from)
        log("nearest_position: poss=<#{poss}>, from=<#{from}>")
        poss.map.with_index{|point, i|
          [manhattan_distance(point, from), point]
        }.sort_by{|distance, _| distance }.map{|_, point|
          [-(wall_cnt_from_to(from, point)), point]
        }.sort_by{|i, _| i }.first[1]
      end
    end
  end
end
