# coding: utf-8
require_relative "../dist/src/lib/lambda_lifter"
$LOAD_PATH.unshift "#{File.dirname(__FILE__)}/lib/"
require 'mygame'
require 'singleton'

class LambdaLifter
  class SdlVisualizer
    include Singleton

    def initialize
      @mine = Mine.new(<<-'EOD')
RL
      EOD
      @scale = nil
    end
    attr_accessor :mine
    attr_writer :scale

    def background_color=(col)
      MyGame.background_color = col
    end

    def run
      MyGame.create_screen 800, 600
      @scale ||= 1

      here = File.dirname(__FILE__)
      @images = {
        closed_lift: MyGame::Image.new("#{here}/../visualizer/images/closed-lift.png"),
        earth: MyGame::Image.new("#{here}/../visualizer/images/earth.png"),
        empty: MyGame::Image.new("#{here}/../visualizer/images/empty.png"),
        lambda: MyGame::Image.new("#{here}/../visualizer/images/lambda.png"),
        open_lift: MyGame::Image.new("#{here}/../visualizer/images/open-lift.png"),
        robot: MyGame::Image.new("#{here}/../visualizer/images/robot.png"),
        rock: MyGame::Image.new("#{here}/../visualizer/images/rock.png"),
        wall: MyGame::Image.new("#{here}/../visualizer/images/wall.png"),
      }

      MyGame.main_loop do
        @mine.raw_map.each.with_index do |raw_row, y|
          raw_row.each.with_index do |sym, x|
            img = @images[sym] or raise "unkown: #{sym}"
            img.x = x * (47*@scale)
            img.y = y * (47*@scale)
            img.scale = @scale
            img.render
          end
        end
      end
    end
  end
end

def sdl(mine)
  LambdaLifter::SdlVisualizer.instance.mine = mine
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
