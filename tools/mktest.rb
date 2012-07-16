#!/usr/bin/env ruby
# coding: utf-8

# weblifter.cgiの投稿結果から自動試験を作成する

require 'mechanize'
require 'pathname'

class WeblifterTestGenerator
  OUTPUT_PATH = Pathname(__FILE__).dirname + "../dist/src/test/validator"
  TEMPLATE_PATH = OUTPUT_PATH + "template.rb"

  def initialize
    @agent = Mechanize.new
  end

  # 例：post!("contest4", "DDUUDA")
  def post!(map_name, commands)
    @agent.get("http://undecidable.org.uk/~edwin/cgi-bin/weblifter.cgi") do |top_page|
      map_names = available_map_names(top_page.root)
      if not map_names.include?(map_name)
        raise ArgumentError, "map #{map_name} not found in #{map_names}"
      end

      map_page = top_page.link_with(text: "#{map_name}.map").click
      initial_map = map_page.body

      form = top_page.forms.first
      form["mapfile"] = map_name
      form["route"] = commands
      puts "posting..."
      result_page = form.submit

      replacements = {}
      replacements[:generate_time] = Time.now.iso8601
      replacements[:test_name] = "Test#{map_name.capitalize}"
      replacements[:commands] = commands.strip
      replacements[:initial_map] = initial_map.chomp
      replacements[:processed_map] = result_page.at("pre").text.chomp
      md = /Score: (\d+)/.match(result_page.root.text)
      replacements[:score] = md[1].to_i

      html_path = OUTPUT_PATH + "test_#{map_name}.html"
      test_path = OUTPUT_PATH + "test_#{map_name}.rb"
      File.write(html_path, result_page.root)
      File.write(test_path, TEMPLATE_PATH.read % replacements)

      puts "generated #{html_path.basename} #{test_path.basename}"
      puts "try to run rake!"
    end
  end

  private

  def available_map_names(doc)
    doc.search("select[name=mapfile] option").map{|o| o["value"]}
  end
end


if $0 == __FILE__
  if ARGV.size == 0
    puts "usage: #$0 mapname commands_file"
    puts "or: echo RRDLA | #$0 mapname"
  else
    map_name = ARGV.shift
    WeblifterTestGenerator.new.post!(map_name, ARGF.read)
  end
end
