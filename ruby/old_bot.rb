class TigerBot < Bot
	
	def simulate
		@sim_planets = @planets
		@sim_planets.each do |p|
			mj = p.incoming_mine_j[1]
			ej = p.incoming_enemy_j[1]
			if p.neutral?
				pj = p.ships
				tom = [pj, mj, ej].sort
				net = tom[2] - tom[1]
				p.ships = net
				if tom[2] == pj
					p.owner = 0
				elsif tom[2] == ej
					p.owner = 2
				else 
					p.owner = 1
				end
			elsif p.mine? # planet started as mine
				p.ships += p.growth
				p.ships += mj
				p.ships -= ej
				if p.ships < 0
					p.owner = 2
					p.ships = p.ships.abs
				end
			else # started as theirs (enemy)
				p.ships += p.growth
				p.ships += ej
				p.ships -= mj
				if p.ships < 0
					p.owner = 1
					p.ships = p.ships.abs
				end
			end
		end
	end
  
####################################################################################################################
####################################################################################################################
### DO TURN #######
  def do_turn(pw)
		super(pw) {
			tiger_style
# 			case @mode
# 			when 'snake'
# 				snake_style
# 			when 'sleep'
# 			when 'tiger'
# 				tiger_style_two
# 			when 'dog'
# 				doggie_style
# 			else
# 				tiger_style
# #			crazy_style
# #			worm
# #			snake_style_two
# #			snake_style_three
# 			end
		}
  end
  
  def lg_planets(planet = nil)
    @planets.each do |x|
      ps = planet ? "distance #{planet.distance(x)}" : "no planet given"
      log("id #{x.pid}, growth #{x.growth}, ships #{x.ships}, #{ps}")
    end
  end
  
  def issue_reinforcements
    troubled, saviors = @my_planets.partition{|x| x.in_trouble?}
		troubled = troubled.sort{|a, b| b.growth <=> a.growth}
    troubled.each do |x|

			ren = x.reinforcements_needed					
			saviors = saviors.sort{|a, b| a.distance(x) <=> b.distance(x)}
      saviors.each do |y|
        if ren < y.reinforcements_available
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
		@not_my_planets = @not_my_planets.delete_if{|x| x.distance(@enemy_origin) < x.distance(@my_origin)}
		@not_my_planets = @not_my_planets.sort do |a, b| 
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
		first_turn_attack(@not_my_planets, p)
	end

	def first_turn_two(p)
		@not_my_planets = @not_my_planets.delete_if{|x| x.distance(@enemy_origin) < x.distance(@my_origin)}
		@not_my_planets = @not_my_planets.sort do |a, b| 
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
		first_turn_attack(@not_my_planets, p)
	end
  

	def round_robin(p)
		@not_my_planets = @not_my_planets.sort do |a, b|
      ad = p.distance(a)
      bd = p.distance(b)
      (b.growth.to_f / ((bd * bd) + b.ships)) <=> (a.growth.to_f / ((ad * ad) + a.ships))
		end
		attack_with_reserves(@not_my_planets, p)
	end

	
	def round_robin_two(p)
#		@not_my_planets = @not_my_planets.sort{ |a, b| (a.ships_to_take(p).to_f / a.growth) <=> (b.ships_to_take(p).to_f / b.growth }
		@not_my_planets = @not_my_planets.sort do |a, b| 
      ad = p.distance(a)
      bd = p.distance(b)			
      (b.growth.to_f / ((bd * bd) + b.ships_to_take(p))) <=> (a.growth.to_f / ((ad * ad) + a.ships_to_take(p)))
		end
		attack_with_reserves(@not_my_planets, p)
	end

	def round_robin_three(p)
		if p.doomed?
#			log "\t***DOOMED***"
			targ = most_desireable(p)
			issue_order(p, targ, p.ships)
			return
		end
		@not_my_planets = @not_my_planets.sort do |a, b| 
			bs = b.ships_to_take(p)
			bs = 100 if bs == 0
			as = a.ships_to_take(p)
			as = 100 if as == 0
			bd = p.distance(b)
			ad = p.distance(a)
