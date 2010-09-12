#! /usr/bin/ruby
bots = Dir.entries(Dir.pwd + "/example_bots").collect{|x| x if x.match(/Bot.jar/)}.compact


# # play my bot against example bots as player 1
puts "You are Player 1"
1.upto(100) do |x|
  bots.each do |bot|
    # Just noticed it makes a difference where you start on maps, so run it with my bot starting first or second both
#    `java -jar tools/PlayGame.jar maps/map#{x}.txt 1000 1000 log.txt "./MyBot" "java -jar example_bots/#{bot}" &> poop.out`
    `java -jar tools/PlayGame.jar maps/map#{x}.txt 1000 1000 log.txt "./MyBot" "java -jar example_bots/#{bot}" &> poop.out`    
#    `java -jar tools/PlayGame.jar maps/map#{x}.txt 1000 1000 log.txt "./first_bot" "java -jar example_bots/#{bot}" &> poop.out`
#    `java -jar tools/PlayGame.jar maps/map#{x}.txt 1000 1000 log.txt "./second_bot" "java -jar example_bots/#{bot}" &> poop.out`    
    result = %x{cat poop.out | grep Player}
    
    unless result.match(/Player 1/)
      puts "#{bot} Beat Your Ass On map#{x}\n"  
    end
  end
end




# # # play my bot against example bots as player 2
# puts "You are Player 2"
# 1.upto(100) do |x|
#   bots.each do |bot|
#     # Just noticed it makes a difference where you start on maps, so run it with my bot starting first or second both
# #    `java -jar tools/PlayGame.jar maps/map#{x}.txt 1000 1000 log.txt "./MyBot" "java -jar example_bots/#{bot}" &> poop.out`
#     `java -jar tools/PlayGame.jar maps/map#{x}.txt 1000 1000 log.txt "java -jar example_bots/#{bot}" "./MyBot" &> poop.out`    
# #    `java -jar tools/PlayGame.jar maps/map#{x}.txt 1000 1000 log.txt "./first_bot" "java -jar example_bots/#{bot}" &> poop.out`
# #    `java -jar tools/PlayGame.jar maps/map#{x}.txt 1000 1000 log.txt "./second_bot" "java -jar example_bots/#{bot}" &> poop.out`    
#     result = %x{cat poop.out | grep Player}
#     
#     unless result.match(/Player 2/)
#       puts "#{bot} Beat Your Ass On map#{x}\n"  
#     end
#   end
# end


# # play my bots against eachother
# bot = 'first_bot'
# 1.upto(100) do |x|
#     `java -jar tools/PlayGame.jar maps/map#{x}.txt 1000 1000 log.txt "./MyBot" "./#{bot}" &> poop.out`
#     result = %x{cat poop.out | grep Player}
#     unless result.match(/Player 1/)
#       puts "#{bot} Beat Your Ass On map#{x}\n"  
#     end
# end


# copied from website
#java -jar tools/PlayGame.jar maps/map7.txt 1000 1000 log.txt "java MyBot" "java -jar example_bots/RandomBot.jar" | java -jar tools/ShowGame.jar

# play one of my bots against another
# java -jar tools/PlayGame.jar maps/map4.txt 1000 1000 log.txt "./first_bot" "./MyBot" | java -jar tools/ShowGame.jar

# play my bot vs prospector bot
# java -jar tools/PlayGame.jar maps/map2.txt 1000 1000 log.txt "java -jar example_bots/ProspectorBot.jar" "./MyBot" | java -jar tools/ShowGame.jar
