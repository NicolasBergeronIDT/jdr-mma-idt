/**
* Name: CTELDEM3D
* Author: Clément Chion
* Description: 
* Tags: Tag1, Tag2, TagN
*/

model CTELDEM3D
 
 global {
 	// Shapefile de l'inventaire du 4ème décennal 
 	file inventaire_CTEL_shapefile <- file("../includes/PEEFO_4eme_CTEL_mtm8.shp");
 	// Shapefile de du zonage vocationnel proposé par la MRC
 	file affectation_CTEL_shapefile <- file("../includes/Affectation.shp");
 	// Raster du MNT
 	file grid_data <- file("../includes/DEM_CTEL_20x20_MTM.asc");
 	//Image
 	//file dem parameter: 'DEM' <- file('../includes/DEM-Vulcano/DEM.png');
 	file CTEL_bounds_shapefile <- file("../includes/Centre_Touristique_Educatif_Laurentides_S.shp");
    geometry shape <- envelope(CTEL_bounds_shapefile);
 	//nombre d'arbres à l'initialisation
 	int number_of_trees <- 1000;
 	int number_of_dead_trees <-0; 	
 	//redéfinition du pas de temps de simulation à 1 an
 	float step <- 1 #year;	 	
 	//liste qui conserve les arbres vivants
 	list<tree> listOfLivingTrees;
 	
 	//Fait une pause à la simulation lorsque 2000 arbres sont morts
 	reflex endSimulation when: number_of_dead_trees=2000 {
 		write "2000 arbres sont morts";
 		do pause;
 	}

	//Initialisation du modèle
	init{
		//Affichage du DEM;
		ask cell {
			float r;
			float g;
			float b;
			
			r <- 255*(grid_value-299)/(516-299);
			g <- 255*(grid_value-299)/(516-299);
			b <- 255*(grid_value-299)/(516-299);
			self.color<-rgb(r,g,b);				
		}
	
		//création des polygones à partir de l'inventaire du 4ème décennal
		create polygones_inventaire from: inventaire_CTEL_shapefile with: [type::string (read ('TYPE_COUV'))]{
			//peuplements à dominante feuillue
			if type='F' {
	         color <- #lightgreen ;
	      	}
	      	//peuplements à dominante mixte		
		    else if type='M' {
		      color <-  #green;
		    }
		    //peuplements à dominante de résineux
		    else if type='R' {
		      color <- #darkgreen ;
		    }
		    //polygones autres que de la forêt (e.g. lacs)
		    else{
		      color<-#white;
		    }
		}
	
		//liste qui contient les polygones de peuplements forestiers seulement
	 	list<polygones_inventaire> peuplements <- polygones_inventaire where (each.type="F" or each.type="M" or each.type="R");
	
		//création des polygones de zones vocationnelles (proposé par la MRC)	
		create affectation_zone from: affectation_CTEL_shapefile with: [type::string (read ('Affectatio')), sector::int(read('FID_PEEFO_'))] {
	      //write type;
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
	      else {
	      	color <- #magenta ;	      			
	      		}
	   	}
   		
	   	create tree number:number_of_trees{
		
		//À MODIFIER POUR QU'UN ARBRE PUISSE SE TROUVER UNIQUEMENT DANS UN PEUPLEMENT (COUCHE COUVERT_FORESTIER)
		//location<-any_location_in (one_of(peuplements));
		
		//On commence par affecter une position au hasard à chaque arbre dans l'espace de notre monde "world". Par la suite, les deux boucles while
		//permettent de s'assurer que chaque arbre a bien été placé à l'intérieur d'un peuplement forestier. Cette façon d'Affecter les arbres à une potision
		// permet d'assurer que la densité d'Arbre est la même dans chaque peuplement, à l'inverse de la fonction "location<-any_location_in (one_of(peuplements));"
		self.location <- any_location_in(world.shape);		
					
		loop while: (b) {
			int i <- 0;
			loop while: (i < length(peuplements) and !(self.location overlaps peuplements[i].shape)){
				self.location <- any_location_in(world.shape);				
					
				if(self.location overlaps peuplements[i].shape){
					self.b <- false;
					//write self.name;
					break;					
				}
				i<-i+1;				
			}							
		}			
		add self to: world.listOfLivingTrees; 
		}
	}		
		
	grid cell file: grid_data {
	//rgb color <- hsb (0.0,0.0,(grid_value-299)/(516-299));	
	/*reflex decreaseValue {
		grid_value <- grid_value + rnd (0.2) - 0.1;
	}*/
	}
}
	
	species affectation_zone{
	string type;
	int sector; 
	rgb color <- #gray;	
		aspect base {
			draw shape color: color;
		}
	}
	
	species polygones_inventaire{
	//tentative de création d'une géométrie pour accéder aux paramètres de cette couche par requêtes spatiales
	//geometry polyg <-polygon (points);
	string type;
	int sector; 
	rgb color <- #gray;	
		aspect base {
			draw shape color: color;
		}
	}
	
	species tree {
		//donne un âge à chaque arbre aléatoirement entre 0.1 et 50
		int age <- rnd (1,50);		
		bool b <- true;
		rgb color <- #red;
		//string type;		
		//int standID;		
		
		//À chaque pas de temps (1 an), les arbres vont vieillir, s'ils ont plus de 60 ans, ils sont affichés en noir, 
		reflex tree_growth { 		
		    		    
		    if (self.age >60){		    	
		    	color <- #black;
		    	
		    	//Si l'arbre meurt (probablité de age/100 à chaque pas ed temps), un autre d'âge 0 est créé au même emplacement.
		    	if (flip (self.age/100)){
		    		number_of_dead_trees <- number_of_dead_trees + 1;
		    		
		    		create tree{
		    			self.location <-myself.location;
		    			self.age<-0;
		    			add self to: world.listOfLivingTrees; 
		    		}
		    		//retire l'Arbre mort de la liste listOfLivingTrees et faire mourir l'agent arbre
		    		remove self from: world.listOfLivingTrees; 	    		
		    		do die;
		    		}		    		
		    	//write ("nbre d'Arbres morts: " + number_of_dead_trees);
		    }
		    //les arbres vivants vieillissent d'1 an
		    else {
		    	self.age<-self.age+1;
		    }
		}
							
		aspect base {
			draw circle (age/10) color:color at:location;	
		}
	}

