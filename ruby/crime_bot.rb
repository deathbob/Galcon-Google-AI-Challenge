class TigerBot < Bot
	
  def do_turn(pw)
		super(pw){
			tiger_style
		}
  end
  
  def issue_reinforcements
    troubled, saviors = (@my_planets + @my_targets).partition{|x| x.in_trouble?}
		troubled = troubled.sort{|a, b| b.growth <=> a.growth}
    troubled.each do |x|
			saviors = (saviors - @my_targets).sort{|a, b| distance(a, x) <=> distance(b, x)}
      saviors.each do |y|
				ren = x.reinforcements_needed(y)
        if ren <= y.reinforcements_available
          issue_order(y, x, ren)
					break # don't send anybody else because we're all good now. 
        else
					if y.reinforcements_available > 1						
						yra = y.reinforcements_available #/ 2
						issue_order(y, x, yra)
						ren -= yra
					end
        end
      end
    end
  end

	def round_robin_four(p)
		if @my_planets.size < 2
			tom = @my_planets.first
			jerry = @enemy_planets.closest(tom)
			dist = distance(tom, jerry)
			log("\tDist between tom and jerry #{dist}")
			if (dist < 14)
				if @turn == 1
					return
				end
				ships_to_reserve = (100 - ((dist - 3) * tom.growth)) - (@turn * tom.growth)
				log("\ttom.ships: #{tom.ships} ")
				log("\tships_to_reserve: #{ships_to_reserve}")				
				if ships_to_reserve > 0
					tom.ships -= ships_to_reserve
				end
				log("\ttom.ships: #{tom.ships} ")				
			end
		end
#		return unless p.reinforcements_available > 1
		# NO need to do this step unless p has some ships to fight with.  check ships.reinforcements_availabl > 1 or something
		# Also save 20 ships in reserve if this is the original planet ...
		tmp = @not_my_planets.sort do |a, b|
			ad = distance(p, a) 
			bd = distance(p, b) 
			(b.growth.to_f / ((bd * bd ) + b.ships_to_take(p))) <=> (a.growth.to_f / ((ad * ad) + a.ships_to_take(p)))
#			(a.ships_to_take(p) <=> b.ships_to_take(p))
#			(b.growth.to_f / (bd + b.ships_to_take(p))) <=> (a.growth.to_f / (ad + a.ships_to_take(p)))
#			(b.growth / (b.ships_to_take(p) + 1)) <=> (a.growth / (a.ships_to_take(p) + 1))
#			a.ships <=> b.ships
#			(b.value(p) / (b.ships_to_take(p) + 1)) <=> (a.value(p) / (a.ships_to_take(p) + 1))			
		end
		stream_with_reserves(tmp, p)
	end




	def stream_with_reserves(planet_array, attacking_planet)
		#return unless attacking_planet.reinforcements_available > 0

		planet_array.each do |planet|
			# if planet.enemy? 
			# 	tom = @enemy_planets.closest(attacking_planet)
			# 	if planet != tom
			# 		planet = tom
			# 	end
			# end
			
			tom = @enemy_planets.closest(attacking_planet)
			if distance(attacking_planet, tom) < distance(attacking_planet, planet)
#				sloop = tom.ships_to_take(attacking_planet)
				planet = tom #if sloop > 0
			end if tom
			
			# if planet.enemy? 
			# 	tom = @not_my_planets.closest(attacking_planet)
			# 	if planet != tom
			# 		planet = tom
			# 	end
			# end
			
			# tom = @not_my_planets.closest(attacking_planet)
			# if distance(attacking_planet, tom) < distance(attacking_planet, planet)
			# 	sloop = tom.ships_to_take(attacking_planet)
			# 	planet = tom if sloop > 0
			# end if tom
			# 
			# NOt sure if this is good to do or not but going to try it.  
			# Sometimes Seem to lose because edge planets are weak.
			closest = @my_planets.closest(planet)
			if (attacking_planet == closest)
				# if the attacking planet is the closest planet to the target				# do nothing
			elsif(distance(attacking_planet, planet) < distance(attacking_planet, closest))
				# if the given attacking planet is closer to the target than it is to the closest planet to the target				
				# do nothing, attack as planned
			else
				# If i own a planet closer to the target than the current attacking_planet				
				# change target to the closest planet / move troops to the closest planet
				planet = closest
			end if closest
			
			ships_needed = planet.ships_to_take(attacking_planet)
			log("Ships to take #{planet.pid} = #{ships_needed}")
			ria = attacking_planet.reinforcements_available
			if (ria >= ships_needed) 
				issue_order(attacking_planet, planet, ships_needed) 
				issue_order(attacking_planet, planet, attacking_planet.reinforcements_available / 3) 
			elsif ria > attacking_planet.growth && @turn.even?
				issue_order(attacking_planet, planet, ria) 
			end

		end
	end
	
	

	
	def tiger_style
		issue_reinforcements
		@my_planets.sort{|a,b| b.growth <=> a.growth}.each do |p|
			round_robin_four(p)
		end
		##############################################################################################
		# need to add some logic to reinforcements to only send if i can make it in time
		# need to add some logic to take strategic planets in between my planets and their ultimate goal. 
		# need to stream fleets to front lines?  That way i can attack more directly and support vulnerable planets at the same time. 
	end

	# make a list of the cheapest planets to take (growth / ships) and then sort by distance
	# or sort by growth, take the top half, then sort by distance. 
	# Problem is I'm attacking neutral planets with too many ships, i could get more growth by attacking two less populated ships with slightly smaller growth(slightly further away)
  
  

  

end