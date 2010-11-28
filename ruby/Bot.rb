class Bot
  attr_accessor :planet_wars, :orders, :my_planets, :enemy_planets, :neutral_planets, 
                :my_fleets, :enemy_fleets, :planets, :fleets, :turn, :enemy_origin, :my_origin,
                :my_growth_rate, :their_growth_rate, :my_ships, :their_ships, :enemy_targets, :really_ahead,
								:mode, :distances, :my_targets
  

  def initialize(mode = nil)
    @turn = 0
		@really_ahead = 0
    @orders = []
		@mode = mode
		@sim_planets = []
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
	
	def log(str, mode = 'a+', options = {})
		if options[:file]
			File.open("rubybot.log", mode) {|f|  f << str << "\n"}
		else
			$stderr.puts str + "\n"
		end
  end
  
  def log_planets(planet = nil)
    @planets.each do |x|
      ps = planet ? "distance #{distance(planet, x)}" : "no planet given"
      log("id #{x.pid}, growth #{x.growth}, ships #{x.ships}, #{ps}")
    end
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
		@my_targets = @my_fleets.collect{|f| @planets[f.destination]}.uniq

    if @turn == 1
      @enemy_origin = @enemy_planets.first
      @my_origin = @my_planets.first
			build_distances_table
    end
		
    set_incoming
    calc_my_growth_rate
		calc_their_growth_rate
		calc_my_ships
		calc_their_ships
		log("turn #{@turn}")
		log("\tgr #{my_growth_rate} vs. #{their_growth_rate}")		
		log("\tships #{@my_ships} vs. #{@their_ships}")

  end

	def build_distances_table
		@distances = Array.new(@planets.size){Array.new(@planets.size)}
		@planets.each do |p|
			@planets.each do |q|
				@distances[p.pid][q.pid] = p.distance(q)
			end
		end
#		log(@distances.inspect, 'w+', :file => true)
	end
	
	def distance(p1, p2)
		@distances[p1.pid][p2.pid]
	end
  
  def set_incoming
    @fleets.each do |x|
			@planets[x.destination].incoming << x
      if x.mine?
        @planets[x.destination].incoming_mine_i += x.ships
        @planets[x.destination].incoming_mine << x #= @planets[x.destination].incoming_mine + x.ships
        @planets[x.destination].incoming_mine_j[x.remaining_turns] += x.ships 
      elsif x.enemy?
        @planets[x.destination].incoming_enemy_i += x.ships
        @planets[x.destination].incoming_enemy << x #= @planets[x.destination].incoming_enemy + x.ships
        @planets[x.destination].incoming_enemy_j[x.remaining_turns] += x.ships
      end
    end
  end
    
  def do_turn(pw)
    @turn = @turn + 1
    @planet_wars = pw
    parse_game_state

		yield if block_given?

    finish_turn
  end

  def finish_turn
    @orders.each{|o| puts o }
    @orders = []    
    puts "go"
    $stdout.flush
  end

  def issue_order(from, to, num)
		unless num > 0 and from.ships >= num	
#			log "\tERROR num #{num} > 0    OR   from.ships #{from.ships} < num #{num}"
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
		# if to.growth == 0
		# 	log "\tERROR to.growth == 0"
		# 	return
		# end
		unless from.mine?
			log '\tERROR from is not mine'
			return
		end

	  order = "#{from.pid} #{to.pid} #{num}"

    to.incoming_mine_i += num
    from.ships -= num
		dist = distance(from, to)
    to.incoming << Fleet.new("1 #{num} #{from.pid} #{to} #{dist} #{dist}", 1000)

		to.incoming_mine_j[dist] += num
		log "\t\tORDER UP #{order}"
    @orders << order
    true
  end


  def closest_enemy(planet)
		@enemy_planets.closest(planet)
  end

  def closest_neutral(planet)
    @neutral_planets.closest(planet)
  end


end

class Array
  def closest(planet)
		return nil if planet.nil?
    self.min{|a, b| planet.distance(a) <=> planet.distance(b)}
  end
end




#end