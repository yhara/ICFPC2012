#!/usr/bin/env ruby
# coding: utf-8
# weblifter.cgiへの投稿を自動化する
require 'mechanize'

class WebLifting
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

      form = top_page.forms.first
      form["mapfile"] = map_name
      form["route"] = commands
      puts "posting..."

      result_page = form.submit
      File.write("result.html", result_page.root.to_html)
      puts "wrote result.html"
    end
  end

  private
  def available_map_names(doc)
    doc.search("select[name=mapfile] option").map{|o| o["value"]}
  end

  def parse_result_html(doc)
    doc
  end
end


if $0 == __FILE__
  if ARGV.size == 0
    puts "usage: #$0 mapname < commands_file"
    puts "or: echo RRDLA | #$0 mapname"
  else
    WebLifting.new.post!(ARGV[0], $stdin.read)
  end
end
