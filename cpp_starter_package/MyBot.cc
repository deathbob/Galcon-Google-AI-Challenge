#include <iostream>
#include "PlanetWars.h"
#include <time.h>
#include <algorithm>
#include <fstream>
#include <string>
// The DoTurn function is where your code goes. The PlanetWars object contains
// the state of the game, including information about all planets and fleets
// that currently exist. Inside this function, you issue orders using the
// pw.IssueOrder() function. For example, to send 10 ships from planet 3 to
// planet 8, you would say pw.IssueOrder(3, 8, 10).
int enemy_origin = -1;
int my_origin = -1;
int turn = 0;
int game_stage = -1;
int dist_to_their_origin = -1;
int total_planets_size = 0;

bool num_ships_compare(const Planet& a, const Planet& b){
	return a.NumShips() < b.NumShips();
}


class PigSort{
public:
	PigSort(const PlanetWars& ppw):tom(ppw){}
	bool operator()(const Planet& a, const Planet& b){
		double a_dist = (double)tom.Distance(my_origin, a.PlanetID());
		double b_dist = (double)tom.Distance(my_origin, b.PlanetID());

		double a_score = a.GrowthRate() / ((double)a.NumShips() * a_dist);
		double b_score = b.GrowthRate() / ((double)b.NumShips() * b_dist);
		return a_score > b_score;		
		// double a_score = 1.0 / ((a_dist * a_dist) + (double)a.NumShips());
		// double b_score = 1.0 / ((b_dist * b_dist) + (double)b.NumShips());
		// return a_score > b_score;
//		double a_score = a.NumShips();
//		double b_score = b.NumShips();
//		return a_score < b_score;
	}
private:
	const PlanetWars& tom;
};

// void SafeIssue(int p1, int p2, int num){
// 	if (num > 0){
// 		// make sure planet has enough to send, make sure i own the planet, make sure the planet exists, make sure it's not 0 or negative
// 	}
// }
void logout(std::string str1) {
	std::ofstream log_file("botlog.txt", std::ios::app);
	log_file << "turn "<< turn << " " << str1 << std::endl;
	log_file.close();
};
void logout(std::string str1, std::string str2){
	std::ofstream log_file("botlog.txt", std::ios::app);
	log_file << "turn "<< turn << " "  << str1 << str2 << std::endl;
	log_file.close();
}
void logout(std::string str1, int str2){
	std::ofstream log_file("botlog.txt", std::ios::app);
	log_file << "turn "<< turn << " "  << str1 << str2 << std::endl;
	log_file.close();
}
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
	std::vector<Planet> planets = pw.Planets();
	bool targeted_everybody = false;
	turn += 1;

	// set origin
	if (turn <= 1){
		enemy_origin = enemy_planets[0].PlanetID();
		my_origin = my_planets[0].PlanetID();
		dist_to_their_origin = pw.Distance(my_origin, enemy_origin);
//		logout("dist to their origin", dist_to_their_origin);
		total_planets_size = planets.size();
//		logout("total planets size ", total_planets_size);
		// also need to try to spread to planets that are far away from their origin,
		// because those planets, especially if they have a high growth rate, will be easier to defend and a good source of troops
	}

	int max_fleet_size = 30;
