# coding: utf-8

require "pathname"
require "tmpdir"

# 実行環境の指定
deploy_to = "192.168.1.113"
submit_number = "95754150"

task :default => :test

desc "ユニットテストを実行する"
task :test do
  Dir.chdir("dist/src") do
    sh "ruby test/run-test.rb"
  end
end

desc "パッケージングを行う"
task :package do
  sh "./tools/pack.sh"
end

namespace :run do
  task :check do
    if !ENV['map']
      raise "must specify map: rake run map=./sample/contest1.map"
    end
  end

  task :task => [:check, :package] do
    map_file = ENV['map']
    raise "must specify map." if !map_file
    map_path = Pathname(map_file)
    current_path = Pathname(Dir.pwd)
    ssh_id_path = current_path + "deploy/id"
    Dir.mktmpdir do |d|
      deploy_file = "icfp-#{submit_number}.tgz"
      cp [deploy_file, map_path], d, preserve: true
      Dir.chdir(d) do
        sh "chmod go= #{ssh_id_path}"
        sh "tar cf - #{deploy_file} #{map_path.basename} | ssh -i #{ssh_id_path} icfp-run@#{deploy_to}"
      end
    end
  end

  desc "実行環境を整備する"
  task :setup do
    sh "tar cf - -C deploy dot.ssh | ssh icfp@#{deploy_to} 'sudo userdel -r icfp-run; sudo adduser --disabled-password --gecos icfp icfp-run && sudo adduser icfp-run sudo && cd /home/icfp-run && sudo tar xf - && sudo -u icfp-run cp -a dot.ssh .ssh'"
  end
end
desc "実行環境で実行する"
task :run => 'run:task'

desc "やるねぇ〜"
task :yarunee do
  puts "やるねぇ〜"
end
