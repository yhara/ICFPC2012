require 'mygame'

module MyGame
  module Scene
    class Exit; end

    class Base
      attr_accessor :next_scene
      attr_reader :frame_counter
      def initialize
        @next_scene = nil
        @frame_counter = 0
        init
      end

      def __quit
        quit
        MyGame.init_events
        Font.clear_cache
        Image.clear_cache
        Wave.clear_cache
      end
      private :__quit

      def __update
        update
        @frame_counter += 1
      end
      private :__update
  
      def __render
        render
      end
      private :__render
  
      def init # :nodoc:
      end

      def quit # :nodoc:
      end

      def update # :nodoc:
      end

      def render # :nodoc:
      end
    end

    def self.main_loop(scene_class, fps = 60, step = 1)
      MyGame.create_screen
      scene = scene_class.new
      default_step = step
      MyGame.main_loop(fps) do
        if MyGame.new_key_pressed?(Key::PAGEDOWN)
          step += 1
          MyGame.fps = fps * default_step / step
        end
        if MyGame.new_key_pressed?(Key::PAGEUP) and step > default_step
          step -= 1
          MyGame.fps = fps * default_step / step
        end
        step.times do
          break if scene.next_scene
          scene.__send__ :__update
        end
        scene.__send__ :__render
        if scene.next_scene
          scene.__send__ :__quit
          break if Exit == scene.next_scene
          scene = scene.next_scene.new
        end
      end
    end
  end
end
