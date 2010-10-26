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

  attr_accessor :x, :y, :owner, :ships, :growth, :pid, :incoming_mine, :incoming_enemy, 
								:incoming, :incoming_mine_i, :incoming_enemy_i, :incoming_mine_j, :incoming_enemy_j
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
		if @incoming_enemy_i > 0
			pig = @ships
			(1..10).to_a.each do |x|
				pig += @incoming_mine_j[x] - @incoming_enemy_j[x]
				return true if pig < 0
			end
		end
		false
  end

	def doomed?
		we = @incoming_mine_j[1] 
		they = @incoming_enemy_j[1]
		if (@ships + we - they) < 0
			true
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
  
  def reinforcements_needed(p = nil)
		return 0 unless @incoming_enemy.size > 0
		cow = if p
			dist = distance(p) + 1
			ene = @incoming_enemy.inject(0){|memo, x|
				memo += (x.remaining_turns <= dist) ? x.ships : 0
			}
			mine = @incoming_mine.inject(0){|memo, x|
				memo += (x.remaining_turns <= dist) ? x.ships : 0
			}
			ene - (@ships + mine)
		else
			tom = @incoming_enemy_i - total_power	
			base = @ships
			res = 0
			(1..15).to_a.each do |x|
				if base > 0
					base += @growth
				else
					base -= @growth
				end
				base -= @incoming_enemy_j[x]
				base += @incoming_mine_j[x]
				if base < 0
					res = base.abs
				end
			end
#			log("tom #{tom}, .res #{res}")
			res + 1
#			res + (res * 1.1).ceil
		end

		(cow <= 0) ? 0 : cow
  end
  
  def reinforcements_available(p = nil)
		if p
			dist = distance(p) + 1
	    ene = @incoming_enemy.inject(0){|memo, x| 
				memo += (x.remaining_turns <= dist) ? x.ships : 0
			}
			mine = @incoming_enemy.inject(0){|memo, x|
				memo += (x.remaining_turns <= dist) ? x.ships : 0
			}
			cow = @ships + mine - ene
		else
    	cow = @ships - @incoming_enemy_i
		end

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
		dist = self.distance(planet) + 1
		cow = if neutral?
			mine = false
			enemy = false
			pig = @ships			
			(1..dist).to_a.each do |i|
				mj = @incoming_mine_j[i]
				ej = @incoming_enemy_j[i]
				if mine or enemy
					pig += @growth
				end
				tom = [pig, ej, mj].sort # rank forces
				if (pig >= mj) && (pig >= ej) # biggest force is neutral, can't go negative, can't switch hands
					pig -= tom[1]
				elsif (mj >= pig) && (mj >= ej) # biggest force is mine
					if mine
						pig += mj
					else #neutral or enemy, doesn't matter
						pig -= mj
						if pig < 0
							mine = true
							enemy = false
							pig = pig.abs
						end
					end
				else # biggest force is enemy
					if enemy
						pig += ej + 1
					else # neutral or mine, doesn't matter
						pig -= ej
						if pig < 0
							mine = false
							enemy = true
							pig = pig.abs
						end
					end
				end

			end
			pig + 1
			# base = @ships
			# ene = 0
			# me = 0
			# if @incoming_enemy.size > 0
			# 	ene = @incoming_enemy.inject(0){|memo, x| memo += (x.remaining_turns <= dist) ? x.ships : 0	}
			# end
			# if @incoming_mine.size > 0
			# 	me = @incoming_mine.inject(0){|memo, x| memo += (x.remaining_turns <= dist) ? x.ships : 0	}
			# end
			# base + ene - me + 1
		elsif enemy?
			base = @ships + (@growth * dist) 
			ene = 0
			if @incoming_enemy.size > 0
				ene = @incoming.inject(0) do |memo, x| 
					val = if x.enemy? && (x.remaining_turns <= dist)
 						x.ships
					elsif x.mine? && (x.remaining_turns <= dist)
						-x.ships
					else
						0
					end
					memo += val
				end
			end
			base + ene + 2
		else # mine
			0
		end
#		log "\tships to take #{cow} -|- #{self.to_s} -|- dist = #{dist}"
		cow + (cow * 1.1).ceil
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