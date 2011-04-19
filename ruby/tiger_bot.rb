class TigerBot < Bot
	
  def do_turn(pw)
		super(pw){
			tiger_style
		}
  end
  
  def issue_reinforcements
		log("\tReinforcements, begin -----------------------------------------------")	
#    troubled, saviors = (@my_planets + @my_targets).partition{|x| x.in_trouble?}
    junk, saviors = (@my_planets).partition{|x| x.in_trouble?}
    troubled, junk = (@my_planets + @my_targets).partition{|x| x.in_trouble?}
		troubled = troubled.sort{|a, b| b.growth <=> a.growth}
    troubled.each do |x|
			ren = x.reinforcements_needed			
			order_q = []			
      saviors.each do |y|
        if ren < y.reinforcements_available
					log("\tReinforcements, have enough, #{ren} needed for #{x.pid}, #{y.pid} has #{y.reinforcements_available}")	
          issue_order(y, x, ren + 1)
					ren = 0
#					break # don't send anybody else because we're all good now. 
        else
					if y.reinforcements_available > 1						
						yra = y.reinforcements_available #/ 2
						log("\tReinforcements, don't have enough,  #{ren} needed for #{x.pid}, #{y.pid} has #{y.reinforcements_available}")						
#						issue_order(y, x, yra)
						order_q << [y, x, yra]
						ren -= yra
					end
        end
      end # ends saviors loop
			if ren < 10
				order_q.each do |qo|
					issue_order(qo[0], qo[1], qo[2])
				end
			end

    end
		log("\tReinforcements, END -----------------------------------------------")	
  end

	def round_robin_four(p)
		if @my_planets.size < 2
			tom = p#@my_planets.first
#			jerry = @enemy_planets.closest(tom)
			jerry = @enemy_planets.closest(p)
			dist = distance(tom, jerry)
			log("\tDist between tom and jerry #{dist}")
			if (dist < 14)
				ships_to_reserve = (100 - ((dist + 1) * tom.growth)) - (@turn * tom.growth)
				log("\ttom.ships: #{tom.ships} ")
				log("\tships_to_reserve: #{ships_to_reserve}")				
				if ships_to_reserve > 0
					tom.ships -= ships_to_reserve
				end
				log("\ttom.ships: #{tom.ships} ")				
			end
		end
		tmp = @not_my_planets.sort do |a, b|
			ad = distance(p, a) 
			bd = distance(p, b) 
			(b.growth.to_f / ((bd * bd ) + b.ships_to_take(p))) <=> (a.growth.to_f / ((ad * ad) + a.ships_to_take(p)))
		end
		stream_with_reserves(tmp, p)
	end




	def stream_with_reserves(planet_array, attacking_planet)
		planet_array.each do |planet|
			ria = attacking_planet.reinforcements_available
			break if ria <= 0			
			ships_needed = planet.ships_to_take(attacking_planet)			
			log("\t\t#{attacking_planet.pid} has #{ria} ria; ships needed to take #{planet.pid} = #{ships_needed}")

			if (ria >= ships_needed) 
				issue_order(attacking_planet, planet, ships_needed) 
			else
				if @current_focus && @current_focus.ships_to_take(attacking_planet) >= 1
					log("\t\t #{attacking_planet.pid} has #{ria} ria; ships needed to take CURRENT FOCUS #{@current_focus.pid} = #{@current_focus.ships_to_take(attacking_planet)}")					
					issue_order(attacking_planet, @current_focus, ria) 
				else
					if @center && (@center != attacking_planet)
						log("\tmoving ships to center #{@center.pid}")	
						issue_order(attacking_planet, @center, ria)
					else
						break
					end
				end
			end
		end
	end
	

	
	def tiger_style
		issue_reinforcements
		@my_planets = @my_planets.sort{|a,b| b.growth <=> a.growth}
		set_focus		
		set_center

#		@current_focus = most_desirable(@my_planets.first)
		log("\tCurrent Focus #{@current_focus.pid}") if @current_focus
		@my_planets.each do |p|
			round_robin_four(p)
		end
	end
	
	# def set_focus
	# 	av_x, av_y = 0.0, 0.0
	# 	@not_my_planets.each do |mp|
	#       av_x += mp.x
	#  			av_y += mp.y
	#     end
	# 	av_x = av_x / @not_my_planets.size
	# 	av_y = av_y / @not_my_planets.size
	# 	@current_focus = @not_my_planets.min do |a, b|
	# 		((a.x - av_x).abs + (a.y - av_y).abs) <=> ((b.x - av_x).abs + (b.y - av_y).abs)
	# 	end
	# end
	def set_focus
		av_x, av_y = 0.0, 0.0
		@enemy_planets.each do |mp|
	      av_x += mp.x
	 			av_y += mp.y
	    end
		av_x = av_x / @enemy_planets.size
		av_y = av_y / @enemy_planets.size
		@current_focus = @enemy_planets.min do |a, b|
			((a.x - av_x).abs + (a.y - av_y).abs) <=> ((b.x - av_x).abs + (b.y - av_y).abs)
		end
	end
	
	def set_center
		@center = @my_planets.closest(@current_focus)
		# av_x, av_y = 0.0, 0.0
		# @my_planets.each do |mp|
		#       av_x += mp.x
		#  			av_y += mp.y
		#     end
		# av_x = av_x / @my_planets.size
		# av_y = av_y / @my_planets.size
		# @center = @my_planets.min do |a, b|
		# 	((a.x - av_x).abs + (a.y - av_y).abs) <=> ((b.x - av_x).abs + (b.y - av_y).abs)
		# end
	end

	def most_desirable(p)
		return nil unless p
		@not_my_planets.max do |a, b|
			ad = distance(p, a) 
			bd = distance(p, b) 
#			((a.growth * a.growth) - ad) <=> ((b.growth * b.growth) - bd)
#			((a.growth) - ad) <=> ((b.growth) - bd)			 # this won a game.  
			(a.growth - a.ships_to_take(p) - ad) <=> (b.growth - b.ships_to_take(p) - bd)
		end
	end  
  

  

end