#      (b.growth.to_f / (bs + (10 * p.distance(b)))) <=> (a.growth.to_f / (as + (10 * p.distance(a))))
      (b.growth.to_f / (bs + (bd * bd))) <=> (a.growth.to_f / (as + (ad * ad)))
		end
		attack_with_reserves(@not_my_planets, p)
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
	
	def round_robin_five(p)
		@not_my_planets = @not_my_planets.sort do |a, b|
      ad = p.distance(a)
      bd = p.distance(b)
#   		(b.growth.to_f / ((bd * bd) + b.ships_to_take(p))) <=> (a.growth.to_f / ((ad * ad) + a.ships_to_take(p))) 
   		(b.growth.to_f / ((bd * bd) + b.ships)) <=> (a.growth.to_f / ((ad * ad) + a.ships)) 
			# (b.growth.to_f / b.ships_to_take(p)) <=> (a.growth.to_f / a.ships_to_take(p)) # not badd		    
			# ((b.growth.to_f / (bd * bd)) * (1 / ( 1 + b.ships_to_take(p)))) <=> ((a.growth.to_f / (ad * ad)) * ( 1 / ( 1 + a.ships_to_take(p)))) # not as good as four      
			# (b.growth.to_f / ((2 * bd * bd) + b.ships)) <=> (a.growth.to_f / ((2 * ad * ad) + a.ships)) # better than some, but not as good as b.ships      
			# (b.growth.to_f / ((2 * bd * bd) + b.ships_to_take(p))) <=> (a.growth.to_f / ((2 * ad * ad) + a.ships_to_take(p))) # slightly less terrible      
			# ((b.growth.to_f / bd) * (1 / ( 1 + b.ships_to_take(p)))) <=> ((a.growth.to_f / (ad)) * ( 1 / ( 1 + a.ships_to_take(p)))) # terrible      
			# (b.growth.to_f / ((bd) + b.ships)) <=> (a.growth.to_f / ((ad) + a.ships)) # terrible        			
			# (b.ships_to_take(p)) <=> (a.ships_to_take(p)) # terrible			
		end
		stream_with_reserves_two(@not_my_planets, p)		
	end
	
	def mass_assault(p)
		@enemy_planets = @enemy_planets.sort do |a, b|
      ad = p.distance(a)
      bd = p.distance(b)
      (b.growth.to_f / ((bd * bd) + b.ships)) <=> (a.growth.to_f / ((ad * ad) + a.ships))
		end
		attack_with_reserves(@enemy_planets, p)
	end

	def mass_assault_two(p)
		@enemy_planets = @enemy_planets.sort{ |a, b|	b.ships_to_take(p) <=> a.ships_to_take(p)	}
		attack_with_reserves(@enemy_planets, p)
	end
	
	def attack_without_reserves(planet_array, attacking_planet)
		planet_array.each do |planet|
			ships_needed = planet.ships_to_take(attacking_planet)
			if attacking_planet.ships > ships_needed
				issue_order(attacking_planet, planet, ships_needed)
			else
				issue_order(attacking_planet, planet, attacking_planet.ships - 1)
				break
			end
		end
	end
	
	def attack_with_reserves(planet_array, attacking_planet)
		planet_array.each do |planet|
			ships_needed = planet.ships_to_take(attacking_planet)
			next unless ships_needed > 0
			ria = attacking_planet.reinforcements_available			
			if (ria > ships_needed) 
				issue_order(attacking_planet, planet, ships_needed) 
			else
				issue_order(attacking_planet, planet, ria / 2) if ria > 2
			end
		end
	end
	
	def stream_with_reserves(planet_array, attacking_planet)
		planet_array.each do |planet|

			ships_needed = planet.ships_to_take(attacking_planet)
			next unless ships_needed > 0
			ria = attacking_planet.reinforcements_available
			next unless ria > 0

			closest = @my_planets.closest(planet)
			if (attacking_planet == closest)
				# if the attacking planet is the closest planet to the target
				# do nothing
			elsif (attacking_planet.distance(planet) < attacking_planet.distance(closest))
				# if the given attacking planet is closer to the target than it is to the closest planet to the target
				# do nothing, attack as planned
			else
				# If i own a planet closer to the target than the current attacking_planet
				# change target to the closest planet / move troops to the closest planet
				planet = closest if closest
			end

			if (ria >= ships_needed) 
				issue_order(attacking_planet, planet, ships_needed)  # this is better
