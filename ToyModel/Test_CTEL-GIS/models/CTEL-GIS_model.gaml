/**
* Name: CTELGISmodel
* Author: Clement
* Description: 
* Tags: Tag1, Tag2, TagN
*/

model CTELGISmodel

/* Insert your model definition here */

global{
	//Shapefile du CTEL
   file affectation_CTEL_shapefile <- file("../includes/Affectation.shp");
   file CTEL_bounds_shapefile <- file("../includes/Centre_Touristique_Educatif_Laurentides_S.shp");
   geometry shape <- envelope(CTEL_bounds_shapefile);
   init{
	create affectation_zone from: affectation_CTEL_shapefile with: [type::string (read ('Affectatio'))] {
      write type;
      if type='PFNL' {
         color <- #blue ;
      		}		
      else if type='Conservation' {
         color <- #pink ;
      		}
      else if type='Educatif' {
         color <- #yellow ;
      		}
      else if type='Faune' {
         color <- #purple ;
      		}
      else if type='Touristique' {
         color <- #red ;
      		}
      else if type='Foresterie intensive' {
         color <- #green ;
      		}
      else if type='Foresterie urbaine' {
         color <- #grey ;
      		}
      else if type='Villegiature' {
         color <- #black ;
      		}
      		else {color <- #magenta ;}
   		}
	}
}


species affectation_zone{
	string type;
	int sector; 
	rgb color <- #gray  ;
	
	aspect base {
		draw shape color: color ;
	}
}

experiment my_experiment type: gui {
	parameter "Shapefile for the affectation:" var: affectation_CTEL_shapefile category: "GIS" ;
	
	output {
		display CTEL_display type:opengl {
			species affectation_zone aspect: base ;
		}
	}
}