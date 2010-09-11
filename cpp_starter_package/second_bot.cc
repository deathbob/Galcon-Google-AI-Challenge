#include <iostream>
#include "PlanetWars.h"

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
  // (1) If we currently have a fleet in flight, just do nothing.
  if (pw.MyFleets().size() >= 2) {
    return;
  }
  std::vector<Planet> my_planets = pw.MyPlanets();
  std::vector<Planet> neutral_planets = pw.NeutralPlanets();
  std::vector<Planet> not_my_planets = pw.NotMyPlanets();
  std::vector<Planet> enemy_planets = pw.EnemyPlanets(); 
  
  std::vector<Fleet> enemy_fleets = pw.EnemyFleets();
  int dest = -1;
  for(int i = 0; i < enemy_fleets.size(); ++i) {
    const Fleet& f = enemy_fleets[i];
    dest = f.DestinationPlanet();
  }
  
        
  // Find planet that I own with highest growth factor
  int my_hgr = 0;
  int hgr_planet_id = -1;
  int hgr_ship_count = 0;
  for (int i = 0; i < my_planets.size(); ++i) {
    const Planet& p = my_planets[i];
    int gr = p.GrowthRate();
    if (gr > my_hgr) {
      my_hgr = gr;
      hgr_planet_id = p.PlanetID();
      hgr_ship_count = p.NumShips();
    }
  }
  
  // Find neutral planet with highest growth factor
  int nhgr = 0;  
  int nhgr_planet_id = -1;
  int nhgr_ship_count = 0;
  
  for(int i = 0; i < neutral_planets.size(); ++i){
    const Planet& p = neutral_planets[i];
    int gr = p.GrowthRate();
    if(gr > nhgr){
      nhgr = gr;
      nhgr_planet_id = p.PlanetID();
      nhgr_ship_count = p.NumShips();
    }
  }

  // (2) Find my strongest planet.
  int my_strongest = -1;
  double strongest_score = -999999.0;
  int strongest_ships = 0;
  for (int i = 0; i < my_planets.size(); ++i) {
    const Planet& p = my_planets[i];
    double score = (double)p.NumShips();
    if (score > strongest_score) {
      strongest_score = score;
      my_strongest = p.PlanetID();
      strongest_ships = p.NumShips();
    }
  }
  
  // (3) Find the weakest enemy planet.
  int their_weakest = -1;
  int weakest_ships = 0;
  double weakest_score = -999999.0;
  for (int i = 0; i < enemy_planets.size(); ++i) {
    const Planet& p = enemy_planets[i];
    double score = 1.0 / (1 + p.NumShips());
    if (score > weakest_score) {
      weakest_score = score;
      their_weakest = p.PlanetID();
      weakest_ships = p.NumShips();
    }
  }

  bool flip = false;
  for (int i = 0; i < my_planets.size(); ++i) {
    const Planet& p = my_planets[i];
    if (flip){
      if(their_weakest > 0){
        pw.IssueOrder(p.PlanetID(), their_weakest, p.NumShips() / 2);
      }
    }else{
      if(dest > 0){
        pw.IssueOrder(p.PlanetID(), dest, p.NumShips() / 2);
      }
    }
    flip = !flip;    
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
