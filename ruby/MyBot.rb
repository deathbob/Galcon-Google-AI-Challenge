#!/usr/bin/ruby

require 'planetwars'
require 'bot'

#File.open("rubybot.log", 'w+') {|f|  f << "Game On\n"}
# main loop
map_data = []
mybot = Bot.new
while true
  current_line = gets
  next unless current_line
  if current_line.match /go/
    p = PlanetWars.new(map_data)
    mybot.do_turn(p)
    map_data = []
  else
    map_data << current_line
  end
end


# java -jar tools/PlayGame.jar maps/map5.txt 1000 1000 log.txt "./MyBot" "./rubybot.rb" | java -jar tools/ShowGame.jar
