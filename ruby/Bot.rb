class Bot
  attr_accessor :planet_wars, :orders, :my_planets, :enemy_planets, :neutral_planets, 
                :my_fleets, :enemy_fleets, :planets, :fleets, :turn, :enemy_origin, :my_origin,
                :my_growth_rate, :their_growth_rate, :my_ships, :their_ships, :enemy_targets, :really_ahead,
								:mode
  

  def initialize(mode = nil)
    @turn = 0
		@really_ahead = 0
    @orders = []
		@mode = mode
  end
  
  def calc_my_ships
    @my_ships = @my_planets.inject(0){|memo, x| memo + x.ships}
		@my_ships = @my_ships + @my_fleets.inject(0){|memo, x| memo + x.ships}
  end
  
  def calc_their_ships
    @their_ships = @enemy_planets.inject(0){|memo, x| memo + x.ships}
		@their_ships = @their_ships + @enemy_fleets.inject(0){|memo, x| memo + x.ships}
  end
  
  def behind_on_ships
    @my_ships < @their_ships
  end
  
  def calc_my_growth_rate
    @my_growth_rate = @my_planets.inject(0){|memo, x| memo + x.growth}
  end

  def calc_their_growth_rate
    @their_growth_rate = @enemy_planets.inject(0){|memo, x| memo + x.growth}
  end
	
	def log(str, mode = 'a+')
		$stderr.puts str + "\n"		
#    File.open("rubybot.log", mode) {|f|  f << str << "\n"}
  end
  
  def behind_on_growth
    @my_growth_rate <= @their_growth_rate
  end
  
  def parse_game_state
    @planets = @planet_wars.planets
    @neutral_planets = @planets.collect{|x| x if x.owner == 0}.compact
    @my_planets =      @planets.collect{|x| x if x.owner == 1}.compact
    @enemy_planets =   @planets.collect{|x| x if x.owner == 2}.compact
    @not_my_planets =  @enemy_planets + @neutral_planets

    @fleets = @planet_wars.fleets
    @my_fleets =    @planet_wars.fleets.collect{|x| x if x.owner == 1}.compact
    @enemy_fleets = @planet_wars.fleets.collect{|x| x if x.owner == 2}.compact

		@enemy_targets = @enemy_fleets.collect{|f| f.destination}.uniq

    if @turn == 1
      @enemy_origin = @enemy_planets.first
      @my_origin = @my_planets.first
    end
		
    set_incoming
    calc_my_growth_rate
		calc_their_growth_rate
		calc_my_ships
		calc_their_ships
		 log("turn #{@turn}")
		 log("\tmy growth rate #{my_growth_rate}  their growth rate #{their_growth_rate}")		
		 log("\tmy ships  #{@my_ships}  their ships #{@their_ships}")

  end
  
  def set_incoming
    @fleets.each do |x|
			@planets[x.destination].incoming << x
      if x.mine?
        @planets[x.destination].incoming_mine_i += x.ships
        @planets[x.destination].incoming_mine << x #= @planets[x.destination].incoming_mine + x.ships
      elsif x.enemy?
        @planets[x.destination].incoming_enemy_i += x.ships
        @planets[x.destination].incoming_enemy << x #= @planets[x.destination].incoming_enemy + x.ships
      end
    end
  end
    
  
  def do_turn(pw)
    @turn = @turn + 1
    @planet_wars = pw
    parse_game_state

		if @mode == 'sleep'
		else
#			snake_style
			snake_style_two
