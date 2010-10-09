class Bot
  attr_accessor :planet_wars, :orders, :my_planets, :enemy_planets, :neutral_planets, 
                :my_fleets, :enemy_fleets, :planets, :fleets, :turn, :enemy_origin, :my_origin,
                :my_growth_rate, :their_growth_rate, :my_ships, :their_ships, :enemy_targets, :really_ahead
  

  def initialize
    @turn = 0
		@really_ahead = 0
    @orders = []
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
	
	def log(str)
		$stderr.puts str + "\n"
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
		
    # log "my origin #{@my_origin.pid}\n"
    # log "enemy_origin #{@enemy_origin.pid}\n"
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
      if x.owner == 1
        @planets[x.destination].incoming_mine = @planets[x.destination].incoming_mine + x.ships
      elsif x.owner == 2
        @planets[x.destination].incoming_enemy = @planets[x.destination].incoming_enemy + x.ships
      end
    end
  end
    
  
  def do_turn(pw)
    @turn = @turn + 1
#    log "Turn #{@turn}"
    @planet_wars = pw
    parse_game_state
    snake_style #unless turn == 1
    finish_turn
  end
  
  def log_planets(planet = nil)
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
#				$stderr.puts "reinforcements_available #{x.reinforcements_available}, ships #{x.ships}, incoming_enemy #{x.incoming_enemy}"	
        if x.reinforcements_needed < y.reinforcements_available
          issue_order(y, x, x.reinforcements_needed)
        else
					if y.reinforcements_available > 0
						issue_order(y, x, y.reinforcements_available)
					end
        end
      end
    end
  end
  

	def round_robin(p)
		log("\t round robin")
		@not_my_planets = @not_my_planets.sort do |a, b|
      ad = p.distance(a)
      bd = p.distance(b)
			# need to divide the distance part by 2 to mitigate the effects of it.  
			# actually that seems to do a little worse
#      (b.growth.to_f / ((bd * bd / 2) + b.ships)) <=> (a.growth.to_f / ((ad * ad / 2) + a.ships))
      (b.growth.to_f / ((bd * bd) + b.ships)) <=> (a.growth.to_f / ((ad * ad) + a.ships))
		end
		attack_with_reserves(@not_my_planets, p)
	end

	def mass_assault(p)
		log("\t mass_assault")
		@enemy_planets.sort do |a, b|
      ad = p.distance(a)
      bd = p.distance(b)
      (b.growth.to_f / ((bd * bd) + b.ships)) <=> (a.growth.to_f / ((ad * ad) + a.ships))
		end
		attack_with_reserves(@enemy_planets, p)
	end

	def mass_assault_two(p)
		log "\t mass assault two"
		@enemy_planets = @enemy_planets.sort{|a, b|	b.ships_to_take(p) <=> a.ships_to_take(p)	}
#		attack_with_reserves(@enemy_planets, p)
		attack_without_reserves(@enemy_planets, p)
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
			if attacking_planet.ships > ships_needed
				issue_order(attacking_planet, planet, ships_needed) unless attacking_planet.would_be_in_trouble(ships_needed)
			else
				issue_order(attacking_planet, planet, attacking_planet.reinforcements_available)
				break
			end
		end
	end
	
	def mirror_mode
		@enemy_targets = @enemy_fleets.collect{|f| @planets[f.destination]}
		@my_planets.each do |p|
			@enemy_targets.each do |x|
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
		log("\t sniping")
		targets = @enemy_targets.map{|x| @planets[x] if @planets[x].neutral?}.compact
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
		snipe_their_targets
	end
	
  
  def snake_style
		issue_reinforcements
		@my_planets.each do |p|
			# need to work snipe_their_targets in there somewhere
			if behind_on_growth
				@really_ahead = 0
				round_robin(p)
#				nasty(p) # not real good, end up taking a lot of small growth planets usually
#				half_kill(p) # better, still needs more testing to figure out where it really lands. 
			elsif behind_on_ships
#				round_robin(p)
#				nasty(p)
				snipe_their_targets
#				snipe_their_targets
				# do nothing, just wait until catch up on ships
			else
				@really_ahead = @really_ahead + 1
				if @really_ahead > 1
					mass_assault_two(p) 
# 				mass_assault(p)
#	  			half_kill(p) # do this after mass_assault in case there were no targets we could take.  Continue to spread.
				end
			end
		end
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
  
  def weakest_enemy(planet)
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
    closest_to_their_origin = @my_planets.closest(@enemy_origin)
    @not_my_planets.min do |a, b|
      (closest_to_their_origin.distance(a) + @enemy_origin.distance(a)) <=> (closest_to_their_origin.distance(b) + @enemy_origin.distance(b))
    end
  end
  
  def finish_turn
    @orders.each{|o| puts o }
    @orders = []    
    puts "go"
    $stdout.flush
  end
  
  def issue_order(from, to, num)
    return unless num > 0 and from.ships >= num
    return unless from && to
		return if from == to # 
		return if to.growth == 0
    
    to.incoming_mine = to.incoming_mine + num
    from.ships = from.ships - num
        
    order = "#{from.pid} #{to.pid} #{num}"
    @orders << order
    true
  end
  
  # def log(str, mode = 'a+')
  #   File.open("rubybot.log", mode) {|f|  f << str << "\n"}
  # end
  
end

class Array
  def closest(planet)
    self.min{|a, b| planet.distance(a) <=> planet.distance(b)}
  end
end




#end