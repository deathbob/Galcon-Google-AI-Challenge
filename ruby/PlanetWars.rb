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
	DIST = 20
  attr_accessor :x, :y, :owner, :ships, :growth, :pid, :incoming_mine, :incoming_enemy, 
								:incoming, :incoming_mine_i, :incoming_enemy_i, :incoming_mine_j, :incoming_enemy_j,
								:edges_out, :edges_in
  def initialize(str, id)
    cow = str.split
    @x = cow[1].to_f
    @y = cow[2].to_f
    @owner = cow[3].to_i
    @ships = cow[4].to_i
    @growth = cow[5].to_i
    @incoming_mine_i = 0
    @incoming_mine_j = Hash.new{|hash, key| hash[key] = 0}
    @incoming_mine = []
    @incoming_enemy_i = 0
    @incoming_enemy_j = Hash.new{|hash, key| hash[key] = 0}
    @incoming_enemy = []
    @pid = id
		@net_inc = {}
		@incoming = []
		@edges_out = []
		@edges_in = []
		@result
  end
  
  def to_s
    "Planet #{@pid}: X: #{@x} Y: #{@y} Owner: #{@owner} Ships: #{@ships} Growth: #{@growth} "
  end
  
  def distance(planet)
    dx = self.x.to_f - planet.x.to_f
    dy = self.y.to_f - planet.y.to_f
    (Math.sqrt(dx * dx + dy * dy)).ceil
  end
  
  def in_trouble?
		reinforcements_needed > 0
  end


	def total_power
		@ships + @growth
	end
  

  def reinforcements_needed(p = nil)
		res = 0
		base = @ships
		(0..DIST).each do |i|
			(base += base > 0 ? @growth : -@growth) unless (@owner == 0) || (i == 0)
			base -= @incoming_enemy_j[i]
			base += @incoming_mine_j[i]
		end
		return base < 0 ? base.abs : 0
  end

  def reinforcements_available(p = nil)
		ene = (0..10).to_a.inject(0){|memo, x| memo += @incoming_enemy_j[x]}
		cow = @ships - ene
    (cow <= 0) ? 0 : cow
  end
	
	def value(p)
		cow = 0
		pig = p.ships
		dist = distance(p)
		(0..DIST).each do |i|
			if i < dist
				next
			end
			if pig > @ships
				cow += @growth
			else
				pig += p.growth
			end
		end
		cow
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
		base = @ships
		state = @owner
		(0..dist).to_a.each do |i|
			mj, ej = @incoming_mine_j[i], @incoming_enemy_j[i]
#			log("\t\tships to take (#{self.pid}) before #{i}: #{base}, mj #{mj}, ej #{ej}")	
			case state
			when 0 # neutral
				tom = [base, ej, mj].sort # rank forces
				if (base >= mj) && (base >= ej) # biggest force is neutral, can't go negative, can't switch hands
					base -= tom[1]
				elsif (mj == ej)
					base -= mj
				# elsif (ej >= base) && (ej >= mj) # biggest force is enemy (pesimistic version)
				# 	base -= ej
				# 	state = 2			if base < 0
				# else # biggest force is mine
				# 	base -= mj
				# 	state = 1			if base < 0
				elsif (mj >= base) && (mj >= ej) # biggest force is mine
					base -= mj
					state = 1			if base < 0
				else # biggest force is enemy
					base -= ej
					state = 2			if base < 0
				end
			when 1 # mine
				base += @growth
				base += mj
				base -= ej
				state = 2				if base < 0
			when 2 # enemy owned
				base += @growth
				base -= mj				
				base += ej
				state = 1				if base < 0
			end
			base = base.abs
		end
		if state == 1
			return 0
		else
 			return base + 1
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
    "Fleet #{@fid}: Owner: #{@owner} Ships: #{@ships} Source: #{@source} Destination: #{@destination} TotalTurns: #{@total_turns} RemainingTurns: #{@remaining_turns}"
  end
end


def log(str, mode = 'a+')
	$stderr.puts str + "\n"
#  File.open("rubybot.log", mode) {|f|  f << str}
end