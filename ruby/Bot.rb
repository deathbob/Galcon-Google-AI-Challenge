class Bot
  attr_accessor :planet_wars, :orders, :my_planets, :enemy_planets, :neutral_planets, 
                :my_fleets, :enemy_fleets, :planets, :fleets, :turn, :enemy_origin, :my_origin
  

  def initialize
    @turn = 0
    @orders = []
  end
  
  def my_growth_rate
    @my_planets.inject(0){|memo, x| memo + x.growth}
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
    # log "my origin #{@my_origin.id}\n"
    # log "enemy_origin #{@enemy_origin.id}\n"
    set_incoming
    
  end
  
  def set_incoming
    @fleets.each do |x|
      @planets[x.destination].incoming = @planets[x.destination].incoming + x.ships
    end
  end
    
  
  def do_turn(pw)
    @turn = @turn + 1
#    log "Turn #{@turn}"
    @planet_wars = pw

    parse_game_state
    snake_style
    finish_turn
  end
  
  def log_planets(planet = nil)
    @planets.each do |x|
      piss = planet ? "distance #{planet.distance(x)}" : "no planet given"
      log("id #{x.id}, growth #{x.growth}, ships #{x.ships}, #{piss}")
    end
  end
  
  def snake_style

    @my_planets.each do |p|
#      log_planets(p)
      issue_order(p, weakest_enemy(p), p.ships / 2) unless p.in_trouble?
      @not_my_planets = @not_my_planets.sort{|a, b|
        ad = p.distance(a)
        bd = p.distance(b)
        # a_score = ( a.growth.to_f / ((a.ships * ad) + 1) )
        # log "#{a.id} score #{a_score}"
        (b.growth.to_f / ((bd * bd) + b.ships)) <=> (a.growth.to_f / ((ad * ad) + a.ships))
      }
      it = @not_my_planets.size
      while (p.ships > 0 && it > 0) do
        curr = @not_my_planets[-it]
        it = it - 1
        if p.ships > (curr.ships + 1)
          issue_order(p, curr, (curr.ships + 1)) unless p.in_trouble?
        else
#          issue_order(p, curr, p.ships) unless p.in_trouble?
        end
      end
    end
    true
  end
  
  def most_desireable(planet)
    @not_my_planets.min{|a, b|
      ad = planet.distance(a)
      bd = planet.distance(b)
      (a.growth / ((ad * ad) + a.ships)) <=> (b.growth / ((bd * bd) + b.ships))
    }
#    			double score = grow / ((dist * dist ) + pop) ; // This is the (one from c++) best one so far.
  end
  
  def closest_neutral(planet)
    @neutral_planets.closest(planet)
  end
  
  def weakest_enemy(planet)
    @enemy_planets.min do |a, b| 
#      a.ships <=> b.ships
      (a.ships + planet.distance(a)) <=> (b.ships + planet.distance(b))
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
    return unless num > 0 and from.ships >= num
    order = "#{from.id} #{to.id} #{num}\n"
#    log "\torder #{order}"
    from.ships = from.ships - num
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