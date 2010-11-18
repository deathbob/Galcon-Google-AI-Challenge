class TigerBot < Bot
	
  def do_turn(pw)
		super(pw) {
#			tiger_style
#			cow_style
			fat_style
		}
  end
  
  def issue_reinforcements
    troubled, saviors = @my_planets.partition{|x| x.in_trouble?}
		troubled = troubled.sort{|a, b| b.growth <=> a.growth}
    troubled.each do |x|

#			ren = x.reinforcements_needed
			saviors = saviors.sort{|a, b| distance(a, x) <=> distance(b, x)}
      saviors.each do |y|
				ren = x.reinforcements_needed(y)
				log("\tReinforcements needed from #{y} \n\t\t\tto #{x} -|- #{ren}")
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

	def first_turn(p)
		tmp = @not_my_planets.delete_if{|x| distance(x, @enemy_origin) < distance(x, @my_origin)}
		tmp = tmp.sort do |a, b| 
      ad = distance(p, a) 
      bd = distance(p, b) 
      (b.growth.to_f / ((bd * bd) + b.ships)) <=> (a.growth.to_f / ((ad * ad) + a.ships))
		end
		dist = distance(@my_origin, @enemy_origin)
		log("\tDist between me and enemy origin #{dist}")
		ships_to_risk = [(dist * @my_origin.growth), @my_origin.ships].min
		log "\tShips to risk (#{ships_to_risk})"
		p.ships = ships_to_risk
		first_turn_attack(tmp, p)
	end  
	
	def first_turn_attack(planet_array, attacking_planet)
		planet_array.each do |planet|
			ships_needed = planet.ships_to_take(attacking_planet)
			if attacking_planet.reinforcements_available > ships_needed
				issue_order(attacking_planet, planet, ships_needed) 
				# issue_order(attacking_planet, planet, ships_needed * 2 )
				# break
			end
		end
		issue_order(attacking_planet, planet_array.first, attacking_planet.reinforcements_available)
	end

	
	def round_robin_four(p)
#		return unless p.reinforcements_available > 1
		# NO need to do this step unless p has some ships to fight with.  check ships.reinforcements_availabl > 1 or something
		# Also save 20 ships in reserve if this is the original planet ...
		@not_my_planets = @not_my_planets.sort do |a, b|
			ad = distance(p, a) #p.distance(a)
			bd = distance(p, b) #p.distance(b)
			(b.growth.to_f / ((bd * bd) + b.ships)) <=> (a.growth.to_f / ((ad * ad) + a.ships))
#   		(b.growth.to_f / ((bd * bd) + b.ships_to_take(p))) <=> (a.growth.to_f / ((ad * ad) + a.ships_to_take(p))) # This really isn't as good as just ships
		end
		stream_with_reserves(@not_my_planets, p)
	end

	def round_robin_five
		tmp = @not_my_planets.sort do |a, b|
			ad = distance(@my_origin, a) #p.distance(a)
			bd = distance(@my_origin, b) #p.distance(b)
#			(b.growth.to_f / ((bd * bd) + b.ships)) <=> (a.growth.to_f / ((ad * ad) + a.ships))
			(b.growth.to_f / ((bd) + b.ships_to_take(@my_origin))) <=> (a.growth.to_f / ((ad) + a.ships_to_take(@my_origin)))			
		end
		stream_with_reserves_new(tmp)
	end
	
	
	def rounder_one
		zap = @my_planets.closest(@enemy_origin)
		return if zap.nil?
		tmp = @not_my_planets.delete_if{|x| distance(x, @enemy_origin) < distance(x, zap)}
		tmp = tmp.sort do |a, b|
			ad = distance(zap, a) #p.distance(a)
			bd = distance(zap, b) #p.distance(b)
#			(b.growth.to_f / ((bd * bd) + b.ships)) <=> (a.growth.to_f / ((ad * ad) + a.ships))
#			(b.growth.to_f / ((bd) + b.ships_to_take(@my_origin))) <=> (a.growth.to_f / ((ad) + a.ships_to_take(@my_origin)))			
			a.ships_to_take(zap) <=> b.ships_to_take(zap)
		end
		stream_with_reserves_new(tmp)
	end
	
	def stream_with_reserves_new(planet_array)
		@my_planets.each do |x|
			planet_array.each do |planet|
				if planet.enemy? 
#					tom = @enemy_planets.closest(x)
					tom = @not_my_planets.closest(x)					
					if planet != tom
						planet = tom
					end
				end
				
				
				ships_needed = planet.ships_to_take(x)
				next if ships_needed < 1
				ria = x.reinforcements_available
				break if ria < 1
				issue_order(x, planet, [x.reinforcements_available, ships_needed].min)
			end
		end
	end

	def stream_with_reserves(planet_array, attacking_planet)
		planet_array.each do |planet|
			if planet.enemy? 
				tom = @enemy_planets.closest(attacking_planet)
				if planet != tom
					planet = tom
				end
			end
			ships_needed = planet.ships_to_take(attacking_planet)
			next unless ships_needed > 0
			ria = attacking_planet.reinforcements_available
			next unless ria > 0

			closest = @my_planets.closest(planet)
			if (attacking_planet == closest)
				# if the attacking planet is the closest planet to the target				# do nothing
			elsif(distance(attacking_planet, planet) < distance(attacking_planet, closest))
				# if the given attacking planet is closer to the target than it is to the closest planet to the target				# do nothing, attack as planned
			else
				# If i own a planet closer to the target than the current attacking_planet				
				# change target to the closest planet / move troops to the closest planet
				planet = closest if closest
			end
			
			if (ria >= ships_needed) 
					issue_order(attacking_planet, planet, ships_needed)  # this is better than ria					
			elsif ria > attacking_planet.growth
				issue_order(attacking_planet, planet, ria) 
			end

		end
		# if attacking_planet.reinforcements_available > 1
		# 	issue_order(attacking_planet, @enemy_planets.closest(attacking_planet), attacking_planet.reinforcements_available)
		# end
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

	def cow_style
		issue_reinforcements
		round_robin_five
	end
	
	def fat_style
		issue_reinforcements
		rounder_one
	end
	# make a list of the cheapest planets to take (growth / ships) and then sort by distance
	# or sort by growth, take the top half, then sort by distance. 
	# Problem is I'm attacking neutral planets with too many ships, i could get more growth by attacking two less populated ships with slightly smaller growth(slightly further away)
  
  

  

end