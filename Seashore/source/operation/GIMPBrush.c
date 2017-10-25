/*
	Seashore 0.0.4
	
	More or less the GIMP's code for brushes.

	Copyright (c) 1995 Spencer Kimball and Peter Mattis
	Distributed under the terms of the GNU General Public License
*/

#include "GIMPBridge.h"

gdouble
gimp_vector2_inner_product (GimpVector2 *vector1,
			    GimpVector2 *vector2)
{
  g_assert (vector1 != NULL);
  g_assert (vector2 != NULL);

  return (vector1->x * vector2->x + vector1->y * vector2->y);
}

gdouble
gimp_vector2_length (GimpVector2 *vector)
{
  g_assert (vector != NULL);

  return (sqrt (vector->x * vector->x + vector->y * vector->y));
}

static void
gimp_avoid_exact_integer (gdouble *x)
{
  gdouble integral   = floor (*x);
  gdouble fractional = *x - integral;

  if (fractional < EPSILON)
    *x = integral + EPSILON;
  else if (fractional > (1-EPSILON))
    *x = integral + (1-EPSILON);
}

void
gimp_paint_core_interpolate (GimpPaintCore    *core,
			     GimpDrawable     *drawable,
                             GimpPaintOptions *paint_options)
{
  GimpCoords  delta;
  gint        n, num_points;
  gdouble     t0, dt, tn;
  gdouble     st_factor, st_offset;
  gdouble     initial;
  gdouble     dist;
  gdouble     total;
  gdouble     pixel_dist;
  gdouble     pixel_initial;
  gdouble     xd, yd;
  gdouble     mag;

  g_return_if_fail (GIMP_IS_PAINT_CORE (core));
  g_return_if_fail (GIMP_IS_DRAWABLE (drawable));
  g_return_if_fail (paint_options != NULL);

  gimp_avoid_exact_integer (&core->last_coords.x);
  gimp_avoid_exact_integer (&core->last_coords.y);
  gimp_avoid_exact_integer (&core->cur_coords.x);
  gimp_avoid_exact_integer (&core->cur_coords.y);
  
  delta.x        = core->cur_coords.x        - core->last_coords.x;
  delta.y        = core->cur_coords.y        - core->last_coords.y;
  delta.pressure = core->cur_coords.pressure - core->last_coords.pressure;
  delta.xtilt    = core->cur_coords.xtilt    - core->last_coords.xtilt;
  delta.ytilt    = core->cur_coords.ytilt    - core->last_coords.ytilt;
  delta.wheel    = core->cur_coords.wheel    - core->last_coords.wheel;

  /*  return if there has been no motion  */
  if (! delta.x        &&
      ! delta.y        &&
      ! delta.pressure &&
      ! delta.xtilt    &&
      ! delta.ytilt    &&
      ! delta.wheel)
    return;

  /* calculate the distance traveled in the coordinate space of the brush */
  mag = gimp_vector2_length (&(core->brush->x_axis));
  xd  = gimp_vector2_inner_product ((GimpVector2 *) &delta,
				    &(core->brush->x_axis)) / (mag * mag);

  mag = gimp_vector2_length (&(core->brush->y_axis));
  yd  = gimp_vector2_inner_product ((GimpVector2 *) &delta,
				    &(core->brush->y_axis)) / (mag * mag);

  dist    = 0.5 * sqrt (xd * xd + yd * yd);
  total   = dist + core->distance;
  initial = core->distance;

  pixel_dist    = gimp_vector2_length ((GimpVector2 *) &delta);
  pixel_initial = core->pixel_dist;

  /*  FIXME: need to adapt the spacing to the size  */
  /*   lastscale = MIN (gimp_paint_tool->lastpressure, 1/256); */
  /*   curscale = MIN (gimp_paint_tool->curpressure,  1/256); */
  /*   spacing = gimp_paint_tool->spacing * sqrt (0.5 * (lastscale + curscale)); */

  /*  Compute spacing parameters such that a brush position will be
   *  made each time the line crosses the *center* of a pixel row or
   *  column, according to whether the line is mostly horizontal or
   *  mostly vertical. The term "stripe" will mean "column" if the
   *  line is horizontalish; "row" if the line is verticalish.
   *
   *  We start by deriving coefficients for a new parameter 's':
   *      s = t * st_factor + st_offset
   *  such that the "nice" brush positions are the ones with *integer*
   *  s values. (Actually the value of s will be 1/2 less than the nice
   *  brush position's x or y coordinate - note that st_factor may
   *  be negative!)
   */
  
  if (delta.x*delta.x > delta.y*delta.y)
    {
      st_factor = delta.x;
      st_offset = core->last_coords.x - 0.5;
    }
  else
    {
      st_factor = delta.y;
      st_offset = core->last_coords.y - 0.5;
    }
  
  if (fabs (st_factor) > dist / core->spacing)
    {
      /*  The stripe principle leads to brush positions that are spaced
       *  *closer* than the official brush spacing. Use the official
       *  spacing instead. This is the common case when the brush spacing
       *  is large.
       *  The net effect is then to put a lower bound on the spacing, but
       *  one that varies with the slope of the line. This is suppose to
       *  make thin lines (say, with a 1x1 brush) prettier while leaving
       *  lines with larger brush spacing as they used to look in 1.2.x.
       */
      dt = core->spacing / dist;
      n = (gint) (initial / core->spacing + 1.0 + EPSILON);
      t0 = (n * core->spacing - initial) / dist;
      num_points = 1 + (gint) floor ((1 + EPSILON - t0) / dt);
    }
  else if (fabs (st_factor) < EPSILON)
    {
      /* Hm, we've hardly moved at all. Don't draw anything, but reset the
       * old coordinates and hope we've gone longer the next time.
       */
      core->cur_coords.x = core->last_coords.x;
      core->cur_coords.y = core->last_coords.y;
      /* ... but go along with the current pressure, tilt and wheel */
      return;
    }
  else
    {
      gint direction = st_factor > 0 ? 1 : -1;
      gint x, y;
      gint s0, sn;

      /*  Choose the first and last stripe to paint.
       *    FIRST PRIORITY is to avoid gaps painting with a 1x1 aliasing
       *  brush when a horizontalish line segment follows a verticalish
       *  one or vice versa - no matter what the angle between the two
       *  lines is. This will also limit the local thinning that a 1x1
       *  subsampled brush may suffer in the same situation.
       *    SECOND PRIORITY is to avoid making free-hand drawings
       *  unpleasantly fat by plotting redundant points.
       *    These are achieved by the following rules, but it is a little
       *  tricky to see just why. Do not change this algorithm unless you
       *  are sure you know what you're doing!
       */
      
      /*  Basic case: round the beginning and ending point to nearest
       *  stripe center.
       */
      s0 = (gint) floor (st_offset + 0.5);
      sn = (gint) floor (st_offset + st_factor + 0.5);

      t0 = (s0 - st_offset) / st_factor;
      tn = (sn - st_offset) / st_factor;
      
      x = (gint) floor (core->last_coords.x + t0 * delta.x);
      y = (gint) floor (core->last_coords.y + t0 * delta.y);
      if (t0 < 0.0 && !( x == (gint) floor (core->last_coords.x) &&
                         y == (gint) floor (core->last_coords.y) ))
        {
          /*  Exception A: If the first stripe's brush position is
           *  EXTRApolated into a different pixel square than the
           *  ideal starting point, dont't plot it.
           */
          s0 += direction;
        }
      else if (x == (gint) floor (core->last_paint.x) &&
               y == (gint) floor (core->last_paint.y))
        {
          /*  Exception B: If first stripe's brush position is within the
           *  same pixel square as the last plot of the previous line,
           *  don't plot it either.
           */
          s0 += direction;
        }

      x = (gint) floor (core->last_coords.x + tn * delta.x);
      y = (gint) floor (core->last_coords.y + tn * delta.y);
      if (tn > 1.0 && !( x == (gint) floor( core->cur_coords.x ) &&
                         y == (gint) floor( core->cur_coords.y ) ))
        {
          /*  Exception C: If the last stripe's brush position is
           *  EXTRApolated into a different pixel square than the
           *  ideal ending point, don't plot it.
           */
          sn -= direction;
        }

      t0 = (s0 - st_offset) / st_factor;
      tn = (sn - st_offset) / st_factor;
      dt         =     direction * 1.0 / st_factor;
      num_points = 1 + direction * (sn - s0);

      if (num_points >= 1)
        {
          /*  Hack the reported total distance such that it looks to the
           *  next line as if the the last pixel plotted were at an integer
           *  multiple of the brush spacing. This helps prevent artifacts
           *  for connected lines when the brush spacing is such that some
           *  slopes will use the stripe regime and other slopes will use
           *  the nominal brush spacing.
           */

          if (tn < 1)
            total = initial + tn * dist;

          total = core->spacing * (gint) (total / core->spacing + 0.5);
          total += (1.0 - tn) * dist;
        }
    }

  for (n = 0; n < num_points; n++)
    {
      GimpBrush *current_brush;
      gdouble    t = t0 + n*dt;

      core->cur_coords.x        = core->last_coords.x        + t * delta.x;
      core->cur_coords.y        = core->last_coords.y        + t * delta.y;
      core->cur_coords.pressure = core->last_coords.pressure + t * delta.pressure;
      core->cur_coords.xtilt    = core->last_coords.xtilt    + t * delta.xtilt;
      core->cur_coords.ytilt    = core->last_coords.ytilt    + t * delta.ytilt;
      core->cur_coords.wheel    = core->last_coords.wheel    + t * delta.wheel;

      core->distance            = initial                    + t * dist;
      core->pixel_dist          = pixel_initial              + t * pixel_dist;

      /*  save the current brush  */
      current_brush = core->brush;

      gimp_paint_core_paint (core, drawable, paint_options, MOTION_PAINT);

      /*  restore the current brush pointer  */
      core->brush = current_brush;
    }

  core->cur_coords.x        = core->last_coords.x        + delta.x;
  core->cur_coords.y        = core->last_coords.y        + delta.y;
  core->cur_coords.pressure = core->last_coords.pressure + delta.pressure;
  core->cur_coords.xtilt    = core->last_coords.xtilt    + delta.xtilt;
  core->cur_coords.ytilt    = core->last_coords.ytilt    + delta.ytilt;
  core->cur_coords.wheel    = core->last_coords.wheel    + delta.wheel;

  core->distance   = total;
  core->pixel_dist = pixel_initial + pixel_dist;
}
