# coding: utf-8
require_relative "../dist/src/lib/lambda_lifter"
$LOAD_PATH.unshift "#{File.dirname(__FILE__)}/lib/"
require 'mygame'
require 'singleton'

class LambdaLifter
  class SdlVisualizer
    include Singleton
    include MyGame

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

    IMAGE_FILES = %w(closed_lift earth empty lambda open_lift robot rock wall
                    razor beard higher_order_rock trampoline target
                    higher_order_rock)
    def run(opts = {})
      screen_w = 800
      screen_h = 600
      MyGame.create_screen screen_w, screen_h

      images = Hash[IMAGE_FILES.map{|name|
        name = $1 if name.match(/(trampoline|target)_\w/)
        [name.to_sym, Image.new("#{File.dirname __FILE__}/../visualizer/images/#{name}.png")]
      }]

      MyGame.main_loop do
        scale = @scale || [(screen_h.to_f/@mine.height)/47, 1].min
        @mine.raw_map.each.with_index do |raw_row, y|
          raw_row.each.with_index do |sym, x|
            sym = $1.to_sym if sym.match(/(trampoline|target)_\w/)
            img = images[sym] or raise "unkown: #{sym}"
            img.x = x * (47*scale)
            img.y = y * (47*scale)
            img.scale = scale
            img.render
          end
        end
        water_lv = (@mine.height  - @mine.water) * (47*scale)
        MyGame.screen.draw_filled_rect_alpha(0, water_lv,
                                             @mine.width * (47*scale),
                                             @mine.height * (47*scale) - water_lv,
                                             [0,0,255],100)

        exit if key_pressed?(Key::Q)
        @mine.step!("U") if new_key_pressed?(Key::UP)
        @mine.step!("D") if new_key_pressed?(Key::DOWN)
        @mine.step!("R") if new_key_pressed?(Key::RIGHT)
        @mine.step!("L") if new_key_pressed?(Key::LEFT)
        @mine.step!("W") if new_key_pressed?(Key::W)
        @mine.step!("A") if new_key_pressed?(Key::A)
        @mine.step!("S") if new_key_pressed?(Key::S)
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
