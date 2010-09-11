#! /usr/bin/ruby
bots = Dir.entries(Dir.pwd + "/example_bots").collect{|x| x if x.match(/Bot.jar/)}.compact

bots.each do |bot|
  puts bot
  1.upto(100) do |x|
    puts "On map#{x}\n"
    `java -jar tools/PlayGame.jar maps/map1.txt 1000 1000 log.txt "./MyBot" "java -jar example_bots/#{bot}" &> poop.out`
    puts %x{cat poop.out | grep Player}
  end
end



# copied from website
#java -jar tools/PlayGame.jar maps/map7.txt 1000 1000 log.txt "java MyBot" "java -jar example_bots/RandomBot.jar" | java -jar tools/ShowGame.jar

# play one of my bots against another
# java -jar tools/PlayGame.jar maps/map4.txt 1000 1000 log.txt "./first_bot" "./MyBot" | java -jar tools/ShowGame.jar

