class CrimeBot < Bot
	
  def do_turn(pw)
		super(pw) {
			tiger_style
		}
  end
  
  def issue_reinforcements
    troubled, saviors = @my_planets.partition{|x| x.in_trouble?}
		troubled = troubled.sort{|a, b| b.growth <=> a.growth}
    troubled.each do |x|

			ren = x.reinforcements_needed					
			saviors = saviors.sort{|a, b| a.distance(x) <=> b.distance(x)}
      saviors.each do |y|
        if ren <= y.reinforcements_available
          issue_order(y, x, ren)
					break # don't send anybody else because we're all good now. 
        else
					if y.reinforcements_available > 0
						yra = y.reinforcements_available
						issue_order(y, x, yra)
						ren -= yra
					end
        end
      end
    end
  end

	def first_turn(p)
		tmp = @not_my_planets.delete_if{|x| x.distance(@enemy_origin) < x.distance(@my_origin)}
		tmp = tmp.sort do |a, b| 
      ad = p.distance(a)
      bd = p.distance(b)			
      (b.growth.to_f / ((bd * bd) + b.ships)) <=> (a.growth.to_f / ((ad * ad) + a.ships))
		end
		dist = @my_origin.distance(@enemy_origin)
		log("\tDist between me and enemy origin #{dist}")
		if dist < 10
			p.ships = 49
		else
			ships_to_risk = (p.ships - ((1.0 / (dist / 4)) * p.ships )).floor				
		end
		log "\tShips to risk #{ships_to_risk}"
#		p.ships = ships_to_risk
		first_turn_attack(tmp, p)
	end  
	
	def first_turn_attack(planet_array, attacking_planet)
		planet_array.each do |planet|
			ships_needed = planet.ships_to_take(attacking_planet)
			attacking_planet.reinforcements_available
			if attacking_planet.reinforcements_available > ships_needed
				issue_order(attacking_planet, planet, ships_needed) 
			end
		end
	end

	
	def round_robin_four(p)
		@not_my_planets = @not_my_planets.sort do |a, b|
      ad = p.distance(a)
      bd = p.distance(b)
      (b.growth.to_f / ((bd * bd) + b.ships)) <=> (a.growth.to_f / ((ad * ad) + a.ships))
#   		(b.growth.to_f / ((bd * bd) + b.ships_to_take(p))) <=> (a.growth.to_f / ((ad * ad) + a.ships_to_take(p))) # This really isn't as good as just ships
		end
		stream_with_reserves(@not_my_planets, p)
	end
	# Need to build distance table in first turn and return cached distances after that.  
	
	def stream_with_reserves(planet_array, attacking_planet)
		planet_array.each do |planet|

			ships_needed = planet.ships_to_take(attacking_planet)
			next unless ships_needed > 0
			ria = attacking_planet.reinforcements_available
			next unless ria > 0

			closest = @my_planets.closest(planet)
			if (attacking_planet == closest)
				# if the attacking planet is the closest planet to the target				# do nothing
			elsif (attacking_planet.distance(planet) < attacking_planet.distance(closest))
				# if the given attacking planet is closer to the target than it is to the closest planet to the target				# do nothing, attack as planned
			else
				# If i own a planet closer to the target than the current attacking_planet				# change target to the closest planet / move troops to the closest planet
				planet = closest if closest
			end

			if (ria >= ships_needed) 
				issue_order(attacking_planet, planet, ships_needed)  # this is better
#				issue_order(attacking_planet, planet, ria)
			elsif ria > attacking_planet.growth
				# Test this (5) then test attacking the closest enemy to what is now the current closest 
				# Need to turn aggressive at some point.  
				issue_order(attacking_planet, planet, ria) 
			end

		end
	end
	
	

	
	def tiger_style
		issue_reinforcements
		@my_planets.each do |p|
			if @turn == 1
				first_turn(p)
			else
				round_robin_four(p)
			end
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