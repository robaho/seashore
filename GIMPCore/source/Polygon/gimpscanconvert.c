#include "gimpscanconvert.h"

/* private functions */
static void   gimp_scan_convert_close_add_points (GimpScanConvert *sc);

/*  public functions  */

/**
 * gimp_scan_convert_new:
 *
 * Create a new scan conversion context.
 *
 * Return value: a newly allocated #GimpScanConvert context.
 */
GimpScanConvert *
gimp_scan_convert_new (void)
{
  GimpScanConvert *sc;

  sc = g_new0 (GimpScanConvert, 1);

  sc->ratio_xy = 1.0;

  return sc;
}

/**
 * gimp_scan_convert_free:
 * @sc: a #GimpScanConvert context
 *
 * Frees the resources allocated for @sc.
 */
void
gimp_scan_convert_free (GimpScanConvert *sc)
{
  if (sc->vpath)
    art_free (sc->vpath);
  if (sc->svp)
    art_svp_free (sc->svp);

  g_free (sc);
}

/**
 * gimp_scan_convert_set_pixel_ratio:
 * @sc:       a #GimpScanConvert context
 * @ratio_xy: the aspect ratio of the major coordinate axes
 *
 * Sets the pixel aspect ratio.
 */
void
gimp_scan_convert_set_pixel_ratio (GimpScanConvert *sc,
                                   gdouble          ratio_xy)
{
  /* we only need the relative resolution */
  sc->ratio_xy = ratio_xy;
}

/**
 * gimp_scan_convert_set_clip_rectangle
 * @sc:     a #GimpScanConvert context
 * @x:      horizontal offset of clip rectangle
 * @y:      vertical offset of clip rectangle
 * @width:  width of clip rectangle
 * @height: height of clip rectangle
 *
 * Sets a clip rectangle on @sc. Subsequent render operations will be
 * restricted to this area.
 */
void
gimp_scan_convert_set_clip_rectangle (GimpScanConvert *sc,
                                      gint             x,
                                      gint             y,
                                      gint             width,
                                      gint             height)
{
  sc->clip   = TRUE;
  sc->clip_x = x;
  sc->clip_y = y;
  sc->clip_w = width;
  sc->clip_h = height;
}


static void
gimp_scan_convert_close_add_points (GimpScanConvert *sc)
{
  if (sc->need_closing &&
      (sc->prev.x != sc->first.x || sc->prev.y != sc->first.y))
    {
      sc->vpath = art_renew (sc->vpath, ArtVpath, sc->num_nodes + 2);
      sc->vpath[sc->num_nodes].code = ART_LINETO;
      sc->vpath[sc->num_nodes].x = sc->first.x;
      sc->vpath[sc->num_nodes].y = sc->first.y;
      sc->num_nodes++;
      sc->vpath[sc->num_nodes].code = ART_END;
      sc->vpath[sc->num_nodes].x = 0.0;
      sc->vpath[sc->num_nodes].y = 0.0;
    }

  sc->need_closing = FALSE;
}


/**
 * gimp_scan_convert_add_polyline:
 * @sc:       a #GimpScanConvert context
 * @n_points: number of points to add
 * @points:   array of points to add
 * @closed:   whether to close the polyline and make it a polygon
 *
 * Add a polyline with @n_points @points that may be open or closed.
 * It is not recommended to mix gimp_scan_convert_add_polyline() with
 * gimp_scan_convert_add_points().
 *
 * Please note that you should use gimp_scan_convert_stroke() if you
 * specify open polygons.
 */
void
gimp_scan_convert_add_polyline (GimpScanConvert *sc,
                                guint            n_points,
                                GimpVector2     *points,
                                gboolean         closed)
{
  GimpVector2  prev = { 0.0, 0.0, };
  gint         i;

  if (sc->need_closing)
    gimp_scan_convert_close_add_points (sc);

  if (!closed)
    sc->have_open = TRUE;

  /* make sure that we have enough space for the nodes */
  sc->vpath = art_renew (sc->vpath, ArtVpath,
                         sc->num_nodes + n_points + 2);

  for (i = 0; i < n_points; i++)
    {
      /* compress multiple identical coordinates */
      if (i == 0 ||
          prev.x != points[i].x ||
          prev.y != points[i].y)
        {
          sc->vpath[sc->num_nodes].code = (i == 0 ? (closed ?
                                                     ART_MOVETO :
                                                     ART_MOVETO_OPEN) :
                                                    ART_LINETO);
          sc->vpath[sc->num_nodes].x = points[i].x;
          sc->vpath[sc->num_nodes].y = points[i].y;
          sc->num_nodes++;
          prev = points[i];
        }
    }

  /* close the polyline when needed */
  if (closed && (prev.x != points[0].x ||
                 prev.y != points[0].y))
    {
      sc->vpath[sc->num_nodes].x = points[0].x;
      sc->vpath[sc->num_nodes].y = points[0].y;
      sc->vpath[sc->num_nodes].code = ART_LINETO;
      sc->num_nodes++;
    }

  sc->vpath[sc->num_nodes].code = ART_END;
  sc->vpath[sc->num_nodes].x = 0.0;
  sc->vpath[sc->num_nodes].y = 0.0;

  /* If someone wants to mix this function with _add_points ()
   * try to do something reasonable...
   */
  sc->got_first = FALSE;
}

/* private function to convert the vpath to a svp when not using
 * gimp_scan_convert_stroke
 */
void
gimp_scan_convert_finish (GimpScanConvert *sc)
{
  ArtSVP       *svp , *svp2;
  ArtSvpWriter *swr;

  /* return gracefully on empty path */
  if (!sc->vpath)
    return;

  if (sc->need_closing)
    gimp_scan_convert_close_add_points (sc);


  if (sc->svp)
    return;   /* We already have a valid SVP */

  /* Debug output of libart path */
  /* {
   *   gint i;
   *   for (i = 0; i < sc->num_nodes + 1; i++)
   *     {
   *       g_printerr ("X: %f, Y: %f, Type: %d\n", sc->vpath[i].x,
   *                                               sc->vpath[i].y,
   *                                               sc->vpath[i].code );
   *     }
   * }
   */

  if (sc->have_open)
    {
      gint i;

      for (i = 0; i < sc->num_nodes; i++)
        if (sc->vpath[i].code == ART_MOVETO_OPEN)
          {
            //g_printerr ("Fixing ART_MOVETO_OPEN - result might be incorrect\n");
            sc->vpath[i].code = ART_MOVETO;
          }
    }

  svp = art_svp_from_vpath (sc->vpath);

  swr = art_svp_writer_rewind_new (ART_WIND_RULE_ODDEVEN);
  art_svp_intersector (svp, swr);

  svp2 = art_svp_writer_rewind_reap (swr); /* this also frees swr */

  art_svp_free (svp);

  sc->svp = svp2;
}