#				issue_order(attacking_planet, planet, ria)
			elsif ria > 6
				# Test this (5) then test attacking the closest enemy to what is now the current closest 
				# Need to turn aggressive at some point.  
				issue_order(attacking_planet, planet, ria) 
			end

		end
	end
	
	def stream_with_reserves_two(planet_array, attacking_planet)
		planet_array.each do |planet|

			ships_needed = planet.ships_to_take(attacking_planet)
			next unless ships_needed > 0
			ria = attacking_planet.reinforcements_available
			next unless ria > 0
			
			closest = @my_planets.closest(planet)
			if (attacking_planet == closest)
				# if the attacking planet is the closest planet to the target
				# do nothing
			elsif (attacking_planet.distance(planet) < attacking_planet.distance(closest))
				# if the given attacking planet is closer to the target than it is to the closest planet to the target
				# do nothing, attack as planned
			else
				# If i own a planet closer to the target than the current attacking_planet
				# change target to the closest planet / move troops to the closest planet
				planet = closest if closest
			end

			if (ria >= ships_needed) 			
#				issue_order(attacking_planet, planet, ria)
				issue_order(attacking_planet, planet, ships_needed) 
			elsif ria > 6
				issue_order(attacking_planet, planet, ria)
			end
		end
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
	
	def snake_style_three
		if @turn == 1
			targ = most_desireable(@my_origin)
			issue_order(@my_origin, targ, targ.ships_to_take(@my_origin))
		else
			issue_reinforcements
			@my_planets.each do |p|
				round_robin_three(p)
			end
		end
	end
	
  def snake_style_two
		issue_reinforcements
		targ = closest_to_me_and_enemy_origin	
		
		@my_planets.each do |p|
			if @turn == 1
				first_turn(p)
			end
			if !behind_on_ships
				focus_fire_two(p, targ)
			else
				round_robin_two(p)
			end
		end
	end
	
  
  def snake_style
		return if @turn == 1
		issue_reinforcements

		if ( !behind_on_ships && !behind_on_growth )
			@really_ahead += 1
		else
			@really_ahead -= 1 if (@really_ahead > 0)
		end
		log("really ahead #{@really_ahead}")
		targ = closest_to_me_and_enemy_origin	
		# 	log "\ttarg = #{targ.to_s},\t owned by #{targ.mine? ? 'me' : 'enemy'}" if targ
		@my_planets.each do |p|
			if @really_ahead > 2			
#				mass_assault(p) 
				mass_assault_two(p)
#				focus_fire(p, targ)
			else
				if @turn < 10
					round_robin(p)
				else
					round_robin_two(p)
				end
			end
		end
  end

	def tiger_style

		issue_reinforcements
		@my_planets.each do |p|
			if @turn == 1
				first_turn(p)
			end
			round_robin_four(p)
		end
		##############################################################################################
		# need to add some gic to reinforcements to only send if i can make it in time
		# need to add some logic to take strategic planets in between my planets and their ultimate goal. 
		# need to stream fleets to front lines?  That way i can attack more directly and support vulnerable planets at the same time. 
	end

	def tiger_style_two
		issue_reinforcements
		@my_planets.each do |p|
			if @turn == 1
				first_turn_two(p)
			end
			round_robin_five(p)
		end
	end

	def worm
		issue_reinforcements
		c = closest_to_me_and_enemy_origin
		log("c #{c.to_s}")
		@my_planets.each do |p|
			if @turn == 1
				round_robin(p)
			else
				issue_order(p, c, p.ships ) # if p.ships > 4
			end
		end
	end
	
	def doggie_style
		issue_reinforcements
			
		if ( !behind_on_ships && !behind_on_growth )
			@really_ahead += 1
		else
			@really_ahead -= 1 if (@really_ahead > 0)
		end
		@my_planets.each do |p|
			if @turn == 1
				first_turn(p)
			end

			if @really_ahead < 2
				round_robin_four(p)
			else
				mass_assault_two(p)
			end
		end
	end
	
	def focus_fire(p, target)
		issue_order(p, target, p.ships ) if p.ships > 4
	end
	
	def focus_fire_two(p, target)
		tom = p.reinforcements_available(target)			
		issue_order(p, target, tom ) 
	end


	def half_kill(p)
