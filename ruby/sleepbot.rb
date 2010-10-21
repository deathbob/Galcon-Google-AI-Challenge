#!/usr/bin/ruby

require './planetwars.rb'
require './bot.rb'

#File.open("rubybot.log", 'w+') {|f|  f << "Game On\n"}

map_data = []
sleepbot = Bot.new('sleep')
while true
  current_line = gets
  next unless current_line
  if current_line.match /go/
    p = PlanetWars.new(map_data)
    sleepbot.do_turn(p)
    map_data = []
  else
    map_data << current_line
  end
end
