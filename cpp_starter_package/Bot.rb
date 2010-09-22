class Bot
  attr_accessor :planet_wars, :orders, :my_planets, :enemy_planets, :neutral_planets, 
                :my_fleets, :enemy_fleets, :planets, :fleets, :turn, :enemy_origin, :my_origin
  

  def initialize
    @turn = 0
    @orders = []
  end
  
  def parse_game_state
    @planets = @planet_wars.planets
    
    @neutral_planets = @planets.collect{|x| x if x.owner == '0'}.compact
    
    @my_planets = @planets.collect{|x| x if x.owner == '1'}.compact
    @enemy_planets = @planets.collect{|x| x if x.owner == '2'}.compact
    @not_my_planets = @enemy_planets + @neutral_planets
    @fleets = @planet_wars.fleets
    @my_fleets = @planet_wars.fleets.collect{|x| x.owner == '1'}
    @enemy_fleets = @planet_wars.fleets.collect{|x| x.owner == '2'}
    if @turn == 1
      @enemy_origin = @enemy_planets.first
      @my_origin = @my_planets.first
    end
    
  end
    
  
  def do_turn(pw)
    @turn = @turn + 1
    log "Turn #{@turn}\n"
    @planet_wars = pw

    parse_game_state
    snake_style
    finish_turn

    # Benchmark.bmbm do |x|
    #   x.report("parse_game_state"){parse_game_state}
    #   x.report("snake_style"){snake_style}
    #   x.report("1000 times"){1000.times {|z| z * 10}}
    #   x.report("Finish turn"){finish_turn}
    # end
  end
  
  def snake_style
    
    @my_planets.each do |p|
#      foo = @not_my_planets.closest(p)
#      issue_order(p, foo, p.ships )
#      issue_order(p, closest_to_me_and_enemy_origin, p.ships )
      issue_order(p, weakest_enemy(p), p.ships)
    end
    true
  end
  
  def weakest_enemy(planet)
    @not_my_planets.min do |a, b| 
      a.ships <=> b.ships
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
    puts "go\n"
    $stdout.flush
  end
  
  def issue_order(from, to, num)
    order = "#{from.id} #{to.id} #{num}\n"
    log order
    @orders << order
    true
  end
  
  def log(str)
    File.open("rubybot.log", 'a+') {|f|  f << str}
  end
  
end

class Array
  def closest(planet)
    self.min{|a, b| planet.distance(a) <=> planet.distance(b)}
  end
end




#end