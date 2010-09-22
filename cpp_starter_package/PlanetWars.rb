class PlanetWars
  
  attr_accessor :planets, :fleets
  
  def initialize(str)
    # File.open("rubybot.log", 'a+') {|f|  f << str}
    @planets = []
    @fleets = []

    str.each do |s|
      if s.start_with? 'P'
        @planets << Planet.new(s, @planets.size )
      elsif s.start_with? 'F'
        @fleets << Fleet.new(s, @fleets.size )
      end
    end
    # self.fleets.each do |fleet|
    #   File.open("rubybot.log", 'a+') {|f|  f << fleet.to_s}
    # end
    # self.planets.each do |planet|
    #   File.open("rubybot.log", 'a+') {|f|  f << planet.to_s}
    # end
  end
  
  def issue_order
  end
  
end

class Planet

  attr_accessor :x, :y, :owner, :ships, :growth, :id
  def initialize(str, id)
    junk, @x, @y, @owner, @ships, @growth = str.split
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
  
end

class Fleet
  attr_accessor :owner, :ships, :source, :destination, :total_turns, :remaining_turns, :id
  def initialize(str, id)
    junk, @owner, @ships, @source, @destination, @total_turns, @remaining_turns = str.split
    @id = id
  end
  
  def to_s
    "Fleet #{@id}: Owner: #{@owner} Ships: #{@ships} Source: #{@source} Destination: #{@destination} TotalTurns: #{@total_turns} RemainingTurns: #{@remaining_turns}\n"
  end
end

