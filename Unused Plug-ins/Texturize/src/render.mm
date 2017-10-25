#include "GIMPBridge.h"
#include "texturize.h"

int render(unsigned char *image_in, int width_in, int height_in, unsigned char *image_out, int width_out, int height_out, int overlap, int channels, char tileable, id progressBar);

int render(unsigned char *image_in, int width_in, int height_in, unsigned char *image_out, int width_out, int height_out, int overlap, int channels, char tileable, id progressBar)
{
	int k, x_i, y_i;
	unsigned char *coupe_h_here, *coupe_h_west, *coupe_v_here, *coupe_v_north;
	unsigned char **rempli;
	int cur_posn[2], patch_posn[2];
	int x_off_min, y_off_min, x_off_max, y_off_max;
	double progress;
	
	gimp_progress_init ("Texturizing image...");

	x_off_min = MIN (overlap, width_in - 1);
	y_off_min = MIN (overlap, height_in - 1);
	x_off_max = CLAMP (20, x_off_min/3, width_in -1);
	y_off_max = CLAMP (20, y_off_min/3, height_in - 1);

	rempli = init_guchar_tab_2d (width_out, height_out);

	coupe_h_here  = g_new (guchar, width_out * height_out * channels);
	coupe_h_west  = g_new (guchar, width_out * height_out * channels);
	coupe_v_here  = g_new (guchar, width_out * height_out * channels);
	coupe_v_north = g_new (guchar, width_out * height_out * channels);
	
	for (k = 0; k < width_out * height_out * channels; k++)
		coupe_h_here[k] = coupe_h_west[k] = coupe_v_here[k] = coupe_v_north[k] = 0;
	
	for (x_i = 0; x_i < width_in; x_i++) {
		for (y_i = 0; y_i < height_in; y_i++) rempli[x_i][y_i] = 1;
	}

	cur_posn[0] = 0; cur_posn[1] = 0;

	while (compter_remplis (rempli,width_out,height_out) < (width_out * height_out)) {
		if (pixel_a_remplir (rempli, width_out, height_out, cur_posn) == NULL) {
			g_message (_("There was a problem when filling the new image."));
			return -1;
		};

		offset_optimal (patch_posn,
		image_out, image_in,
		width_in, height_in, width_out, height_out,
		cur_posn[0] - x_off_min,
		cur_posn[1] - y_off_min,
		cur_posn[0] - x_off_max,
		cur_posn[1] - y_off_max,
		channels,
		rempli,
		tileable);

		decoupe_graphe (patch_posn,
		width_out, height_out, width_in, height_in,
		channels,
		rempli,
		image_out,
		image_in,
		coupe_h_here, coupe_h_west, coupe_v_here, coupe_v_north,
		tileable,
		FALSE);

		progress = ((double) compter_remplis (rempli, width_out, height_out)) / ((double)(width_out * height_out));
		[progressBar setDoubleValue:progress];
		[progressBar display];
	}

	g_free (coupe_h_here);
	g_free (coupe_h_west);
	g_free (coupe_v_here);
	g_free (coupe_v_north);

	return 0;
}