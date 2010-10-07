class Bot
  attr_accessor :planet_wars, :orders, :my_planets, :enemy_planets, :neutral_planets, 
                :my_fleets, :enemy_fleets, :planets, :fleets, :turn, :enemy_origin, :my_origin,
                :my_growth_rate, :their_growth_rate, :my_ships, :their_ships
  

  def initialize
    @turn = 0
    @orders = []
  end
  
  def my_ship_count
    @my_ships ||= @my_planets.inject(0){|memo, x| memo + x.ships}
  end
  
  def their_ship_count
    @their_ships ||= @enemy_planets.inject(0){|memo, x| memo + x.ships}
  end
  
  def behind_on_ships
    my_ship_count < their_ship_count
  end
  
  def my_growth_rate
    @my_growth_rate ||= @my_planets.inject(0){|memo, x| memo + x.growth}
  end

  def their_growth_rate
    @their_growth_rate ||= @enemy_planets.inject(0){|memo, x| memo + x.growth}
  end
  
  def behind_on_growth
    my_growth_rate <= their_growth_rate
  end
  
  def parse_game_state
    @planets = @planet_wars.planets
    
    @neutral_planets = @planets.collect{|x| x if x.owner == 0}.compact
    
    @my_planets = @planets.collect{|x| x if x.owner == 1}.compact
    @enemy_planets = @planets.collect{|x| x if x.owner == 2}.compact
    @not_my_planets = @enemy_planets + @neutral_planets
    @fleets = @planet_wars.fleets
    @my_fleets = @planet_wars.fleets.collect{|x| x.owner == 1}
    @enemy_fleets = @planet_wars.fleets.collect{|x| x.owner == 2}
    if @turn == 1
      @enemy_origin = @enemy_planets.first
      @my_origin = @my_planets.first
    end
    # log "my origin #{@my_origin.pid}\n"
    # log "enemy_origin #{@enemy_origin.pid}\n"
    set_incoming
    
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
    troubled.each do |x|
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
  
  # def fake_style
  #   issue_reinforcements
  #   @my_planets.each do |p|
  #     if p.in_trouble?      
  #       next 
  #     end
  #     if behind_on_growth 
  # 				@not_my_planets = @not_my_planets.sort do |a, b|
  # 		      ad = p.distance(a)
  # 		      bd = p.distance(b)
  # 		      (b.growth.to_f / ((bd * bd) + b.ships)) <=> (a.growth.to_f / ((ad * ad) + a.ships))
  # 				end
  #       it = @not_my_planets.size
  #       while (p.ships > 0 && it > 0) do
  #         curr = @not_my_planets[-it]
  #         it = it - 1
  #         # bail out conditions
  #         if (p.ships < curr.ships + 1) || curr.is_as_good_as_mine
  #           next
  #         else
  #           issue_order(p, curr, (curr.ships + 1))             
  #         end
  #       end
  #     elsif behind_on_ships
  #       # do nothing
  #     else
  # 				@enemy_planets.sort do |a, b|
  # 		      ad = p.distance(a)
  # 		      bd = p.distance(b)
  # 		      (b.growth.to_f / ((bd * bd) + b.ships)) <=> (a.growth.to_f / ((ad * ad) + a.ships))
  # 				end
  # 				it = @enemy_planets.size
  # 				while((p.ships > 0) && (it > 0))
  # 					curr = @enemy_planets[-it]
  # 					if(p.ships < curr.ships)
  # 					end
  # 				end
  #       issue_order(p, most_vulnerable_enemy(p), p.ships / 2)        
  #       # issue_order(p, weakest_enemy(p), p.ships / 2) 
  #       # issue_order(p, closest_enemy(p), p.ships / 2)        
  #     end
  #   end
  #   true
  # end

	def round_robin(p)
		@not_my_planets = @not_my_planets.sort do |a, b|
      ad = p.distance(a)
      bd = p.distance(b)
			# need to divide the distance part by 2 to mitigate the effects of it.  
      (b.growth.to_f / ((bd * bd) + b.ships)) <=> (a.growth.to_f / ((ad * ad) + a.ships))
		end
		it = @not_my_planets.size
		while ((p.ships > 0) && (it > 0))
			curr = @not_my_planets[-it]
			it = it - 1
			ships_needed = curr.ships_to_take(p)
			if p.ships > ships_needed
				issue_order(p, curr, ships_needed) unless p.would_be_in_trouble(ships_needed)
			else
				# do nothing? 
				# issue_order(p, curr, p.reinforcements_available)
				it = 0
			end
		end
	end

	def mass_assault(planet)
		p = planet
		@enemy_planets.sort do |a, b|
      ad = p.distance(a)
      bd = p.distance(b)
      (b.growth.to_f / ((bd * bd) + b.ships)) <=> (a.growth.to_f / ((ad * ad) + a.ships))
		end
		it = @enemy_planets.size
		while((p.ships > 0) && (it > 0))
			curr = @enemy_planets[-it]
			it = it + 1
			ships_needed = curr.ships_to_take(p)
			if(p.ships > ships_needed)
				issue_order(p, curr, ships_needed)
			else
				# do nothing?
#				issue_order(p, curr, p.ships / 2)
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
		enemy_targets = @enemy_fleets.collect{|f| f.destination}.uniq
		enemy_targets = enemy_targets.map{|x| @planets[x] if @planets[x].neutral?}.compact
		enemy_targets.each do |target|
			@my_planets.each do |mine|
				cow = target.ships_to_take(mine)
				if mine.reinforcements_available > cow
					issue_order(mine, target, cow)
				end
			end
		end
	end
	
	def crazy_style
		issue_reinforcements
		snipe_their_targets
	end
	
  
  def snake_style
		issue_reinforcements
		@my_planets.each do |p|
			# need to work snipe_their_targets in there somewhere
			if behind_on_growth
				round_robin(p)
			elsif behind_on_ships
				# do nothing, just wait until catch up on ships
			else
				mass_assault(p)
			end
		end
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