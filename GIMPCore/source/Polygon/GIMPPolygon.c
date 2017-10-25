#include "gimpscanconvert.h"
/*
	GCPolygonCallback
	
	Actually draws on the bitmap being called from the svp_render.
*/
static void GCPolygonCallback (gpointer user_data, gint y, gint start_value, ArtSVPRenderAAStep *steps, gint n_steps);


void GCDrawPolygon(unsigned char *dest, int destWidth, int destHeight, GimpVector2 *points, int n_points, int spp)
{
	GimpScanConvert *scan_convert;

	scan_convert = gimp_scan_convert_new ();
	
	gimp_scan_convert_add_polyline (scan_convert, n_points, points, TRUE);

	/*gimp_scan_convert_render (scan_convert,
							gimp_drawable_data (GIMP_DRAWABLE (add_on)),
							offset_x, offset_y, antialias);*/
							
	gimp_scan_convert_finish (scan_convert);

	scan_convert->antialias = 1;
	scan_convert->spp     = spp;

	gpointer callback = GCPolygonCallback;

	scan_convert->buf       = dest;
	scan_convert->rowstride = destWidth * spp;
	scan_convert->x0        = 0;
	scan_convert->x1        = destWidth;

	art_svp_render_aa (scan_convert->svp,
					 scan_convert->x0, 0,
					 scan_convert->x1, destHeight,
					 callback, scan_convert);

	gimp_scan_convert_free (scan_convert);
}

void GCPolygonCallback (gpointer user_data, gint y, gint start_value, ArtSVPRenderAAStep *steps, gint n_steps)
{
	GimpScanConvert *sc        = user_data;
	gint             cur_value = start_value;
	gint			spp = sc->spp;
	gint             run_x0;
	gint             run_x1;
	gint             k;
	
	if (n_steps > 0)
	{
		run_x1 = steps[0].x;

		if (run_x1 > sc->x0)
			memset (sc->buf, ((cur_value) >> 16), (run_x1 - sc->x0) * spp);
		for (k = 0; k < n_steps - 1; k++)
		{
			cur_value += steps[k].delta;

			run_x0 = run_x1;
			run_x1 = steps[k + 1].x;
			if (run_x1 > run_x0)
				memset (sc->buf + (run_x0 - sc->x0) * spp , ((cur_value) >> 16), (run_x1 - run_x0) * spp);
		}

		cur_value += steps[k].delta;

		if (sc->x1 > run_x1)
			memset (sc->buf + (run_x1 - sc->x0) * spp , ((cur_value) >> 16), (sc->x1 - run_x1) * spp);
	}
	else
	{
		memset (sc->buf, ((cur_value) >> 16), (sc->x1 - sc->x0) * spp);
	}

	sc->buf += sc->rowstride;
}