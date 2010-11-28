class WebBot < Bot

	def do_turn(pw)
		super(pw){
			web_style
		}
	end
	
	
	def web_style
		build_web
		
	end
	
	def build_web
		@my_planets.each do |x| 
			@not_my_planets.each do |y|
				y.result += x.ships
				y.edges_in <<  [x.ships, x.id, distance(x,y), :in]
				x.edges_out << [x.ships, y.id, distance(x,y), :out]
			end
		end
		
		@enemy_planets.each do |x|
			(@planets - @enemy_planets).each do |y|
				y.result -= x.ships
				y.edges_in <<  [x.ships, x.id, distance(x,y), :in]
				x.edges_out << [x.ships, y.id, distance(x,y), :out]
			end
		end
	end
	
end





=begin
Take all the planets.
Calculate ships to take each planet, not counting travel time, which can be added / calculated per planet.
Score different moves based on how much Growth we would have at the end of a turn / if a turn goes well. 
Make edges from planets representing their ships available to attack with.
Determine which planets would be best to attack based on the combination of power that can be brought to bear.

first steps
take each planet i own
calculate outgoing available power to other planets
calculate incoming available power from other planets
look at all planets and decide which ones make sense to reinforce or to attack.  



=end

































































































