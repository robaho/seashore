/*
extern "C" {
#include "config.h"
#include <stdio.h>
#include <stdlib.h>

#include <gtk/gtk.h>
#include <libgimp/gimp.h>
#include <libgimp/gimpui.h>
#include <libgimp/gimpimage_pdb.h>
#include "plugin-intl.h"

#include "main.h"
#include "render.h"
#include "texturize.h"
}
*/
#include "GIMPBridge.h"
#include "texturize.h"
#include "graph.h"

#define MAX_CAPACITY 16383 //la moitié du plus grand short, (captype est short dans graph.h)
#define REMPLI    1
#define CUT_NORTH 2
#define CUT_WEST  4
#define HAS_CUT_NORTH(r) (r) & CUT_NORTH
#define HAS_CUT_WEST(r)  (r) & CUT_WEST

// ||pixel1 - pixel2||^2
// Expérimentalement, le carré semble mieux marcher que la norme 2.
inline Graph::captype
cost (guchar * pixel1, guchar * pixel2, int channels)
{
  int diff, result = 0;
  for (int c = 0; c < channels; c++){
    diff = pixel1[c] - pixel2[c];
    result += diff*diff;
  }
  return (result/24);
  // Il faut diviser au moins par 24 sinon on risque de renvoyer plus que MAX_CAPACITY.
}

inline Graph::captype
gradient (guchar * pixel1, guchar * pixel2, int channels)
{
  int diff, result = 0;
  for (int c = 0; c < channels; c++){
    diff = pixel1[c] - pixel2[c];
    result += diff*diff;
  }
  return ((Graph::captype) sqrt(result));
}

//si les quatre arguments de edge_weight sont écrits dans le code sur deux lignes
//alors les mêmes coordonnées de pixels sont sur une même ligne,
//les mêmes images d'origine du pixel sur une même colonne.
inline Graph::captype
edge_weight (int channels,
             guchar * im1_pix1, guchar * im2_pix1,
             guchar * im1_pix2, guchar * im2_pix2)
{
  return ((cost(im1_pix1,im2_pix1,channels) + (cost(im1_pix2,im2_pix2,channels)))
          / (gradient(im1_pix1,im1_pix2,channels) + gradient(im2_pix1,im2_pix2,channels) +1));
}

inline void
paste_patch_pixel_to_image(int width_i, int height_i, int width_p, int height_p,
                           int x_i, int y_i, int x_p, int y_p,
                           int channels,
                           guchar * image, guchar * patch) {   //,
                           //guchar * coupe_h_here, guchar * coupe_v_here){
  int k;
  for (k = 0; k < channels; k++)
    image[(y_i * width_i + x_i) * channels + k] = patch[(y_p * width_p + x_p) * channels + k];
  /*
  if (y_i < height_i - 1 && y_p < height_p - 1){
    for(k = 0; k < channels; k++)
      coupe_v_here[((y_i + 1) * width_i + x_i) * channels + k] = patch[((y_p + 1) * width_p + x_p) * channels + k];
  }
  if (x_i < width_i - 1 && x_p < width_p - 1) {
    for(k = 0; k < channels; k++)
      coupe_h_here[(y_i * width_i + x_i + 1) * channels + k] = patch[(y_p * width_p + x_p + 1) * channels + k];
  }
  */
}