experiment DEM type: gui {
	parameter "nombre d'arbres" var: number_of_trees category:"Arbres";
	
	output {

		//Display the grid triangulated in 3D with the cell altitude corresponding to its grid_value and the color cells (if defined otherwise in black)
		display gridWithElevationTriangulated type: opengl autosave: true scale: 1 { 
			grid cell elevation: true triangulation: true ;
			
			species polygones_inventaire aspect: base ;
			species affectation_zone aspect: base ;
		}

		//Display the grid triangulated in 3D with the cell altitude corresponding to its grid_value and the color of cells as a gray value corresponding to grid_value / maxZ *255
		display gridGrayScaledTriangulated type: opengl { 
			grid cell elevation: true grayscale: true triangulation: true;
			species affectation_zone aspect: base ;
			species polygones_inventaire aspect: base ;
		}
		
		display CTEL_display type:opengl {
			species affectation_zone aspect: base ;
			species polygones_inventaire aspect: base ;
			species tree aspect:base refresh:true;
		}
		
		display graph_age_moyen{
			chart "Age moyen des arbres" type: series{
				data "age moyen" value: world.listOfLivingTrees mean_of (each.age);
			}
		}
		

		//Display the textured grid in 3D with the cell altitude corresponding to its grid_value.				
		//display gridTextured type: opengl { 
		//	grid cell texture: texture text: false triangulation: true elevation: true;
		//}
		
		
		//display VulcanoDEMScaled type: opengl draw_env: false { 
		//	graphics 'GraphicPrimitive' {
		//		draw dem(grid_data, 0.1);
		//	}
		//} 
		 
		//display VulcanoDEM type: opengl draw_env: false { 
		//	graphics 'GraphicPrimitive' {
		//		draw dem(grid_data);
		//	}
		//}
	}
}