#			worm
			#	crazy_style
		end
    finish_turn
  end
  
  def lg_planets(planet = nil)
    @planets.each do |x|
      piss = planet ? "distance #{planet.distance(x)}" : "no planet given"
      log("id #{x.pid}, growth #{x.growth}, ships #{x.ships}, #{piss}")
    end
  end
  
  def issue_reinforcements
    troubled, saviors = @my_planets.partition{|x| x.in_trouble?}
		troubled = troubled.sort{|a, b| b.growth <=> a.growth}
    troubled.each do |x|
			saviors = saviors.sort{|a, b| a.distance(x) <=> b.distance(x)}
      saviors.each do |y|
        if x.reinforcements_needed < y.reinforcements_available
          issue_order(y, x, x.reinforcements_needed)
        else
					if y.reinforcements_available > 3
						issue_order(y, x, y.reinforcements_available - 1)
					end
        end
      end
    end
  end

	def first_turn(p)
		@not_my_planets = @not_my_planets.sort do |a, b| 
      ad = p.distance(a)
      bd = p.distance(b)			
      (b.growth.to_f / ((bd * bd) + b.ships_to_take(p))) <=> (a.growth.to_f / ((ad * ad) + a.ships_to_take(p)))
		end
		dist = @my_origin.distance(@enemy_origin)
		ships_to_risk = (p.ships - ((1.0 / dist) * p.ships )).floor	
		p.ships = ships_to_risk
		first_turn_attack(@not_my_planets, p)
	end
  

	def round_robin(p)
#		log("\t round robin")
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
	
	
	def mass_assault(p)
#		log("\t mass_assault")
		@enemy_planets = @enemy_planets.sort do |a, b|
      ad = p.distance(a)
      bd = p.distance(b)
      (b.growth.to_f / ((bd * bd) + b.ships)) <=> (a.growth.to_f / ((ad * ad) + a.ships))
		end
		attack_with_reserves(@enemy_planets, p)
	end

	def mass_assault_two(p)
#		log "\t mass assault two"
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
			ria = attacking_planet.reinforcements_available			
			if ria > ships_needed
				issue_order(attacking_planet, planet, ships_needed) 
			else
				issue_order(attacking_planet, planet, ria) if ria > 4
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
#			break if attacking_planet.ships <= 0
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
				# log("\tFocusing Fire Two")
				# log("\ttarg #{targ.to_s}")
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
	
		def focus_fire(p, target)
			issue_order(p, target, p.ships ) if p.ships > 4
		end
		
		def focus_fire_two(p, target)
			tom = p.reinforcements_available			
			# log("\t\tissuing order")
			# log("\t\t #{p.pid}, #{target.pid}, #{tom}")
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
		log "\t nasty"
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
	#		log("\t sniping")
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
    @not_my_planets.min{|a, b|
      ad = planet.distance(a)
      bd = planet.distance(b)
      (a.growth.to_f / ((ad * ad) + a.ships)) <=> (b.growth.to_f / ((bd * bd) + b.ships))
    }
  end
  
  def closest_neutral(planet)
    @neutral_planets.closest(planet)
  end
  
  def weakest_enemy(planet=nil)
    @enemy_planets.min do |a, b| 
      a.ships <=> b.ships
    end
  end

  def closest_enemy(planet)
    @enemy_planets.min do |a, b| 
      (planet.distance(a)) <=> (planet.distance(b))
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
  
  def finish_turn
    @orders.each{|o| puts o }
    @orders = []    
    puts "go"
    $stdout.flush
  end
  
  def issue_order(from, to, num)
		unless num > 0 and from.ships >= num	
			log "\tERROR num #{num} > 0    OR   from.ships #{from.ships} < num #{num}"
			return
		end
		unless from && to
			log "\tERROR from or to doesn't exist"
			return
		end
		if from == to 
			log "\tERROR from == to"
			return
		end
		if to.growth == 0
			log "\tERROR to.growth == 0"
			return
		end
		unless from.mine?
			log '\tERROR from is not mine'
			return
		end
				
	  order = "#{from.pid} #{to.pid} #{num}"
    
    to.incoming_mine_i += num
    from.ships -= num
        
		log "\tORDER UP #{order}"
    @orders << order
    true
  end
  

  
end

class Array
  def closest(planet)
		return nil if planet.nil?
    self.min{|a, b| planet.distance(a) <=> planet.distance(b)}
  end
end




#end