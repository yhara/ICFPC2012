# coding: utf-8

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

desc "やるねぇ〜"
task :yarunee do
  puts "やるねぇ〜"
end