//	int max_fleet_size = dist_to_their_origin + (my_planets.size() * 2);
	  	if (pw.MyFleets().size() >= max_fleet_size ) {
	   		return;
	}

  	// Find planet enemy is aiming at.
  	std::vector<Fleet> enemy_fleets = pw.EnemyFleets();
	int their_targets[total_planets_size][2] ;
	for(int i = 0; i < total_planets_size; ++i){ 
		their_targets[i][0] = 0; 
		their_targets[i][1] = 0; 		
	}
	

	int their_most_targeted = -1;
  	for(int i = 0; i < enemy_fleets.size(); ++i) {
  		int dest = -1;	
		int max_targs = 0;
  	    	const Fleet& f = enemy_fleets[i];
  	    	dest = f.DestinationPlanet();
			if(dest > 0 && dest < total_planets_size){
				their_targets[dest][0] += f.NumShips();
				if(their_targets[dest][0] > max_targs){
					max_targs = their_targets[dest][0];
					their_most_targeted = dest;
				}
				their_targets[dest][1] = 1;
			}
  	}
	
	int their_planets_size = enemy_planets.size();
	if(their_planets_size < 1){
		their_planets_size = 1;
	}
	
	int my_growth_rate = 0;
  	for (int i = 0; i < my_planets.size(); ++i) {
  	  	const Planet& p = my_planets[i];	
		my_growth_rate += p.GrowthRate();
	}
	

	

	////////////////////////////////////////////////////
  	// loop through my planets and issue commands to attack either the enemy or an unclaimed rock. 
	////////////////////////////////////////////////////
  	for (int i = 0; i < my_planets.size(); ++i) {
  	  	const Planet& curr_p = my_planets[i];	
		
		if(turn <= 1){ // first turn
			PigSort cow(pw);
			std::sort(neutral_planets.begin(), neutral_planets.end(), cow);	

			std::vector<Planet>::iterator it;
			int rick = curr_p.NumShips();
			for(int it = 0; it < neutral_planets.size(); ++it){
				const Planet& p = neutral_planets[it];
				int tar = p.NumShips() + 1;
				if(rick > tar){
					rick = rick - tar;
					pw.IssueOrder(curr_p.PlanetID(), p.PlanetID(), tar );
				}
			}
			continue;
		}

		// Determine if I have incoming
		// Don't leave if there are enemy ships pointed at me.
		int incoming = their_targets[curr_p.PlanetID()][0];
		
		// Find the weakest enemy planet.
	  	int their_weakest_planet_id = -1;
		int their_second_weakest_id = -1;
	  	int their_weakest_ships = 0;
		int their_second_weakest_ships = 0;
	  	double weakest_score = -999999.0;
		int their_growth_rate = 0;
	  	for (int i = 0; i < enemy_planets.size(); ++i) {
	    	const Planet& p = enemy_planets[i];
			double dist = pw.Distance(curr_p.PlanetID(), p.PlanetID());	
			double grow = p.GrowthRate();
			their_growth_rate += grow;
	    	double score = 1.0 / ((dist * dist) + p.NumShips());  // This is the best formula so far for finding planet weakness
//	    	double score = grow / ((dist * dist) + p.NumShips());  // Not quite as good as 1.0 / ...
	    	if (score > weakest_score) {
	      		weakest_score = score;
				their_second_weakest_id = their_weakest_planet_id;
	      		their_weakest_planet_id = p.PlanetID();
				their_second_weakest_ships = their_weakest_ships;
	      		their_weakest_ships = p.NumShips();
	    	}
	  	}
		
		double desire = -999999.0;
		int desire_planet_id = -1;
		int desire_ship_count = 0;
		int second_desire_planet_id = enemy_origin;
		int second_desire_ship_count = 0;
		int closest_planet = -1;
		int closest_dist = 1000;
		for(int k = 0; k < not_my_planets.size(); ++k){
			const Planet& cow = not_my_planets[k];
			double dist = pw.Distance(curr_p.PlanetID(), cow.PlanetID());
			double grow = cow.GrowthRate();
			double pop = cow.NumShips();
//			double score = (grow ) / (dist ) ; // this is the default
//			double score = (grow * grow) / (dist * pop) ; // this is also pretty good, need to check them against each other.
			double score = grow / ((dist * dist ) + pop) ; // This is the best one so far.
//			double score = 1.0 / ((dist * dist ) + pop) ; //  Not as good. Second best so far?

			if (dist < closest_dist){
				closest_planet = cow.PlanetID();
				closest_dist = dist;
			}
			if (score > desire){
				desire = score;
				second_desire_planet_id = desire_planet_id;
				desire_planet_id = cow.PlanetID();
				second_desire_ship_count = desire_ship_count;
				desire_ship_count = cow.NumShips();
			}
			if (second_desire_planet_id == -1){
				second_desire_planet_id = desire_planet_id;
			}
		}
		

		
	
		bool i_have_more_planets = ( my_planets.size() > enemy_planets.size() );
		bool i_have_twice_as_many_planets = (my_planets.size() > (enemy_planets.size() * 2));
		bool my_growth_rate_is_higher = ((double)my_growth_rate > ((double)their_growth_rate));
//    	if (i_have_twice_as_many_planets && (their_weakest_planet_id > -1)){
    	if (my_growth_rate_is_higher && (their_weakest_planet_id > -1)){
			if(i_have_twice_as_many_planets){
				int ships_to_send = curr_p.NumShips() / their_planets_size;
				int total_ships = curr_p.NumShips();
				for(int j = 0; j < enemy_planets.size(); ++j){
					if (incoming > 0){
						pw.IssueOrder(curr_p.PlanetID(), enemy_planets[j].PlanetID(), ships_to_send);
					}else{
						if(total_ships > incoming){
							int temp_ships = total_ships - incoming;
							total_ships -= temp_ships;
							pw.IssueOrder(curr_p.PlanetID(), enemy_planets[j].PlanetID(), temp_ships);
						}
					}
				}
			}
// need to sort my planets based on how many ships they have so the first planet will send the most ships and then we can switch targets.			
			else {
				// If this planet has a shit ton of ships, do several things.
				// First, if you have incoming, just chill.  Maybe should call for help?
				if ( incoming > curr_p.NumShips() ){
					continue;
				}
				// Shoot one ship at all their enemy planets, looks like this could be enough to freeze a bunch of people in their tracks.
				int p_ships = curr_p.NumShips();
				if ((p_ships > enemy_planets.size()) && (targeted_everybody == false)){
					targeted_everybody = true;
					for(int q = 0; q < enemy_planets.size(); ++q){
						const Planet& zzz = enemy_planets[q];
						pw.IssueOrder(curr_p.PlanetID(), zzz.PlanetID(), 1);
						p_ships = p_ships - 1;
					}
				}
				int ships = their_weakest_ships * 2;
	        	if (p_ships > ships){
	          		p_ships = p_ships - ships;
	          		// attack their weakest with twice the strength of their weakest
	       			pw.IssueOrder(curr_p.PlanetID(), their_weakest_planet_id, ships );

					if(desire_planet_id > -1){
						if (p_ships > desire_ship_count + 1){
							p_ships -= (desire_ship_count + 1);
							pw.IssueOrder(curr_p.PlanetID(), desire_planet_id, desire_ship_count + 1);
						}
					}
					if(their_second_weakest_id > -1){
						if(p_ships > their_second_weakest_ships + 1){
							p_ships -= (their_second_weakest_ships + 1);
							pw.IssueOrder(curr_p.PlanetID(), their_second_weakest_id, their_second_weakest_ships + 1);
						}
					}
					
	          		// attack the Destination of their current fleet with the rest.					
	          		if (their_most_targeted > -1){
						if(p_ships > 2){
							int to_send = 0;
							if(p_ships > (their_targets[their_most_targeted][0] + 1) ){
								to_send = (their_targets[their_most_targeted][0] + 1) ;
							}else{
								to_send = p_ships / 2;
							}
	            			pw.IssueOrder(curr_p.PlanetID(), their_most_targeted, to_send );
						}
	          		}
	        	}
	        	else{
	          		// this is hit for planets that are not heavily stacked, attack only one target with them.
					if(incoming > 0){
						if(p_ships > incoming){
							// this doesn't really make sense, because incoming should be 0 if this is hit.
							// These two sections are actually backwards from what I intended, have not
							// had time to flip them and verify that they work better in their intended configuration.
							// Nevermind, just did flip them. 
							pw.IssueOrder(curr_p.PlanetID(), their_weakest_planet_id, incoming );
						}
					}else{
						// if ((p_ships > 1) && (desire_planet_id > -1)){
						// 	pw.IssueOrder(curr_p.PlanetID(), their_weakest_planet_id, p_ships / 2 );
						// 	pw.IssueOrder(curr_p.PlanetID(), desire_planet_id, p_ships / 2 );
						// }
						// Neither the above nor the below is significantly better.  Both win 90 of 100 against tenth_bot
						// Need to figure out how to do best of both.
						if ((p_ships > 1) && (their_second_weakest_id > -1)){
							pw.IssueOrder(curr_p.PlanetID(), their_weakest_planet_id, p_ships / 2 );
							pw.IssueOrder(curr_p.PlanetID(), their_second_weakest_id, p_ships / 2 );
						}
						else{
							// Really need to make a save IssueOrder version that checks for valid input
							// luckily this never got called but it had a serious logic flaw.
							if(p_ships > 1){
								pw.IssueOrder(curr_p.PlanetID(), their_weakest_planet_id, p_ships - 1 );
							}
						}
					}
	        	}
			}
      	}
      	// also need to make it so that if the current planet is a target it doesn't send it's ships away.
      	// Keep getting one planet with a shitload of ships, need to loop and send to different targets.
		else{ // if i'm not ahead, or if we can't find a weakest planet for them. 
			if((curr_p.NumShips() > 1)){
				if (incoming > 0){
					if ( (desire_planet_id > -1) && (incoming < curr_p.NumShips()) ){
						pw.IssueOrder(curr_p.PlanetID(), desire_planet_id, curr_p.NumShips() / 2 );	
					}
					// if (desire_planet_id > -1){
					// 	pw.IssueOrder(curr_p.PlanetID(), desire_planet_id, curr_p.NumShips() / 2 );	
					// }
				}else{
					// if(closest_planet > -1){
					// 	pw.IssueOrder(curr_p.PlanetID(), closest_planet, curr_p.NumShips() - 1);  // This is better, 70 out of 100 vs 62
					// }
					if (their_weakest_planet_id > -1){
						pw.IssueOrder(curr_p.PlanetID(), their_weakest_planet_id, curr_p.NumShips() - 1);  // 63 out of 100 vs tenth_bot, tenth_bot goes first.  58 out of 100 vs tenth_bot, MyBot goes first
					}
					// if(desire_planet_id > 0)
					// 	pw.IssueOrder(curr_p.PlanetID(), desire_planet_id, curr_p.NumShips() - 1);  //
					// }
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
