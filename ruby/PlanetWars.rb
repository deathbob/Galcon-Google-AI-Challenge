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

  attr_accessor :x, :y, :owner, :ships, :growth, :pid, :incoming_mine, :incoming_enemy
  def initialize(str, id)
    cow = str.split
    @x = cow[1].to_f
    @y = cow[2].to_f
    @owner = cow[3].to_i
    @ships = cow[4].to_i
    @growth = cow[5].to_i
    @incoming_mine = 0
    @incoming_enemy = 0    
    @pid = id
  end
  
  def to_s
    "Planet #{@id}: X: #{@x} Y: #{@y} Owner: #{@owner} Ships: #{@ships} Growth: #{@growth}\n"
  end
  
  def distance(planet)
    dx = self.x.to_f - planet.x.to_f
    dy = self.y.to_f - planet.y.to_f
    (Math.sqrt(dx * dx + dy * dy)).ceil
  end
  
  def in_trouble?
    (self.growth + self.ships + self.incoming_mine) <= self.incoming_enemy
  end
  
  def is_as_good_as_mine
    if self.owner == 1 #me
      (self.ships + self.incoming_mine) > self.incoming_enemy
    else # enemy owned
      (self.ships + self.incoming_enemy + (self.growth * 3)) <  self.incoming_mine
    end
  end

	def total_power
		@ships + @growth
	end
  
  def reinforcements_needed
		cow = @incoming_enemy - total_power
		(cow <= 0) ? 0 : cow
  end
  
  def reinforcements_available
    cow = total_power - @incoming_enemy
    (cow <= 0) ? 0 : cow
  end

	def would_be_in_trouble(s)
		(total_power - s) <= self.incoming_enemy
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
		if neutral?
			(@ships + @incoming_enemy - @incoming_mine) + 2
		elsif enemy?
			(@ships + (@growth * distance(planet)) - (@incoming_mine / 2) + @incoming_enemy) + 3
		else
			(@incoming_enemy - @ships - @incoming_mine - @growth)
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
  
  def to_s
    "Fleet #{@id}: Owner: #{@owner} Ships: #{@ships} Source: #{@source} Destination: #{@destination} TotalTurns: #{@total_turns} RemainingTurns: #{@remaining_turns}\n"
  end
end

# def log(str, mode = 'a+')
#   File.open("rubybot.log", mode) {|f|  f << str}
# end