void
decoupe_graphe (int* patch_posn,
                int width_i, int height_i, int width_p, int height_p,
                int channels,
                guchar  **rempli,
                guchar   *image, guchar * patch,
                guchar   *coupe_h_here, guchar * coupe_h_west,
                guchar   *coupe_v_here, guchar * coupe_v_north,
                gboolean  make_tileable, gboolean invert)
{
////////////////////////////////////////////////////////////////////////////////
// Déclaration des variables
  gint k, x_p, y_p, x_i, y_i;// nb_sommets, sommet_courant; // Compteurs
  gint real_x_i, real_y_i;
  gint x_inf, y_inf, x_sup, y_sup;
  int chute_patch_posn[2];
  Graph * graphe = new Graph(); // Le graphe à couper
  Graph::node_id node_of_pixel[width_p * height_p]; // Le noeud du graph auquel correspond un pointeur.
  for (k=0; k<width_p * height_p; k++) node_of_pixel[k] = NULL;

  Graph::captype poids; // Pour calculer le poids d'un arc avant de le déclarer à Graph:add_edge
  Graph::node_id first_node = NULL, node_sommet_courant; 
  guchar r;
  guchar new_r;

////////////////////////////////////////////////////////////////////////////////
// Création du graphe

  // Définition de l'espace à visiter selon si on veut une texture "tileable"

  if (make_tileable) {
    x_inf = patch_posn[0];
    y_inf = patch_posn[1];
    x_sup = patch_posn[0] + width_p;
    y_sup = patch_posn[1] + height_p;
  } else {
    x_inf = MAX (0, patch_posn[0]);
    y_inf = MAX (0, patch_posn[1]);
    x_sup = MIN (width_i,  patch_posn[0] + width_p);
    y_sup = MIN (height_i, patch_posn[1] + height_p);
  }


  /* Remarque sur la convention "real" :
   *
   *                 ______________________
   *                 |                    |
   *                 |                    |
   *                 |<------- x_i ------>|
   *                 |                    |
   *                 |                    |
   *  <--------------|--------- real_x_i--|--------------->
   *                 |                    |
   *                 |                    |
   *                 ______________________
   */

  // On compte le nombre de sommets en parcourant
  // la région commune au patch et à l'image remplie.

//   nb_sommets = 0;

//   for (real_x_i = x_inf; real_x_i < x_sup; real_x_i++) {
//     for (real_y_i = y_inf; real_y_i < y_sup; real_y_i++) {
//       x_i = modulo (real_x_i, width_i);
//       y_i = modulo (real_y_i, height_i);
//       r = rempli[x_i][y_i];
//       if (r) {
//         nb_sommets++;
// sera décommenté quand on prendra à nouveau en compte les anciennes coupes
//         if (HAS_CUT_NORTH(r)) nb_sommets++;
//         if (HAS_CUT_WEST(r))  nb_sommets++;
//       }
//     }
//   }

  // On commence par parcourir tout le patch une première fois pour créer les noeuds
  // et faire les liens dans node_of_pixel

  for (real_x_i = x_inf;
       real_x_i < x_sup;
       real_x_i++) {
    x_p = real_x_i - patch_posn[0];
    x_i = modulo (real_x_i, width_i);
    for (real_y_i = y_inf;
         real_y_i < y_sup;
         real_y_i++) {
      y_p = real_y_i - patch_posn[1];
      y_i = modulo (real_y_i, height_i);

      // Si le pixel de l'image n'est pas rempli, on ne fait rien et on passe au suivant
      if (rempli[x_i][y_i]) {
        node_of_pixel[x_p * height_p + y_p] = graphe->add_node ();
        if (first_node == NULL) first_node = node_of_pixel[x_p * height_p + y_p];
      }
    }
  }

  // On crée les arcs.
  /*
  On relie à la source les pixels à la fois remplis et au bord du patch
    (et, dans le cas sans make_tileable, qui de plus ne sont pas au bord de l'image).
  On relie au puits les pixels remplis dont un voisin n'est pas rempli.

  **********************************************

  Synopsis de la boucle :

  Pour chaque x du patch (intersection avec l'image dans le cas !make_tileable)
   Pour chaque y du patch (même remarque)
    Si je suis rempli
     Créer les arcs avec mes voisins nord et ouest (s'ils existent dans le patch)
     (plus tard en gérant les anciennes coupes)
     Si je suis au bord du patch (ie personne dans le patch au nord OU au sud OU à l'est OU à l'ouest)
     Et dans le cas !make_tileable, si de plus je ne suis pas au bord de l'image (1)
      Me relier à la source
     Si l'un de mes voisins (nord, sud, est, ouest) existe (dans le patch ET dans l'image) et n'est pas rempli
      Me relier au puits
    Si je ne suis pas rempli
     Ne rien faire

  //Le test (1) ci dessus peut faire en sorte qu'il n'y ait aucun pixel relié à la source;
  //la ligne suivante pallie ce pb.
  Si !make_tileable, relier le pixel haut gauche de l'intersection (le premier créé) à la source.
  */

  for (real_x_i = x_inf;
       real_x_i < x_sup;
       real_x_i++) {
    x_p = real_x_i - patch_posn[0];
    x_i = modulo (real_x_i, width_i);

    for (real_y_i = y_inf;
         real_y_i < y_sup;
         real_y_i++) {
      y_p = real_y_i - patch_posn[1];
      y_i = modulo (real_y_i, height_i);

      // Si le pixel de l'image n'est pas rempli, on ne fait rien et on passe au suivant
      if (!rempli[x_i][y_i]) {
        continue;
      } else {
        // Création du noeud et liens
        node_sommet_courant = node_of_pixel[x_p * height_p + y_p];

        // Si le voisin nord existe dans le patch et si le pixel nord
        // est rempli dans l'image, on crée un lien vers lui
        if ((!make_tileable && y_p != 0 && y_i != 0 && rempli[x_i][y_i - 1])
          || (make_tileable && y_p != 0 && rempli[x_i][modulo (y_i - 1, height_i)])) {
          poids = edge_weight (channels,
                               image + ((y_i * width_i + x_i) * channels),
                               patch + ((y_p * width_p + x_p) * channels),
                               image + (((modulo (y_i - 1, height_i)) * width_i + x_i) * channels),
                               patch + (((y_p - 1) * width_p + x_p) * channels));
          graphe->add_edge (node_sommet_courant,
                            node_of_pixel[x_p * height_p + y_p - 1],
                            poids, poids);
        }

        // Si le voisin ouest existe dans le patch et si le pixel ouest
        // est rempli dans l'image, on crée un lien avec lui
        if ((!make_tileable && x_p != 0 && x_i != 0 && rempli[x_i - 1][y_i])
          || (make_tileable && x_p != 0 && rempli[modulo (x_i - 1, width_i)][y_i])) {
          poids = edge_weight (channels,
                               image + ((y_i * width_i + x_i) * channels),
                               patch + ((y_p * width_p + x_p) * channels),
                               image + ((y_i * width_i + (modulo (x_i, width_i) - 1)) * channels),
                               patch + ((y_p * width_p + (x_p - 1)) * channels));
          graphe->add_edge (node_sommet_courant,
                            node_of_pixel[(x_p - 1) * height_p + y_p],
                            poids, poids);
        }

        // Si je suis au bord du patch et si en plus, dans le cas !make_tileable,
        // je ne suis pas au bord de l'image, me relier à la source
        if (    (make_tileable && (x_p == 0 || y_p == 0 || x_p == width_p - 1 || y_p == height_p - 1))
            || (!make_tileable && (x_p == 0 || y_p == 0 || x_p == width_p - 1 || y_p == height_p - 1)
		               &&  x_i != 0 && y_i != 0 && x_i != width_i - 1 && y_i != height_i - 1)) {
          graphe->add_tweights (node_sommet_courant, MAX_CAPACITY, 0);
	}

        // Si l'un de mes voisins existe et n'est pas rempli, me relier au puits
        if (((!make_tileable)
              && (  (y_p != 0            && y_i != 0            && !rempli[x_i][y_i - 1])      // Nord
                 || (y_p != height_p - 1 && y_i != height_i - 1 && !rempli[x_i][y_i + 1])      // Sud
                 || (x_p != width_p - 1  && x_i != width_i - 1  && !rempli[x_i + 1][y_i])      // Est
                 || (x_p != 0            && x_i != 0            && !rempli[x_i - 1][y_i])))    // Ouest
            || ((make_tileable)
              && (  (y_p != 0            && !rempli[x_i][modulo (y_i - 1, height_i)])          // Nord
                 || (y_p != height_p - 1 && !rempli[x_i][modulo (y_i + 1, height_i)])          // Sud
                 || (x_p != width_p - 1  && !rempli[modulo (x_i + 1, width_i)][y_i])           // Est
                 || (x_p != 0            && !rempli[modulo (x_i - 1, width_i)][y_i])))) {      // Ouest
	  //	  printf ("Connecting %i, %i to Sink\n", x_p, y_p);
          graphe->add_tweights (node_sommet_courant, 0, MAX_CAPACITY);
	}
      }
    }
  }

  // Si !make_tileable, on relie à la source le pixel haut gauche de patch \cap image
  if (!make_tileable) {
    graphe->add_tweights (first_node, MAX_CAPACITY, 0);
  }


////////////////////////////////////////////////////////////////////////////////
// Calcul de la coupe

  graphe->maxflow ();

////////////////////////////////////////////////////////////////////////////////
// Mise_a_jour de l'image

  for (real_x_i = x_inf; real_x_i < x_sup; real_x_i++) {
    x_p = real_x_i - patch_posn[0];
    x_i = modulo (real_x_i, width_i);
    for (real_y_i = y_inf; real_y_i < y_sup; real_y_i++) {
      y_p = real_y_i - patch_posn[1];
      y_i = modulo (real_y_i, height_i);
      r = rempli[x_i][y_i];
      if (r) {
        if (graphe->what_segment(node_of_pixel[x_p * height_p + y_p]) == Graph::SINK) {
          paste_patch_pixel_to_image (width_i, height_i, width_p, height_p, x_i, y_i, x_p, y_p,
                                      channels, image, patch); //,
                                      //coupe_h_here, coupe_v_here);
	}
      } else { // (!rempli[x_i][y_i])
        paste_patch_pixel_to_image (width_i, height_i, width_p, height_p, x_i, y_i, x_p, y_p,
                                    channels, image, patch); //,
	//coupe_h_here, coupe_v_here);
        rempli[x_i][y_i] = REMPLI;
      }
    }
  }

////////////////////////////////////////////////////////////////////////////////
//On nettoie tout

  delete graphe;

  return;
}
