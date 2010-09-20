#! /usr/bin/ruby
bots = Dir.entries(Dir.pwd + "/example_bots").collect{|x| x if x.match(/Bot.jar/)}.compact


# # # play my bot against example bots as player 1
# le_bot = 'MyBot'
# #le_bot = 'tenth_bot'
# puts "You are Player 1"
# go_first = true
# 1.upto(100) do |x|
#   bots.each do |bot|
#     # Just noticed it makes a difference where you start on maps, so run it with my bot starting first or second both
#     if go_first
#       `java -jar tools/PlayGame.jar maps/map#{x}.txt 1000 1000 log.txt "./#{le_bot}" "java -jar example_bots/#{bot}" &> poop.out`    
#       result = %x{cat poop.out | grep Player}
#       puts "#{bot} Beat #{le_bot} On map#{x}\n"        unless result.match(/Player 1/)
#     else
#       `java -jar tools/PlayGame.jar maps/map#{x}.txt 1000 1000 log.txt "java -jar example_bots/#{bot}" "./#{le_bot}" &> poop.out`    
#       result = %x{cat poop.out | grep Player}
#       puts "#{bot} Beat #{le_bot} On map#{x}\n"        unless result.match(/Player 2/)
#     end
#   end
# end




# play my bots against eachother
#bots = %w{ ninth_bot MyBot }
#bots = %w{ MyBot ninth_bot }
#bots = %w{ MyBot tenth_bot }
bots = %w{ tenth_bot MyBot }
tricks = [0,0]
1.upto(100) do |x|
#    `java -jar tools/PlayGame.jar maps/map#{x}.txt 1000 1000 log.txt "./MyBot" "./#{bot}" &> poop.out`
    `java -jar tools/PlayGame.jar maps/map#{x}.txt 1000 1000 log.txt "./#{bots[0]}" "./#{bots[1]}" &> poop.out`    
    result = %x{cat poop.out | grep Player}
    if result.match(/Player 1/)
#      puts "#{bots[0]} Beat #{bots[1]}'s Ass On map#{x}\n"
      tricks[0] = tricks[0] + 1
    else
#      puts "#{bots[1]} Beat #{bots[0]}'s Ass On map#{x}\n"
      tricks[1] = tricks[1] + 1      
    end
    puts " Map #{x}:  #{bots[0]} #{tricks[0]} vs.  #{bots[1]} #{tricks[1]}"
end


# copied from website
#java -jar tools/PlayGame.jar maps/map7.txt 1000 1000 log.txt "java MyBot" "java -jar example_bots/RandomBot.jar" | java -jar tools/ShowGame.jar

# play one of my bots against another
# java -jar tools/PlayGame.jar maps/map4.txt 1000 1000 log.txt "./first_bot" "./MyBot" | java -jar tools/ShowGame.jar
# java -jar tools/PlayGame.jar maps/map5.txt 1000 1000 log.txt "./MyBot" "./ninth_bot" | java -jar tools/ShowGame.jar

# play my bot vs prospector bot
# java -jar tools/PlayGame.jar maps/map2.txt 1000 1000 log.txt "java -jar example_bots/ProspectorBot.jar" "./MyBot" | java -jar tools/ShowGame.jar
