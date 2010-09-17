#include <iostream>
#include "PlanetWars.h"
#include <time.h>


// The DoTurn function is where your code goes. The PlanetWars object contains
// the state of the game, including information about all planets and fleets
// that currently exist. Inside this function, you issue orders using the
// pw.IssueOrder() function. For example, to send 10 ships from planet 3 to
// planet 8, you would say pw.IssueOrder(3, 8, 10).
int enemy_origin = -1;
//
// There is already a basic strategy in place here. You can use it as a
// starting point, or you can throw it out entirely and replace it with your
// own. Check out the tutorials and articles on the contest website at
// http://www.ai-contest.com/resources.
void DoTurn(const PlanetWars& pw) {
  	std::vector<Planet> my_planets =      pw.MyPlanets();
  	std::vector<Planet> neutral_planets = pw.NeutralPlanets();
  	std::vector<Planet> not_my_planets =  pw.NotMyPlanets();
  	std::vector<Planet> enemy_planets =   pw.EnemyPlanets(); 

  	std::vector<Fleet> enemy_fleets = pw.EnemyFleets();

	// set origin
	bool first_turn_strat = false;
	if (enemy_planets.size() == 1){
		enemy_origin = enemy_planets[0].PlanetID();
		first_turn_strat = true;
		// need to spread to more planets on the first turn
		// also need to try to spread to planets that are far away from their origin,
		// because those planets, especially if they have a high growth rate, will be easier to defend and a good source of troops
	}

  	int max_fleet_size = my_planets.size() * 4 ;
//  	int max_fleet_size = 100 ;
  	if (pw.MyFleets().size() >= max_fleet_size ) {
   		return;
	}
  
	int their_planets_size = enemy_planets.size();
	if (their_planets_size < 1){
		their_planets_size = 1;
	}
	
	
	////////////////////////////////////////////////////
  	// loop through my planets and issue commands to attack either the enemy or an unclaimed rock. 
	////////////////////////////////////////////////////
  	for (int i = 0; i < my_planets.size(); ++i) {
  	  	const Planet& curr_p = my_planets[i];	
		// Determine if I have incoming
		// Don't leave if there are enemy ships pointed at me.
		bool incoming = false;
		int incoming_ships = 0;
		for(int m = 0; m < enemy_fleets.size(); ++m){
			const Fleet& pig = enemy_fleets[m];
			int frak = pig.DestinationPlanet();
			if (frak == curr_p.PlanetID()){
				incoming = true;
				incoming_ships += pig.NumShips();
				break;
			}
		}
		
	  	// Find the weakest enemy planet.
	  	int their_weakest_planet_id = enemy_origin;
		int their_second_weakest_id = -1;
	  	int their_weakest_ships = 0;
		int their_second_weakest_ships = 0;
		int weakest_planet_dist = 0;
	  	double weakest_score = -999999.0;
	  	for (int i = 0; i < enemy_planets.size(); ++i) {
	    	const Planet& p = enemy_planets[i];
			double dist = pw.Distance(curr_p.PlanetID(), p.PlanetID());
			double grow = p.GrowthRate();
	    	double score = 1.0 / ((dist * dist) + p.NumShips());
//	    	double score = grow / (dist + p.NumShips());	
//    		double score = 1.0 / (1.0 + p.NumShips());
	    	if (score > weakest_score) {
	      		weakest_score = score;
				their_second_weakest_id = their_weakest_planet_id;
	      		their_weakest_planet_id = p.PlanetID();
				their_second_weakest_ships = their_weakest_ships;
	      		their_weakest_ships = p.NumShips();
				weakest_planet_dist  = (int)dist;
	    	}
	  	}
	
		
		double desire = -99999.0;
		int desire_planet_id = -1;
		int desire_ship_count = 0;
		int second_desire_planet_id = -1;
		int second_desire_ship_count = 0;
		int third_desire_planet_id = -1;
		int third_desire_ship_count = 0;
		int desire_planet_dist = 0;
		for(int k = 0; k < not_my_planets.size(); ++k){
			const Planet& cow = not_my_planets[k];
			double dist = pw.Distance(curr_p.PlanetID(), cow.PlanetID());
			double grow = cow.GrowthRate();
			double pop =  cow.NumShips();
			double score = grow / dist * 2;
//			double score = (grow + grow) / (dist + dist) ;
			// score = score - (pop);
			if (score > desire){
				desire = score;
				third_desire_planet_id = second_desire_planet_id;
				second_desire_planet_id = desire_planet_id;
				desire_planet_id = cow.PlanetID();
				third_desire_ship_count = second_desire_ship_count;
				second_desire_ship_count = desire_ship_count;
				desire_ship_count = cow.NumShips();
				desire_planet_dist = (int)dist;
			}
		}
		
		
	
		bool i_have_more_planets = ( my_planets.size() > enemy_planets.size() );
		bool i_have_twice_as_many_planets = (my_planets.size() > (enemy_planets.size() * 2));

    	if (i_have_more_planets && (their_weakest_planet_id > 0)){
			if(i_have_twice_as_many_planets){
				int ships_to_send = curr_p.NumShips() / their_planets_size;
				for(int j = 0; j < enemy_planets.size(); ++j){
					if (incoming == false){
						pw.IssueOrder(curr_p.PlanetID(), enemy_planets[j].PlanetID(), ships_to_send);
					}else{
						if(ships_to_send > incoming_ships){
							pw.IssueOrder(curr_p.PlanetID(), enemy_planets[j].PlanetID(), ships_to_send - incoming_ships);
						}
					}
				}
			}
// need to sort my planets based on how many ships they have so the first planet will send the most ships and then we can switch targets.			
			else {
				// If this planet has a shit ton of ships, do several things.
				int p_ships = curr_p.NumShips() / 4;
///				int ships = their_weakest_ships * 2;
	        	if (p_ships > 0){
//	          		p_ships = p_ships - ships;
	          		// attack their weakest with twice the strength of their weakest
	       			pw.IssueOrder(curr_p.PlanetID(), their_weakest_planet_id, p_ships );

					if(their_second_weakest_id > 0){
						pw.IssueOrder(curr_p.PlanetID(), their_second_weakest_id, p_ships);
					}
					
					if(desire_planet_id > 0){
						pw.IssueOrder(curr_p.PlanetID(), desire_planet_id, p_ships);
					}

					if(second_desire_planet_id > 0){
						pw.IssueOrder(curr_p.PlanetID(), second_desire_planet_id, p_ships);
					}
					
					
						// 	          		// attack the destination of their current fleet with the rest.					
						// 	          		if (dest > 0){
						// if(p_ships > 2){
						// 	            			pw.IssueOrder(curr_p.PlanetID(), dest, p_ships  / 2 );
						// }
						// 	          		}
	        	}
	        	else{
	          		// this is hit for planets that are not heavily stacked, attack only one target with them.
					if(incoming == false){
						if (curr_p.NumShips() > 2) {
//						if ((curr_p.NumShips() > 2) && (their_second_weakest_id > 0)){							
							pw.IssueOrder(curr_p.PlanetID(), their_weakest_planet_id, curr_p.NumShips() - 1 );
//							pw.IssueOrder(curr_p.PlanetID(), their_second_weakest_id, curr_p.NumShips() / 2 );
						}
						// else{
						// 	if(curr_p.NumShips() > 0){
						// 		pw.IssueOrder(curr_p.PlanetID(), their_weakest_planet_id, curr_p.NumShips() - 1 );
						// 	}
						// }
					}else{
						if (desire_planet_id > 0){
							pw.IssueOrder(curr_p.PlanetID(), desire_planet_id, curr_p.NumShips() - 1 );
						}
						// if(curr_p.NumShips() > incoming_ships){
						// 	pw.IssueOrder(curr_p.PlanetID(), their_weakest_planet_id, curr_p.NumShips() - incoming_ships );
						// }
					}
	        	}
			}
      	}
      	// also need to make it so that if the current planet is a target it doesn't send it's ships away.
      	// Keep getting one planet with a shitload of ships, need to loop and send to different targets.

		else{ // if i'm not ahead, or if we can't find a weakest planet for them. 
			int ships = curr_p.NumShips() / 4;
			if(incoming == false){
				if(ships > 0){
					if(their_weakest_planet_id > 0){
						pw.IssueOrder(curr_p.PlanetID(), their_weakest_planet_id, ships);
					}
					if (desire_planet_id > 0){
						pw.IssueOrder(curr_p.PlanetID(), desire_planet_id, ships);
					}
					if (second_desire_planet_id > 0){
						pw.IssueOrder(curr_p.PlanetID(), second_desire_planet_id, ships);
					}
					if (third_desire_planet_id > 0){
						pw.IssueOrder(curr_p.PlanetID(), third_desire_planet_id, ships);
					}
				}
			}else{
				if(curr_p.NumShips() > incoming_ships){
					pw.IssueOrder(curr_p.PlanetID(), desire_planet_id, 5);
				}
			}


  		}
  	}  
}









// This is just the main game loop that takes care of communicating with the
// game engine for you. You don't have to understand or change the code below.
int main(int argc, char *argv[]) {
  std::string current_line;
  std::string map_data;
  while (true) {
    int c = std::cin.get();
    current_line += (char)c;
    if (c == '\n') {
      if (current_line.length() >= 2 && current_line.substr(0, 2) == "go") {
        PlanetWars pw(map_data);
        map_data = "";
        DoTurn(pw);
	pw.FinishTurn();
      } else {
        map_data += current_line;
      }
      current_line = "";
    }
  }
  return 0;
}
