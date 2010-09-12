#include <iostream>
#include "PlanetWars.h"
#include <time.h>


// The DoTurn function is where your code goes. The PlanetWars object contains
// the state of the game, including information about all planets and fleets
// that currently exist. Inside this function, you issue orders using the
// pw.IssueOrder() function. For example, to send 10 ships from planet 3 to
// planet 8, you would say pw.IssueOrder(3, 8, 10).
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

  	int max_fleet_size = my_planets.size() + 1 ;
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



  	// Find most desirable planet 
	// aka planet with with highest growth factor and shortest distance
	//   	int desire = 0;  
	//   	int desire_planet_id = -1;
	//   	int desire_ship_count = 0;
	// double desire_score = -9999.0;
	//   	for(int i = 0; i < not_my_planets.size(); ++i){
	//     	const Planet& p = not_my_planets[i];
	//     	int gr = p.GrowthRate();
	// 	int dist = pw.Distance(my_strongest_planet_id, p.PlanetID());
	// 	double score = gr / dist;
	//     	if(score > desire_score){
	// 		desire_score = score;
	//       		desire_planet_id = p.PlanetID();
	//       		desire_ship_count = p.NumShips();
	//     	}
	//   	}

  
  	// (3) Find the weakest enemy planet.
  	int their_weakest_planet_id = -1;
  	int their_weakest_ships = 0;
  	double weakest_score = -999999.0;
  	for (int i = 0; i < enemy_planets.size(); ++i) {
    	const Planet& p = enemy_planets[i];
    	double score = 1.0 / (1 + p.NumShips());
    	if (score > weakest_score) {
      		weakest_score = score;
      		their_weakest_planet_id = p.PlanetID();
      		their_weakest_ships = p.NumShips();
    	}
  	}

  	bool attack_them = false;
	bool go_prospecting = true;
	int their_planets_size = enemy_planets.size();
  	// loop through my planets and issue commands to attack either the enemy or an unclaimed rock. 
  	for (int i = 0; i < my_planets.size(); ++i) {

  	  	const Planet& p = my_planets[i];
		bool i_have_more_planets = ( my_planets.size() > enemy_planets.size() );
		bool i_have_twice_as_many_planets = (my_planets.size() > (enemy_planets.size() * 2));
    	if (i_have_more_planets && (their_weakest_planet_id > 0)){
			if(i_have_twice_as_many_planets){
				int ships_to_send = p.NumShips() / their_planets_size;
				for(int j = 0; j < enemy_planets.size(); ++j){
					pw.IssueOrder(p.PlanetID(), enemy_planets[j].PlanetID(), ships_to_send);
				}
//				return;
			}
			else if (their_weakest_planet_id > 0){
	        	// need to sort my planets based on how many ships they have so the first planet will send the most ships and then we can switch targets.
	        	// If this planet has a shit ton of ships, do several things.
				int p_ships = p.NumShips();
				int ships = their_weakest_ships * 2;
	        	if (p_ships > ships){
	          		p_ships = p_ships - ships;
	          		// attack their weakest with twice the strength of their weakest
	       			pw.IssueOrder(p.PlanetID(), their_weakest_planet_id, ships );
	          		// attack the destination of their current fleet with the rest.
					if(neutral_hgr_planet_id > 0){
						if (p_ships > neutral_hgr_ship_count + 1){
							p_ships = p_ships - neutral_hgr_ship_count;
							pw.IssueOrder(p.PlanetID(), neutral_hgr_planet_id, neutral_hgr_ship_count + 1);
						}
					}
	          		if (dest > 0){
						if(p_ships > 2){
	            			pw.IssueOrder(p.PlanetID(), dest, p_ships - 1 );
						}
	          		}
	        	}
	        	else{
	          		// this is hit for planets that are not heavily stacked, attack only one target with them.
	          		pw.IssueOrder(p.PlanetID(), their_weakest_planet_id, p.NumShips() - 1 );
	        	}
			}
      	}
      	// also need to make it so that if the current planet is a target it doesn't send it's ships away.
      	// Keep getting one planet with a shitload of ships, need to loop and send to different targets.
		else{ // if i'm not ahead, or if we can't find a weakest planet for them. 
		double desire = -99999.0;
		int desire_planet_id = -1;
		for(int k = 0; k < not_my_planets.size(); ++k){
			const Planet& cow = not_my_planets[k];
			// watch out, if they're not all doubles some thing is going wrong
			double dist = pw.Distance(p.PlanetID(), cow.PlanetID());
			double grow = cow.GrowthRate();
			double pop = cow.NumShips();
			double score = grow / (pop / 2.0) ;

			if (score > desire){
				desire = score;
				desire_planet_id = cow.PlanetID();
			}
		}
		
			// 		  	int desire = 0;  
			// 		  	int desire_planet_id = -1;
			// 		  	int desire_ship_count = 0;
			// double desire_score = 0.0;
			// 		  	for(int i = 0; i < not_my_planets.size(); ++i){
			// 		    	const Planet& dizzy = not_my_planets[i];
			// 		    	int gr = dizzy.GrowthRate();
			// 	int dist = pw.Distance(p.PlanetID(), dizzy.PlanetID());
			// 	double score = gr / dist;
			// 		    	if(score > desire_score){
			// 		desire_score = score;
			// 		      		desire_planet_id = dizzy.PlanetID();
			// 		      		desire_ship_count = dizzy.NumShips();
			// 		    	}
			// 		  	}
			
			if(desire_planet_id > 0){
				pw.IssueOrder(p.PlanetID(), desire_planet_id, p.NumShips() - 2);
			}

		
		
		// 
		// pw.IssueOrder(p.PlanetID(), planet_to_attack, p.NumShips() / 2);
		// 
			// if(desire_planet_id > 0){
			// 	pw.IssueOrder(p.PlanetID(), desire_planet_id, p.NumShips() - 1);
			// }


// 			if(go_prospecting == false){
// 				// if (dest > 0){
// 				// 	        		pw.IssueOrder(p.PlanetID(), dest, p.NumShips() / 2 );
// 				// 	      		}
// 				if (their_weakest_planet_id > 0){
// 	        		pw.IssueOrder(p.PlanetID(), their_weakest_planet_id, p.NumShips() / 2 );
// 	      		}
// 			}else{
// 				if(neutral_hgr_planet_id > 0){
// 					if (p.NumShips() - 2 > neutral_hgr_ship_count){
// 						pw.IssueOrder(p.PlanetID(), neutral_hgr_planet_id, neutral_hgr_ship_count + 1);
// 					}else{
// //						pw.IssueOrder(p.PlanetID(), neutral_hgr_planet_id, p.NumShips() / 2);
// 						if(their_weakest_planet_id > 0){
// 							pw.IssueOrder(p.PlanetID(), their_weakest_planet_id, p.NumShips() - 1);
// 						}
// 					}
// 				}
// 				// if(their_weakest_planet_id > 0){
// 				// 	pw.IssueOrder(p.PlanetID(), their_weakest_planet_id, p.NumShips() - 1);
// 				// }
// 			}
// 			go_prospecting = !go_prospecting;							
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
