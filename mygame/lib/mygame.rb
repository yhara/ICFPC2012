require 'sdl'
module MyGame
  class Wave
    @@wave = {}
    def initialize(filename, ch = :auto, loop = 1)
      @ch = ch
      @loop = loop
      @filename = filename
      load(filename)
    end

    def load(filename)
      @@wave[filename] = SDL::Mixer::Wave.load(filename)
    end

    def self.clear_cache
      @@wave = {}
    end

    def _loops(loop)
      if loop.nil?
        0
      elsif loop == :loop or loop <= 0
        -1
      else
        loop - 1
      end
    end
    private :_loops

    def _ch(ch)
      if ch.nil? or ch == :auto
        -1
      else
        ch
      end
    end
    private :_ch

    def _play(ch, wave, loop)
      SDL::Mixer.play_channel(_ch(ch), wave, _loops(loop))
    end
    private :_play

    def play(ch = @ch, loop = @loop)
      _play(ch, @@wave[@filename], loop)
    end

    def self.play(*args)
      new(*args).play
    end
  end

  class Music < Wave
    def initialize(filename, loop = 1)
      @loop = loop
      @filename = filename
      load(filename)
    end

    def load(filename)
      @@wave[filename] = SDL::Mixer::Music.load(filename)
    end

    def _play(wave, loop)
      SDL::Mixer.play_music(wave, loop)
    end
    private :_play

    def play(loop = @loop)
      _play(@@wave[@filename], loop)
    end

    def self.stop
      SDL::Mixer.halt_music
    end

    def stop
       self.class.stop
    end
  end

  class DrawPrimitive
    attr_accessor :screen
    private :screen
    attr_accessor :x, :y
    attr_accessor :w
    attr_accessor :h
    attr_accessor :offset_x, :offset_y
    attr_accessor :alpha
    attr_accessor :hide

    Options = {
      :x => 0,
      :y => 0,
      :w => nil,
      :h => nil,
      :offset_x => 0,
      :offset_y => 0,
      :alpha => 255,
      :hide => false,
    } # :nodoc:
    def self.default_options # :nodoc:
      Options
    end

    def self.check_options(options) # :nodoc:
      options.each {|k, v|
        next unless Symbol === k
        unless default_options.include? k
          raise ArgumentError, "unrecognized option: #{k}"
        end
      }
    end

    def self.render(*args)
      new(*args).render
    end

    def initialize(*options)
      @screen = MyGame.screen
      @disp_x = @disp_y = nil
      init_options(*options)
    end

    def init_options(*options) # :nodoc:
      opts = options.shift if !options.empty? && Hash === options.first
      raise ArgumentError.new("extra arguments") if !options.empty?
      opts ||= {}
      self.class.check_options(opts)
      self.class.default_options.each do |k, v|
        __send__ "#{k}=", opts[k] || v
      end
    end

    def hide?
      !!hide
    end

    def hit?(target)
      return nil if hide? or @disp_x.nil?
      SDL::CollisionMap.bounding_box_check(@disp_x, @disp_y, w, h, target.x, target.y, 1, 1)
    end

    def update
    end

    def render
    end

  end

  class Image < DrawPrimitive
    @@image_cache = {}
    attr_accessor :angle
    attr_accessor :scale
    attr_reader :image, :animation

    Options = {
      :angle => 0,
      :scale => 1,
    } # :nodoc:
    def self.default_options # :nodoc:
      super.merge Options; end

    def initialize(filename = nil, *options)
      super(*options)

      @filename = filename
      load(@filename) if @filename
      @ox = @oy = 0
      @animation = nil
      @animation_counter = 0
      @animation_labels = {}
    end

    def update_animation
      if a = @animation_labels[@animation]
        size = a[:patten].size
        idx = @animation_counter / a[:time]
        if idx >= size
          case a[:following]
          when nil
            stop_animation
            return
          when :loop
          else
            start_animation a[:following]
            a = @animation_labels[@animation]
          end
          @animation_counter = 0
          idx = 0
        end
        offset = a[:patten][idx]
        num = @image.w / @w
        @ox = offset % num * @w
        @oy = offset / num * @h
        @animation_counter += 1
      end
    end
    private :update_animation

    def update
      update_animation
    end

    def _set_animation(label, time, patten = nil, following = :loop)
      raise "`#{label}' cannot be used for the label." if label == :loop
      @animation_labels[label] = {
        :time      => [time, 1].max,
        :patten    => patten,
        :following => following,
      }
    end
    private :_set_animation

    def add_animation(hash)
      hash.each do |key, params|
        _set_animation(key, *params)
      end
    end

    def start_animation(label, restart = false)
      @animation_labels[label] or raise "cannot find animation label `#{label}'"
      return if @animation == label and !restart
      @animation = label
      @animation_counter = 0
    end

    def stop_animation
      @animation = nil
    end

    def load(filename)
      unless @image = @@image_cache[filename]
        @image = SDL::Surface.load(filename).display_format
        @@image_cache[filename] = @image
      end
      @w ||= @image.w
      @h ||= @image.h
      @alpha_image = nil
      @image
    end

    def set_transparent_pixel(x = 0, y = 0)
      pix = @image.getPixel(x, y)
      key = [@filename, pix]
      if image = @@image_cache[key]
        @image = image
      else
        @image = @image.display_format
        @image.set_color_key SDL::SRCCOLORKEY, pix
        @image = @image.display_format
        @@image_cache[key] = @image
      end
      @alpha_image = nil
      @image
    end

    def render
      if hide? or @image.nil?
        @disp_x = @disp_y = nil
        return
      end
      x = @x + offset_x
      y = @y + offset_y
      @disp_x, @disp_y = x, y
      @disp_x, @disp_y = x, y
      return if @alpha <= 0
      img = if alpha < 255
              @alpha_image ||= @image.display_format
              @alpha_image.set_alpha(SDL::SRCALPHA, alpha)
              @alpha_image
            else
              @image
            end
      if scale == 1 and angle == 0
        SDL.blit_surface img, @ox, @oy, @w, @h, screen, x, y
      else
        #SDL.transform_blit(img, screen, @angle, @scale, @scale, @w/2, @h/2, x, y, 0)
        SDL.transform_blit(img, screen, @angle, @scale, @scale, 0, 0, x, y, 0)
      end
    end

    def self.clear_cache
      @@image_cache = {}
    end
  end

  class TransparentImage < Image
    def initialize(filename = nil, *options)
      super(filename, *options)
      set_transparent_pixel 0, 0
    end
  end

  require 'kconv'
  require 'rbconfig'

  class Font < DrawPrimitive
    def self.default_options # :nodoc:
      opts = {
          :color => [255, 255, 255],
          :size => default_size,
          :ttf_path => default_ttf_path,
      }
      super.merge opts
    end

    DEFALUT_TTF = 'VL-Gothic-Regular.ttf'
    def self.setup_default_setting(ttf = nil, size = nil)
      datadir = RbConfig::CONFIG["datadir"]
      mygame_datadir = File.join(datadir, 'mygame')
      ['./fonts', mygame_datadir].each do |dir|
        path = ttf || File.join(dir, DEFALUT_TTF)
        if File.exist?(path)
          @@default_ttf_path = path
          break
        end
      end
      @@default_size = size || 16
    end
    setup_default_setting

    def self.default_size
      @@default_size
    end

    def self.default_size=(size)
      @@default_size = size
    end

    def self.default_ttf_path
      @@default_ttf_path
    end

    def self.default_ttf_path=(path)
      @@default_ttf_path = path
    end

    def initialize(string = '', *options)
      super(*options)

      @font = open_tff(@ttf_path, @size)
      @font.style = SDL::TTF::STYLE_NORMAL

      @last_string = nil
      self.string = string
    end

    @@tff_cache = {}
    def self.clear_cache
      @@tff_cache = {}
    end

    def open_tff(ttf_path, size)
      @@tff_cache[[ttf_path, size]] ||= SDL::TTF.open(ttf_path, size)
    end
    private :open_tff

    def refresh # :nodoc:
      if @font
        @font = open_tff(@ttf_path, @size)
        create_surface
      end
    end

    attr_accessor :string
    attr_accessor :color
    attr_accessor :shadow_color
    attr_accessor :size
    attr_accessor :ttf_path
    attr_accessor :added_width # :nodoc:
    %w(color shadow_color size ttf_path).each do |e|
      attr_reader e
      eval "    def #{e}=(arg)
      return if arg == (@last_#{e} ||= nil)
      @last_#{e} = @#{e} = arg
      refresh
    end"
    end

    def string=(arg) # :nodoc:
      return if @last_string == (arg = arg.to_s)
      @last_string = arg
      @string = Kconv.toutf8(arg)
      create_surface
    end

    def create_surface # :nodoc:
      @w, @h = @font.text_size(@string)
      @max_w, @max_h = @w, @h
      @dx, @dy = if @shadow_color
                   [1 + @size / 24, 1 + @size / 24]
                 else
                   [0, 0]
                 end
      @surface = SDL::Surface.new(SDL::SWSURFACE, w + @dx, h + @dy, 32, *MyGame.mask_rgba)
      if @shadow_color
        @font.drawSolidUTF8(@surface, @string, @dx, @dy, *@shadow_color)
        @font.drawSolidUTF8(@surface, @string, 0, @dy, *@shadow_color)
      end
      @font.drawSolidUTF8(@surface, @string, 0, 0, *@color)
      @surface.set_color_key SDL::SRCCOLORKEY, @surface.getPixel(0, 0)
      @surface = @surface.display_format
    end

    def start_effect(w) # :nodoc:
      @added_width = w
      @w = 0
    end

    def max_w? # :nodoc:
      @w.nil? or @w >= @max_w
    end

    def update
      @w += @added_width unless max_w?
    end

    def render
      if hide? or @surface.nil?
        @disp_x = @disp_y = nil
        return
      end
      x = @x + offset_x
      y = @y + offset_y
      if max_w?
        disp_w = 0
        disp_h = 0
      else
        disp_w = w# / 2 * size
        disp_h = h + @dy
      end
      @disp_x, @disp_y = x, y
      return if @alpha <= 0
      @surface.set_alpha(SDL::SRCALPHA, alpha) if alpha < 255
      SDL.blit_surface @surface, 0, 0, disp_w, disp_h, screen, x, y
   end
  end

  class ShadowFont < Font
    def initialize(*args)
      @shadow_color = [64, 64, 64]
      super
    end
  end

  class Square < DrawPrimitive
    Options = {
      :color => [255, 255, 255],
      :fill => false,
    } # :nodoc:
    def self.default_options # :nodoc:
      super.merge Options; end

    attr_accessor :color
    attr_accessor :fill

    def initialize(x = 0, y = 0, w = 0, h = 0, *options)
      super(*options)
      @x, @y = x, y
      @w, @h = w, h
      @fill = false
    end

    def render
      if hide?
        @disp_x = @disp_y = nil
        return
      end
      x = @x + offset_x
      y = @y + offset_y
      @disp_x, @disp_y = x, y
      return if @alpha <= 0
      if @alpha < 255
        @@screen.send((@fill ? :draw_filled_rect_alpha : :draw_rect_alpha),
                      x, y, w, h, color, @alpha)
      else
        @@screen.send((@fill ? :fill_rect : :draw_rect),
                      x, y, w, h, color)
      end
    end
  end

  class FillSquare < Square
    def initialize(*args)
      super
      @fill = true
    end
  end

  @@screen = nil
  @@ran_loop = false
  @@ran_init = false
  @@ran_create_screen = false
  @@loop_end = false
  @@events = {}
  @@background_color = [0, 0, 0]
  @@fps = nil

  def init(flags = SDL::INIT_AUDIO | SDL::INIT_VIDEO)
    raise if SDL.inited_system(flags) > 0
    @@ran_init = true
    init_events
    SDL.init flags
    SDL::Mixer.open if flags & SDL::INIT_AUDIO
    SDL::Mixer.allocate_channels(16)
    SDL::TTF.init
  end
  module_function :init

  def quit
    SDL.quit
  end
  module_function :quit

  def create_screen(screen_w = (defined?(DEFAULT_SCREEN_W) && DEFAULT_SCREEN_W) || 640,
                    screen_h = (defined?(DEFAULT_SCREEN_H) && DEFAULT_SCREEN_H) || 480,
                    bpp = 16, flags = SDL::SWSURFACE)
    init unless @@ran_init
    @@ran_create_screen = true
    screen = SDL.set_video_mode(screen_w, screen_h, bpp, flags)
    def screen.update(x = 0, y = 0, w = 0, h = 0)
      self.update_rect x, y, w, h
    end
    @@screen = screen
  end
  module_function :create_screen

  def main_loop(fps = 60)
    create_screen unless @@ran_create_screen
    @@ran_loop = true
    @@fps = fps
    @@real_fps = 0

    do_wait = true
    @@count = 0
    @@tm_start = @@ticks = SDL.get_ticks

    until @@loop_end
      poll_event
      if block_given?
        screen.fillRect 0, 0, screen.w, screen.h, background_color if background_color
        yield screen
      end
      sync(@@fps) if do_wait
      screen.flip
    end
  end
  module_function :main_loop

  def poll_event # :nodoc:
    while event = SDL::Event2.poll
      event.class.name =~ /\w+\z/
      name = $&.gsub(/([a-z])([A-Z])/) { "#{$1}_#{$2.downcase}" }.downcase
      (@@events[name.to_sym] || {}).each {|key, block| block.call(event) }
    end
    SDL::Key.scan
  end
  module_function :poll_event

  def sync(fps) # :nodoc:
    if fps > 0
      diff = @@ticks + (1000 / fps) - SDL.get_ticks
      SDL.delay(diff) if diff > 0
    end
    @@ticks = SDL.get_ticks
    @@count += 1
    if @@count >= 30
      @@count = 0
      @@real_fps = 30 * 1000 / (@@ticks - @@tm_start)
      @@tm_start = @@ticks
    end
  end
  module_function :sync

  def fps
    @@fps
  end
  module_function :fps

  def fps=(fps)
    @@fps = fps
  end
  module_function :fps=

  def real_fps
    @@real_fps
  end
  module_function :real_fps

  def ran_main_loop? # :nodoc:
    @@ran_loop
  end
  module_function :ran_main_loop?

  def screen
    @@screen
  end
  module_function :screen

  def background_color
    @@background_color
  end
  module_function :background_color

  def background_color=(color)
    @@background_color = color
  end
  module_function :background_color=

  def set_background_color(color)
    self.background_color = color
  end
  module_function :set_background_color

  def add_event(event, key = nil, &block)
    @@events[event] || raise("unknown event type `#{event}'")
    key ||= block.object_id
    @@events[event][key] = block
    key
  end
  module_function :add_event

  def remove_event(event, key=nil)
    if key
      @@events[event].delete(key)
    else
      @@events[event].each {|key, | @@events[event].delete(key) }
    end
  end
  module_function :remove_event

  Events = %w(active key_down key_up mouse_motion mouse_button_down mouse_button_up
              joy_axis joy_ball joy_hat joy_button_up joy_button_down
              quit sys_wm video_resize).map {|e| e.to_sym } # :nodoc:
  def init_events
    Events.each {|e| @@events[e] = {} }
    add_event(:quit, :close) { @@loop_end = true }
    add_event(:key_down, :close) {|e| @@loop_end = true if e.sym == Key::ESCAPE }
    @@press_last_key = {}
  end
  module_function :init_events

  def key_pressed?(key)
    SDL::Key.press?(key)
  end
  module_function :key_pressed?

  def new_key_pressed?(key)
    flag = @@press_last_key[key] == false && SDL::Key.press?(key)
    @@press_last_key[key] = SDL::Key.press?(key)
    flag
  end
  module_function :new_key_pressed?

  def mask_rgba # :nodoc:
    masks = [0x000000ff, 0x0000ff00, 0x00ff0000, 0xff000000]
    masks.reverse! if big_endian = ([1].pack("N") == [1].pack("L"))
    masks
  end
  module_function :mask_rgba

  module Key
    include SDL::Key
  end
end
