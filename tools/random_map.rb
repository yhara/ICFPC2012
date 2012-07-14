#!/usr/bin/env ruby
# coding: utf-8
require 'trollop'

class Mine
  def initialize(wid, hei)
    @wid, @hei = wid, hei
    @mine = Array.new(hei){ Array.new(wid){ nil } }
    @extra = ""
  end
  attr_accessor :extra

  # 左下が1,1
  def [](x,y)
    unless (1..@wid) === x && (1..@hei) === y
      raise ArgumentError, "out of bound: (#{x}, #{y})"
    end
    @mine[@hei - (y-1) - 1][x - 1]
  end

  def []=(x, y, value)
    xx = x - 1
    yy = @hei - y
    unless (0..@wid-1) === xx && (0..@hei-1) === yy
      raise ArgumentError, "out of bound: (#{x}, #{y}) (real: #{xx}, #{yy})"
    end
    @mine[yy][xx] = value
  end

  def to_s
    @mine.map{|row|
      row.map{|item|
        case item
        when String then item
        when nil then " "
        end
      }.join + "\n"
    }.join + @extra
  end
end

opts = Trollop.options do
  banner "usage: #$0 [options]"

  opt :width, "mapの幅(デフォルト: 10)", default: 10
  opt :height, "mapの高さ(デフォルト: 10)", default: 10
  opt :type, "タイプ(easy/mid)", default: "easy"
  opt :flood, "洪水があるかどうか", default: false
  opt :help, "ヘルプ", short: :none
end
Trollop.die if opts[:help] 

wid = opts[:width]
hei = opts[:height]

mine = Mine.new(wid, hei)

# 壁生成
(1..wid).each{|x| mine[x, 1] = "#"; mine[x, hei] = "#"}
(1..hei).each{|y| mine[1, y] = "#"; mine[wid, y] = "#"}

# 中身生成
objects = ("*"*10 + "\\"*10 + "."*70 + " "*30).chars.to_a
(2..wid-1).each do |x|
  (2..hei-1).each do |y|
    mine[x, y] = objects.sample
  end
end

# 壁2
if opts[:type] == "mid"
  #obstacle = Array.new(@wid)
end

# ゴール生成
mine[rand(wid-2)+2, 1] = "L"

# スタート生成
mine[rand(wid-2)+2, hei-1] = "R"

# 洪水
if opts[:flood]
  water = rand(hei / 5)
  flooding = rand(hei / 10) + 1
  waterproof = rand(flooding*2) + (flooding*3)
  mine.extra = [
    "",
    "Water #{water}",
    "Flooding #{flooding}",
    "Waterproof #{waterproof}",
  ].join("\n")
end

puts mine.to_s
