#!/usr/bin/ruby

require './planetwars.rb'
require './bot.rb'
require './tiger_bot.rb'
#require './crime_bot.rb'

#File.open("rubybot.log", 'w+') {|f|  f << "Game On\n"}

map_data = []
#mybot = Bot.new('dog')
mybot = TigerBot.new
#mybot = CrimeBot.new
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

