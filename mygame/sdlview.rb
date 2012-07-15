# coding: utf-8
require_relative "../dist/src/lib/lambda_lifter"
$LOAD_PATH.unshift "#{File.dirname(__FILE__)}/lib/"
require 'mygame/boot'
require 'singleton'

class LambdaLifter
  class SdlVisualizer
    include Singleton

    def initialize
      here = File.dirname(__FILE__)
      @images = {
        closed_lift: Image.new("#{here}/../visualizer/images/closed-lift.png"),
        earth: Image.new("#{here}/../visualizer/images/earth.png"),
        empty: Image.new("#{here}/../visualizer/images/empty.png"),
        lambda: Image.new("#{here}/../visualizer/images/lambda.png"),
        open_lift: Image.new("#{here}/../visualizer/images/open-lift.png"),
        robot: Image.new("#{here}/../visualizer/images/robot.png"),
        rock: Image.new("#{here}/../visualizer/images/rock.png"),
        wall: Image.new("#{here}/../visualizer/images/wall.png"),
      }

      @mine = Mine.new(<<-'EOD')
RL
      EOD
    end
    attr_accessor :mine

    def run
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

def sdl(mine, sleeptime=nil)
  LambdaLifter::SdlVisualizer.instance.mine = mine
  sleep sleeptime if sleeptime
end

if __FILE__==$0
  if ARGV.size == 0
    puts "usage: #$0 sample/contest1.map [sample/contest1.route]"
    exit
  else
    Thread.start{
      LambdaLifter.run
    }
    LambdaLifter::SdlVisualizer.instance.run
  end
end
