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

	// set origin
	if (enemy_planets.size() == 1){
		enemy_origin = enemy_planets[0].PlanetID();
	}

  	int max_fleet_size = my_planets.size() * 3 ;
	  	if (pw.MyFleets().size() >= max_fleet_size ) {
    		return;
  		}

  	// Find planet enemy is aiming at.
  	std::vector<Fleet> enemy_fleets = pw.EnemyFleets();
  	int dest = -1;
  	for(int i = 0; i < enemy_fleets.size(); ++i) {
    	const Fleet& f = enemy_fleets[i];
    	dest = f.DestinationPlanet();
  	}
        
  	// // Find planet that I own with highest growth factor
  	// int hgr = 0;
  	// int my_hgr_planet_id = -1;
  	// int my_hgr_ship_count = 0;
  	// for (int i = 0; i < my_planets.size(); ++i) {
  	//     	const Planet& p = my_planets[i];
  	//     	int gr = p.GrowthRate();
  	//     	if (gr > hgr) {
  	//       		hgr = gr;
  	//       		my_hgr_planet_id = p.PlanetID();
  	//       		my_hgr_ship_count = p.NumShips();
  	//     	}
  	// }

  	// (2) Find my strongest planet.
  	int my_strongest_planet_id = -1;
  	double strongest_score = -999999.0;
  	int my_strongest_ships = 0;
  	for (int i = 0; i < my_planets.size(); ++i) {
    	const Planet& p = my_planets[i];
    	double score = (double)p.NumShips();
    	if (score > strongest_score) {
      		strongest_score = score;
      		my_strongest_planet_id = p.PlanetID();
      		my_strongest_ships = p.NumShips();
    	}
  	}
  
  	// Find neutral planet with highest growth factor
  	int neutral_hgr = 0;  
  	int neutral_hgr_planet_id = -1;
  	int neutral_hgr_ship_count = 0;
    	for(int i = 0; i < neutral_planets.size(); ++i){
    	const Planet& p = neutral_planets[i];
    	int gr = p.GrowthRate();
    	if(gr > neutral_hgr){
      		neutral_hgr = gr;
      		neutral_hgr_planet_id = p.PlanetID();
      		neutral_hgr_ship_count = p.NumShips();
    	}
  	}

  
  	// (3) Find the weakest enemy planet.
  	int their_weakest_planet_id = -1;
	int their_second_weakest_id = -1;
  	int their_weakest_ships = 0;
	int their_second_weakest_ships = 0;
  	double weakest_score = -999999.0;
  	for (int i = 0; i < enemy_planets.size(); ++i) {
    	const Planet& p = enemy_planets[i];
    	double score = 1.0 / (1 + p.NumShips());
    	if (score > weakest_score) {
      		weakest_score = score;
			their_second_weakest_id = their_weakest_planet_id;
      		their_weakest_planet_id = p.PlanetID();
			their_second_weakest_ships = their_weakest_ships;
      		their_weakest_ships = p.NumShips();
    	}
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
				incoming_ships = pig.NumShips();
				break;
			}
		}
		
		double desire = -99999.0;
		int desire_planet_id = -1;
		int desire_ship_count = 0;
		for(int k = 0; k < not_my_planets.size(); ++k){
			const Planet& cow = not_my_planets[k];
			// watch out, if they're not all doubles some thing is going wrong
			double dist = pw.Distance(curr_p.PlanetID(), cow.PlanetID());
			double grow = cow.GrowthRate();
			double pop = cow.NumShips();
			double score = grow / dist ;
			// Does taking the population into account help? // Seems to make things worse :(
			// score = score - (pop);
			if (score > desire){
				desire = score;
				desire_planet_id = cow.PlanetID();
				desire_ship_count = cow.NumShips();
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
			}else {// i have more but not twice as many
				// need to sort my planets based on how many ships they have so the first planet will send the most ships and then we can switch targets.							
				// If this planet has a shit ton of ships, do several things.
				int p_ships = curr_p.NumShips();
				int ships = their_weakest_ships * 2;
	        	if (p_ships > ships){
	          		p_ships = p_ships - ships;
	          		// attack their weakest with twice the strength of their weakest
					pw.IssueOrder(curr_p.PlanetID(), their_weakest_planet_id, ships );

					if(desire_planet_id > 0){
						if (p_ships > desire_ship_count + 1){
							p_ships = p_ships - desire_ship_count;
							pw.IssueOrder(curr_p.PlanetID(), desire_planet_id, desire_ship_count + 1);
						}
					}
					if(their_second_weakest_id > 0){
						if(p_ships > their_second_weakest_ships + 1){
							p_ships = p_ships - their_second_weakest_ships;
							pw.IssueOrder(curr_p.PlanetID(), their_second_weakest_id, their_second_weakest_ships + 1);
						}
					}
					
	          		// attack the destination of their current fleet with the rest.					
	          		if (dest > 0){
						if(p_ships > 2){
	            			pw.IssueOrder(curr_p.PlanetID(), dest, p_ships / 2 );
						}
	          		}
	        	}
	        	else{
	          		// this is hit for planets that are not heavily stacked, attack only one target with them.
					if(incoming == false){
						if ((curr_p.NumShips() > 2) && (their_second_weakest_id > 0)){
							pw.IssueOrder(curr_p.PlanetID(), their_weakest_planet_id, curr_p.NumShips() / 2 );
							pw.IssueOrder(curr_p.PlanetID(), their_second_weakest_id, curr_p.NumShips() / 2 );
						}else{
							if(curr_p.NumShips() > 0){
								pw.IssueOrder(curr_p.PlanetID(), their_weakest_planet_id, curr_p.NumShips() - 1 );
							}
						}
						
					}else{
						if(curr_p.NumShips() > incoming_ships){
							// their weakest is a fine choice
//							pw.IssueOrder(curr_p.PlanetID(), their_weakest_planet_id, curr_p.NumShips() - incoming_ships );
							// their origin has proven less effective
//							pw.IssueOrder(curr_p.PlanetID(), enemy_origin, curr_p.NumShips() - incoming_ships);
							// trying desire now 
							// preliminary research suggests it is even more effective than their_weakest.
							if(desire_planet_id > 0){
								pw.IssueOrder(curr_p.PlanetID(), desire_planet_id, curr_p.NumShips() - incoming_ships);						
							}
						}
					}
	        	}
			}
      	}
      	// also need to make it so that if the current planet is a target it doesn't send it's ships away.
      	// Keep getting one planet with a shitload of ships, need to loop and send to different targets.
		else{ // if i'm not ahead, or if we can't find a weakest planet for them. 
			if(desire_planet_id > 0){
				if (incoming == false){
					pw.IssueOrder(curr_p.PlanetID(), desire_planet_id, curr_p.NumShips() - 1);
				}else{
					if (curr_p.NumShips() > incoming_ships){
//						pw.IssueOrder(curr_p.PlanetID(), enemy_origin, curr_p.NumShips() - incoming_ships);
						pw.IssueOrder(curr_p.PlanetID(), desire_planet_id, curr_p.NumShips() - incoming_ships);						
					}
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
