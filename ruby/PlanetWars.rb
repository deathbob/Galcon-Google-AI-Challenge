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
  
  def issue_order
  end
  
end

class Planet

  attr_accessor :x, :y, :owner, :ships, :growth, :id, :incoming
  def initialize(str, id)
    cow = str.split
    @x = cow[1].to_f
    @y = cow[2].to_f
    @owner = cow[3].to_i
    @ships = cow[4].to_i
    @growth = cow[5].to_i
    @incoming = 0
    @id = id
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
    self.ships <= self.incoming
  end
  
end

class Fleet
  attr_accessor :owner, :ships, :source, :destination, :total_turns, :remaining_turns, :id
  def initialize(str, id)
    cow = str.split
    @owner = cow[1].to_i
    @ships = cow[2].to_i
    @source = cow[3].to_i
    @destination = cow[4].to_i
    @total_turns = cow[5].to_i
    @remaining_turns = cow[6].to_i
#    junk, @owner, @ships, @source, @destination, @total_turns, @remaining_turns = str.split
    @id = id
  end
  
  def to_s
    "Fleet #{@id}: Owner: #{@owner} Ships: #{@ships} Source: #{@source} Destination: #{@destination} TotalTurns: #{@total_turns} RemainingTurns: #{@remaining_turns}\n"
  end
end

def log(str, mode = 'a+')
  File.open("rubybot.log", mode) {|f|  f << str}
end