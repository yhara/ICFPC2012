require_relative "../dist/src/lib/lambda_lifter"
require 'mygame/boot'

class LambdaLifter
  class SdlVisualizer
    def initialize
      @images = {
        closed_lift: Image.new("../visualizer/images/closed-lift.png"),
        earth: Image.new("../visualizer/images/earth.png"),
        empty: Image.new("../visualizer/images/empty.png"),
        lambda: Image.new("../visualizer/images/lambda.png"),
        open_lift: Image.new("../visualizer/images/open-lift.png"),
        robot: Image.new("../visualizer/images/robot.png"),
        rock: Image.new("../visualizer/images/rock.png"),
        wall: Image.new("../visualizer/images/wall.png"),
      }

      @mine = Mine.new(<<-'EOD')
######
#. *R#
#  \.#
#\ * #
L  .\#
######
      EOD
    end

    def run
      lmd = Image.new "../visualizer/images/lambda.png"
      #lmd.scale = 0.5

      i = 0
      Thread.start{
        loop do
          p i+=1
          sleep 1
        end
      }

      main_loop do
        @mine.raw_map.each.with_index do |raw_row, y|
          raw_row.each.with_index do |sym, x|
            img = @images[sym] or raise "unkown: #{sym}"
            scale = 1
            img.x = x * (47*scale)
            img.y = y * (47*scale)
            img.scale = scale
            img.render
          end
        end
      end
    end
  end
end


LambdaLifter::SdlVisualizer.new.run
