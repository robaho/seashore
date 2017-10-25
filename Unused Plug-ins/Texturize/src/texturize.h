// Counts number of cells != 0 in rempli.
int compter_remplis (guchar ** rempli, int width_i, int height_i);

// Compute the graph, cuts it and updates the image.
void decoupe_graphe(
    int* patch_posn, // Where to put the patch.
    int width_i, int height_i, int width_p, int height_p,
    int channels,
    guchar **rempli, //see render.c. Tells whether the the pixel is filled and if there is a cut here.
    guchar  *image, guchar * patch,
    guchar  *coupe_h_here, guchar * coupe_h_west,   // Pixels lost along an old horizontal cut
    guchar  *coupe_v_here, guchar * coupe_v_north,  // idem for vertical cuts
    gboolean make_tileable, gboolean invert);

// Allocates the memory (with malloc) and fills with 0.
guchar ** init_guchar_tab_2d (gint x, gint y);


/* Compute the best position to put the patch,
 * between (x_patch_posn_min, y_patch_posn_min)
 * and     (x_patch_posn_max, y_patch_posn_max).
 */

void offset_optimal(
    gint *resultat, // The position where the patch will have to be put.
    guchar *image, guchar *patch,
    gint width_p, gint height_p, gint width_i, gint height_i,
    gint x_patch_posn_min, gint y_patch_posn_min, gint x_patch_posn_max, gint y_patch_posn_max,
    // Admissible positions for the patch, this function determines the best one.
    gint channels,
    guchar ** rempli,
    gboolean make_tileable);

// Returns the minimal unfilled pixel under lexicographical order (y,x).
int * pixel_a_remplir (guchar ** rempli, int width_i, int height_i, int* resultat);

gint modulo (gint x, gint m);