#		@not_my_planets = @not_my_planets.sort{|a, b| ((b.growth.to_f * 2) / (b.ships + 1)) <=> ((a.growth.to_f * 2) / (a.ships + 1)) }
		@not_my_planets = @not_my_planets.sort{|a, b| ((b.growth.to_f) / (b.ships + 1)) <=> ((a.growth.to_f) / (a.ships + 1)) }
#		@not_my_planets = @not_my_planets.sort{|a, b| b.growth <=> a.growth}
		tom = @not_my_planets[0..(@not_my_planets.size / 2)]
		tom = tom.sort{|a, b| a.distance(p) <=> b.distance(p)}
		tom.each do |planet|
			ships_needed = planet.ships_to_take(p)
			if p.ships > ships_needed
				issue_order(p, planet, ships_needed) unless p.would_be_in_trouble(ships_needed)
			else
				issue_order(p, planet, (p.reinforcements_available / 2))
			end
		end
	end
	
	def nasty(p)
		@not_my_planets = @not_my_planets.sort{|a, b|	a.ships_to_take(p) <=> b.ships_to_take(p)	}
		attack_with_reserves(@not_my_planets, p)
	end
	
	def mirror_mode
		targets = @enemy_targets.collect{|t| @planets[t]}
		@my_planets.each do |p|
			targets.each do |x|
				ships = x.ships_to_take(x)
				if p.ships > ships
					issue_order(p, x, ships)
				else
					issue_order(p, x, p.ships / 2)
				end
			end
		end
	end

	def snipe_their_targets
		targets = @enemy_targets.collect{|x| @planets[x] if @planets[x].neutral?}.compact
		@my_planets.each do |mine|
			targets.sort{|a, b| a.ships_to_take(mine) <=> b.ships_to_take(mine) }.each do |x|
				ships_needed = x.ships_to_take(mine)
				if x.ships > ships_needed
					issue_order(mine, x, ships_needed)
				end
			end
		end
	end

	def crazy_style
#		issue_reinforcements
		mirror_mode
		snipe_their_targets
	end

	# make a list of the cheapest planets to take (growth / ships) and then sort by distance
	# or sort by growth, take the top half, then sort by distance. 
	# Problem is I'm attacking neutral planets with too many ships, i could get more growth by attacking two less populated ships with slightly smaller growth(slightly further away)
  
  def most_desireable(planet)
    @not_my_planets.max{|a, b|
      ad = planet.distance(a)
      bd = planet.distance(b)
      (a.growth.to_f / ((ad * ad) + a.ships)) <=> (b.growth.to_f / ((bd * bd) + b.ships))
    }
  end
  

  
  def weakest_enemy(planet=nil)
    @enemy_planets.min do |a, b| 
      a.ships <=> b.ships
    end
  end

  
  def most_vulnerable_enemy(planet)
    @enemy_planets.min do |a, b|
      ad = planet.distance(a)
      bd = planet.distance(b)
#      (a.ships + (ad * ad)) <=> (b.ships + (bd * bd))
      (a.ships + (2 * ad)) <=> (b.ships + (2 * bd))
    end
  end
  
  def closest_to_me_and_enemy_origin
		eyo = @planets[@enemy_origin.pid]
		if eyo.mine?
			eyo = weakest_enemy
		end
		return nil if eyo.nil?
    ctto = @my_planets.closest(eyo)
		return nil if ctto.nil?
		max_d = @my_origin.distance(eyo)

		cow = (@not_my_planets - [eyo]).collect do |x| 
			[x, (x.distance(ctto) + x.distance(eyo)) ]
		end
		cow = cow.sort{|a, b| a[1] <=> b[1]}
		return nil unless cow.first
		new_target = cow.first[0] 
		# if new_target == @planets[@enemy_origin.pid]
		# 	new_target = @planets[@enemy_origin.pid]
		# end
		if(new_target.distance(eyo) > ctto.distance(eyo))	|| (ctto.distance(new_target) > ctto.distance(eyo)) 
			new_target = eyo
		end
#    @not_my_planets.closest(closest_to_their_origin)		
		new_target
  end
  

  

end