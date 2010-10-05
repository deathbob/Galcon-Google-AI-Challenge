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
        if x.reinforcements_needed < y.reinforcements_available
          issue_order(y, x, x.reinforcements_needed)
        else
          break
        end
      end
    end
  end
  
  def snake_style
    issue_reinforcements
    @my_planets.each do |p|
      if p.in_trouble?      
        next 
      end
      if behind_on_growth 
        @not_my_planets = @not_my_planets.sort{|a, b|
          ad = p.distance(a)
          bd = p.distance(b)
          (b.growth.to_f / ((bd * bd) + b.ships)) <=> (a.growth.to_f / ((ad * ad) + a.ships))
        }
        it = @not_my_planets.size
        while (p.ships > 0 && it > 0) do
          curr = @not_my_planets[-it]
          it = it - 1
          # bail out conditions
          if (p.ships < curr.ships + 1) || curr.is_as_good_as_mine
            next
          else
            issue_order(p, curr, (curr.ships + 1))             
          end
        end
      elsif behind_on_ships
        # do nothing
      else
        issue_order(p, most_vulnerable_enemy(p), p.ships / 2)        
        issue_order(p, closest_enemy(p), p.ships / 2)        
        issue_order(p, weakest_enemy(p), p.ships / 2) 
      end
    end
    true
  end
  
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
      (a.ships + (ad * ad)) <=> (b.ships + (bd * bd))
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
    return unless from && to
    
    to.incoming_mine = to.incoming_mine + num
    from.ships = from.ships - num
        
    order = "#{from.pid} #{to.pid} #{num}\n"
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