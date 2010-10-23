class PlanetWars
  
  attr_accessor :planets, :fleets
  
  def initialize(str)
    @planets = []
    @fleets = []
    str.each do |s|
      if s.start_with? 'P'
        @planets << Planet.new(s, @planets.size)
      elsif s.start_with? 'F'
        @fleets << Fleet.new(s, @fleets.size)
      end
    end
  end
  
end

class Planet

  attr_accessor :x, :y, :owner, :ships, :growth, :pid, :incoming_mine, :incoming_enemy, :incoming, :incoming_mine_i, :incoming_enemy_i
  def initialize(str, id)
    cow = str.split
    @x = cow[1].to_f
    @y = cow[2].to_f
    @owner = cow[3].to_i
    @ships = cow[4].to_i
    @growth = cow[5].to_i
    @incoming_mine_i = 0
    @incoming_mine = []
    @incoming_enemy_i = 0
    @incoming_enemy = []
    @pid = id
		@net_inc = {}
		@incoming = []
  end
  
  def to_s
    "Planet #{@pid}: X: #{@x} Y: #{@y} Owner: #{@owner} Ships: #{@ships} Growth: #{@growth} \n"
  end
  
  def distance(planet)
    dx = self.x.to_f - planet.x.to_f
    dy = self.y.to_f - planet.y.to_f
    (Math.sqrt(dx * dx + dy * dy)).ceil
  end
  
  def in_trouble?
		if @incoming_enemy_i > 0
    	(@growth + @ships + @incoming_mine_i) <= @incoming_enemy_i + 4
		else
			false
		end
  end
  
  def is_as_good_as_mine
    if mine? #me
      (@ships + @incoming_mine_i) > @incoming_enemy_i
    else # enemy owned
      (@ships + @incoming_enemy_i + (@growth * 3)) <  @incoming_mine_i
    end
  end

	def total_power
		@ships + @growth
	end
  
  def reinforcements_needed
		cow = @incoming_enemy_i - total_power
		(cow <= 0) ? 0 : cow
  end
  
  def reinforcements_available
    cow = @ships - @incoming_enemy_i
#		log("\t#{self.to_s}\treinforcements available #{cow} ")
    (cow <= 0) ? 0 : cow
  end

	def would_be_in_trouble(s)
		(total_power - s) <= @incoming_enemy_i
	end
  
	def enemy?
		@owner == 2
	end
	
	def mine?
		@owner == 1
	end
	
	def neutral?
		(@owner != 2) && (@owner != 1)
	end
	
	def ships_to_take(planet)
		dist = self.distance(planet)		
		if neutral?
			base = @ships
			ene = 0
			me = 0
			if @incoming_enemy.size > 0
				ene = @incoming_enemy.inject(0){|memo, x| memo += (x.remaining_turns < dist) ? x.ships : 0	}
			end
			if @incoming_mine.size > 0
				me = @incoming_mine.inject(0){|memo, x| memo += (x.remaining_turns < dist) ? x.ships : 0	}
			end
			# if ene > me
			# 	(base - ene).abs - me + 1				
			# else
			# 	(base -me).abs + ene + 1				
			# end
			base + ene - me + 1
		elsif enemy?
			base = @ships + (@growth * distance(planet)) 
			ene = 0
			if @incoming_enemy.size > 0
				ene = @incoming.inject(0) do |memo, x| 
					val = if x.enemy? && (x.remaining_turns < dist)
 						x.ships
					elsif x.mine? && (x.remaining_turns < dist)
						-x.ships
					else
						0
					end
					memo += val
				end
			end
			base + ene + 1
		else # mine
			(@incoming_enemy_i - @ships - @incoming_mine_i - @growth)
		end
	end
	
end









class Fleet
  attr_accessor :owner, :ships, :source, :destination, :total_turns, :remaining_turns, :fid
  def initialize(str, id)
    cow = str.split
    @owner = cow[1].to_i
    @ships = cow[2].to_i
    @source = cow[3].to_i
    @destination = cow[4].to_i
    @total_turns = cow[5].to_i
    @remaining_turns = cow[6].to_i
    @fid = id
  end

	def enemy?
		@owner == 2
	end
	
	def mine?
		@owner == 1
	end

  
  def to_s
    "Fleet #{@fid}: Owner: #{@owner} Ships: #{@ships} Source: #{@source} Destination: #{@destination} TotalTurns: #{@total_turns} RemainingTurns: #{@remaining_turns}\n"
  end
end


def log(str, mode = 'a+')
	$stderr.puts str + "\n"
#  File.open("rubybot.log", mode) {|f|  f << str}
end