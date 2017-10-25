#include "GIMPCore.h"
#include "GIMPBridge.h"
#include "Gradient.h"
#include "gimprgb.h"
#include "gimpadaptivesupersample.h"

/*  local function prototypes  */

static gdouble gradient_calc_conical_sym_factor  (gdouble          dist,
						  gdouble         *axis,
						  gdouble          offset,
						  gdouble          x,
						  gdouble          y);
static gdouble gradient_calc_conical_asym_factor (gdouble          dist,
						  gdouble         *axis,
						  gdouble          offset,
						  gdouble          x,
						  gdouble          y);
static gdouble gradient_calc_square_factor       (gdouble          dist,
						  gdouble          offset,
						  gdouble          x,
						  gdouble          y);
static gdouble gradient_calc_radial_factor   	 (gdouble          dist,
						  gdouble          offset,
						  gdouble          x,
						  gdouble          y);
static gdouble gradient_calc_linear_factor   	 (gdouble          dist,
						  gdouble         *vec,
						  gdouble          offset,
						  gdouble          x,
						  gdouble          y);
static gdouble gradient_calc_bilinear_factor 	 (gdouble          dist,
						  gdouble         *vec,
						  gdouble          offset,
						  gdouble          x,
						  gdouble          y);
static gdouble gradient_calc_spiral_factor       (gdouble          dist,
						  gdouble         *axis,
						  gdouble          offset,
						  gdouble          x,
						  gdouble          y,
						  gint             cwise);
/*
static gdouble gradient_calc_shapeburst_angular_factor   (gdouble x,
							  gdouble y);
static gdouble gradient_calc_shapeburst_spherical_factor (gdouble x,
							  gdouble y);
static gdouble gradient_calc_shapeburst_dimpled_factor   (gdouble x,
							  gdouble y);
*/
static gdouble gradient_repeat_none              (gdouble       val);
static gdouble gradient_repeat_sawtooth          (gdouble       val);
static gdouble gradient_repeat_triangular        (gdouble       val);
/*
static void    gradient_precalc_shapeburst       (GimpImage    *gimage,
						  GimpDrawable *drawable,
						  PixelRegion  *PR,
						  gdouble       dist);
*/
static void    gradient_render_pixel             (gdouble       x,
						  gdouble       y,
						  GimpRGB      *color,
						  gpointer      render_data);
static void    gradient_put_pixel                (gint          x,
						  gint          y,
						  GimpRGB      *color,
						  gpointer      put_pixel_data);

/*  variables for the shapeburst algs  */
/*
static PixelRegion distR =
{
  NULL,  // data
  NULL,  // tiles
  0,     // rowstride
  0, 0,  // w, h
  0, 0,  // x, y
  4,     // bytes
  0      // process count
};
*/

static gdouble
gradient_calc_conical_sym_factor (gdouble  dist,
				  gdouble *axis,
				  gdouble  offset,
				  gdouble  x,
				  gdouble  y)
{
  gdouble vec[2];
  gdouble r;
  gdouble rat;

  if (dist == 0.0)
    {
      rat = 0.0;
    }
  else if ((x != 0) || (y != 0))
    {
      /* Calculate offset from the start in pixels */

      r = sqrt (x * x + y * y);

      vec[0] = x / r;
      vec[1] = y / r;

      rat = axis[0] * vec[0] + axis[1] * vec[1]; /* Dot product */

      if (rat > 1.0)
	rat = 1.0;
      else if (rat < -1.0)
	rat = -1.0;

      /* This cool idea is courtesy Josh MacDonald,
       * Ali Rahimi --- two more XCF losers.  */

      rat = acos (rat) / G_PI;
      rat = pow (rat, (offset / 10.0) + 1.0);

      rat = CLAMP (rat, 0.0, 1.0);
    }
  else
    {
      rat = 0.5;
    }

  return rat;
}

static gdouble
gradient_calc_conical_asym_factor (gdouble  dist,
				   gdouble *axis,
				   gdouble  offset,
				   gdouble  x,
				   gdouble  y)
{
  gdouble ang0, ang1;
  gdouble ang;
  gdouble rat;

  if (dist == 0.0)
    {
      rat = 0.0;
    }
  else
    {
      if ((x != 0) || (y != 0))
	{
	  ang0 = atan2 (axis[0], axis[1]) + G_PI;
	  ang1 = atan2 (x, y) + G_PI;

	  ang = ang1 - ang0;

	  if (ang < 0.0)
	    ang += (2.0 * G_PI);

	  rat = ang / (2.0 * G_PI);
	  rat = pow (rat, (offset / 10.0) + 1.0);

	  rat = CLAMP (rat, 0.0, 1.0);
	}
      else
	{
	  rat = 0.5; /* We are on middle point */
	}
    }

  return rat;
}

static gdouble
gradient_calc_square_factor (gdouble dist,
			     gdouble offset,
			     gdouble x,
			     gdouble y)
{
  gdouble r;
  gdouble rat;

  if (dist == 0.0)
    {
      rat = 0.0;
    }
  else
    {
      /* Calculate offset from start as a value in [0, 1] */

      offset = offset / 100.0;

      r   = MAX (ABS (x), ABS (y));
      rat = r / dist;

      if (rat < offset)
	rat = 0.0;
      else if (offset == 1.0)
	rat = (rat >= 1.0) ? 1.0 : 0.0;
      else
	rat = (rat - offset) / (1.0 - offset);
    }

  return rat;
}

static gdouble
gradient_calc_radial_factor (gdouble dist,
			     gdouble offset,
			     gdouble x,
			     gdouble y)
{
  gdouble r;
  gdouble rat;

  if (dist == 0.0)
    {
      rat = 0.0;
    }
  else
    {
      /* Calculate radial offset from start as a value in [0, 1] */

      offset = offset / 100.0;

      r   = sqrt (SQR (x) + SQR (y));
      rat = r / dist;

      if (rat < offset)
	rat = 0.0;
      else if (offset == 1.0)
	rat = (rat >= 1.0) ? 1.0 : 0.0;
      else
	rat = (rat - offset) / (1.0 - offset);
    }

  return rat;
}

static gdouble
gradient_calc_linear_factor (gdouble  dist,
			     gdouble *vec,
			     gdouble  offset,
			     gdouble  x,
			     gdouble  y)
{
  gdouble r;
  gdouble rat;

  if (dist == 0.0)
    {
      rat = 0.0;
    }
  else
    {
      offset = offset / 100.0;

      r   = vec[0] * x + vec[1] * y;
      rat = r / dist;

      if (rat >= 0.0 && rat < offset)
	rat = 0.0;
      else if (offset == 1.0)
	rat = (rat >= 1.0) ? 1.0 : 0.0;
      else if (rat < 0.0)
	rat = rat / (1.0 - offset);
      else
	rat = (rat - offset) / (1.0 - offset);
    }

  return rat;
}

static gdouble
gradient_calc_bilinear_factor (gdouble  dist,
			       gdouble *vec,
			       gdouble  offset,
			       gdouble  x,
			       gdouble  y)
{
  gdouble r;
  gdouble rat;

  if (dist == 0.0)
    {
      rat = 0.0;
    }
  else
    {
      /* Calculate linear offset from the start line outward */

      offset = offset / 100.0;

      r   = vec[0] * x + vec[1] * y;
      rat = r / dist;

      if (fabs (rat) < offset)
	rat = 0.0;
      else if (offset == 1.0)
	rat = (rat == 1.0) ? 1.0 : 0.0;
      else
	rat = (fabs (rat) - offset) / (1.0 - offset);
    }

  return rat;
}

static gdouble
gradient_calc_spiral_factor (gdouble  dist,
			     gdouble *axis,
			     gdouble  offset,
			     gdouble  x,
			     gdouble  y,
			     gint     cwise)
{
  gdouble ang0, ang1;
  gdouble ang, r;
  gdouble rat;

  if (dist == 0.0)
    {
      rat = 0.0;
    }
  else
    {
      if (x != 0.0 || y != 0.0)
	{
	  ang0 = atan2 (axis[0], axis[1]) + G_PI;
	  ang1 = atan2 (x, y) + G_PI;
	  if(!cwise)
	    ang = ang0 - ang1;
	  else
	    ang = ang1 - ang0;

	  if (ang < 0.0)
	    ang += (2.0 * G_PI);

	  r = sqrt (x * x + y * y) / dist;
	  rat = ang / (2.0 * G_PI) + r + offset;
	  rat = fmod (rat, 1.0);
	}
      else
	rat = 0.5 ; /* We are on the middle point */
    }

  return rat;
}
/*
static gdouble
gradient_calc_shapeburst_angular_factor (gdouble x,
					 gdouble y)
{
  gint    ix, iy;
  Tile   *tile;
  gfloat  value;

  ix = (gint) CLAMP (x, 0.0, distR.w);
  iy = (gint) CLAMP (y, 0.0, distR.h);
  tile = tile_manager_get_tile (distR.tiles, ix, iy, TRUE, FALSE);
  value = 1.0 - *((float *) tile_data_pointer (tile, ix % TILE_WIDTH, iy % TILE_HEIGHT));
  tile_release (tile, FALSE);

  return value;
}


static gdouble
gradient_calc_shapeburst_spherical_factor (gdouble x,
					   gdouble y)
{
  gint    ix, iy;
  Tile   *tile;
  gfloat  value;

  ix = (gint) CLAMP (x, 0.0, distR.w);
  iy = (gint) CLAMP (y, 0.0, distR.h);
  tile = tile_manager_get_tile (distR.tiles, ix, iy, TRUE, FALSE);
  value = *((gfloat *) tile_data_pointer (tile, ix % TILE_WIDTH, iy % TILE_HEIGHT));
  value = 1.0 - sin (0.5 * G_PI * value);
  tile_release (tile, FALSE);

  return value;
}


static gdouble
gradient_calc_shapeburst_dimpled_factor (gdouble x,
					 gdouble y)
{
  gint    ix, iy;
  Tile   *tile;
  gfloat  value;

  ix = (gint) CLAMP (x, 0.0, distR.w);
  iy = (gint) CLAMP (y, 0.0, distR.h);
  tile = tile_manager_get_tile (distR.tiles, ix, iy, TRUE, FALSE);
  value = *((float *) tile_data_pointer (tile, ix % TILE_WIDTH, iy % TILE_HEIGHT));
  value = cos (0.5 * G_PI * value);
  tile_release (tile, FALSE);

  return value;
}
*/
static gdouble
gradient_repeat_none (gdouble val)
{
  return CLAMP (val, 0.0, 1.0);
}

static gdouble
gradient_repeat_sawtooth (gdouble val)
{
  return val - floor (val);
}

static gdouble
gradient_repeat_triangular (gdouble val)
{
  guint ival;

  if (val < 0.0)
    val = -val;

  ival = (guint) val;
  val = val - floor (val);

  if (ival & 1)
    return 1.0 - val;
  else
    return val;
}

/*****/
/*
static void
gradient_precalc_shapeburst (GimpImage    *gimage,
			     GimpDrawable *drawable,
			     PixelRegion  *PR,
			     gdouble       dist)
{
  GimpChannel *mask;
  PixelRegion  tempR;
  gfloat       max_iteration;
  gfloat      *distp;
  gint         size;
  gpointer     pr;
  guchar       white[1] = { OPAQUE_OPACITY };

  //  allocate the distance map
  distR.tiles = tile_manager_new (PR->w, PR->h, sizeof (gfloat));

  //  allocate the selection mask copy
  tempR.tiles = tile_manager_new (PR->w, PR->h, 1);
  pixel_region_init (&tempR, tempR.tiles, 0, 0, PR->w, PR->h, TRUE);

  mask = gimp_image_get_mask (gimage);

  //  If the gimage mask is not empty, use it as the shape burst source
  if (! gimp_channel_is_empty (mask))
    {
      PixelRegion maskR;
      gint        x1, y1, x2, y2;
      gint        offx, offy;

      gimp_drawable_mask_bounds (drawable, &x1, &y1, &x2, &y2);
      gimp_item_offsets (GIMP_ITEM (drawable), &offx, &offy);

      pixel_region_init (&maskR, gimp_drawable_data (GIMP_DRAWABLE (mask)),
			 x1 + offx, y1 + offy, (x2 - x1), (y2 - y1), FALSE);

      //  copy the mask to the temp mask
      copy_region (&maskR, &tempR);
    }
  //  otherwise...
  else
    {
      //  If the intended drawable has an alpha channel, use that
      if (gimp_drawable_has_alpha (drawable))
	{
	  PixelRegion drawableR;

	  pixel_region_init (&drawableR, gimp_drawable_data (drawable),
			     PR->x, PR->y, PR->w, PR->h, FALSE);

	  extract_alpha_region (&drawableR, NULL, &tempR);
	}
      else
	{
	  //  Otherwise, just fill the shapeburst to white
	  color_region (&tempR, white);
	}
    }

  pixel_region_init (&tempR, tempR.tiles, 0, 0, PR->w, PR->h, TRUE);
  pixel_region_init (&distR, distR.tiles, 0, 0, PR->w, PR->h, TRUE);
  max_iteration = shapeburst_region (&tempR, &distR);

  //  normalize the shapeburst with the max iteration
  if (max_iteration > 0)
    {
      pixel_region_init (&distR, distR.tiles, 0, 0, PR->w, PR->h, TRUE);

      for (pr = pixel_regions_register (1, &distR);
	   pr != NULL;
	   pr = pixel_regions_process (pr))
	{
	  distp = (gfloat *) distR.data;
	  size  = distR.w * distR.h;

	  while (size--)
	    *distp++ /= max_iteration;
	}

      pixel_region_init (&distR, distR.tiles, 0, 0, PR->w, PR->h, FALSE);
    }

  tile_manager_unref (tempR.tiles);
}
*/

static void
gradient_render_pixel (double    x,
		       double    y,
		       GimpRGB  *color,
		       gpointer  render_data)
{
  RenderBlendData *rbd;
  gdouble          factor;

  rbd = render_data;

  /* Calculate blending factor */

  switch (rbd->gradient_type)
    {
    case GIMP_GRADIENT_LINEAR:
      factor = gradient_calc_linear_factor (rbd->dist, rbd->vec, rbd->offset,
					    x - rbd->sx, y - rbd->sy);
      break;

    case GIMP_GRADIENT_BILINEAR:
      factor = gradient_calc_bilinear_factor (rbd->dist, rbd->vec, rbd->offset,
					      x - rbd->sx, y - rbd->sy);
      break;

    case GIMP_GRADIENT_RADIAL:
      factor = gradient_calc_radial_factor (rbd->dist, rbd->offset,
					    x - rbd->sx, y - rbd->sy);
      break;

    case GIMP_GRADIENT_SQUARE:
      factor = gradient_calc_square_factor (rbd->dist, rbd->offset,
					    x - rbd->sx, y - rbd->sy);
      break;

    case GIMP_GRADIENT_CONICAL_SYMMETRIC:
      factor = gradient_calc_conical_sym_factor (rbd->dist, rbd->vec, rbd->offset,
						 x - rbd->sx, y - rbd->sy);
      break;

    case GIMP_GRADIENT_CONICAL_ASYMMETRIC:
      factor = gradient_calc_conical_asym_factor (rbd->dist, rbd->vec, rbd->offset,
						  x - rbd->sx, y - rbd->sy);
      break;
/*
    case GIMP_GRADIENT_SHAPEBURST_ANGULAR:
      factor = gradient_calc_shapeburst_angular_factor (x, y);
      break;

    case GIMP_GRADIENT_SHAPEBURST_SPHERICAL:
      factor = gradient_calc_shapeburst_spherical_factor (x, y);
      break;

    case GIMP_GRADIENT_SHAPEBURST_DIMPLED:
      factor = gradient_calc_shapeburst_dimpled_factor (x, y);
      break;
*/
    case GIMP_GRADIENT_SPIRAL_CLOCKWISE:
      factor = gradient_calc_spiral_factor (rbd->dist, rbd->vec, rbd->offset,
					    x - rbd->sx, y - rbd->sy,TRUE);
      break;

    case GIMP_GRADIENT_SPIRAL_ANTICLOCKWISE:
      factor = gradient_calc_spiral_factor (rbd->dist, rbd->vec, rbd->offset,
					    x - rbd->sx, y - rbd->sy,FALSE);
      break;

    default:
      g_assert_not_reached ();
      return;
    }

  /* Adjust for repeat */

  factor = (*rbd->repeat_func) (factor);

  /* Blend the colors */

      if (rbd->reverse)
        factor = 1.0 - factor;

      color->r = rbd->fg.r + (rbd->bg.r - rbd->fg.r) * factor;
      color->g = rbd->fg.g + (rbd->bg.g - rbd->fg.g) * factor;
      color->b = rbd->fg.b + (rbd->bg.b - rbd->fg.b) * factor;
      color->a = rbd->fg.a + (rbd->bg.a - rbd->fg.a) * factor;
/*
      if (rbd->blend_mode == GIMP_FG_BG_HSV_MODE)
        {
          GimpHSV hsv;

          hsv = *((GimpHSV *) color);

          gimp_hsv_to_rgb (&hsv, color);
        }
*/
}

static void
gradient_put_pixel (int      x,
		    int      y,
		    GimpRGB *color,
		    void    *put_pixel_data)
{
  PutPixelData  *ppd;
  guchar        *data;
  gint			temp;

  ppd = put_pixel_data;
  data = ppd->data;
  
  // Paint

  temp = ((ppd->rect.origin.y + y) * ppd->width + (ppd->rect.origin.x + x)) * ppd->spp;
  if (ppd->spp == 4)
    {
      data[temp] = color->r * 255.0;
      data[temp + 1] = color->g * 255.0;
      data[temp + 2] = color->b * 255.0;
      data[temp + 3] = color->a * 255.0;
    }
  else if (ppd->spp == 2)
    {
      // Convert to grayscale 
      gdouble gray = INTENSITY (color->r, color->g, color->b);
      data[temp] = gray * 255.0;
      data[temp + 1] = color->a * 255.0;
    }
}

void GCFillGradient(unsigned char *dest, int destWidth, int destHeight, IntRect rect, int spp, GimpGradientInfo info, ProgressFunction progress_callback)
{
	RenderBlendData rbd;
	PutPixelData ppd;
	GimpRGB color;
	int x, y;
	
	rbd.gradient = NULL;
	rbd.reverse = 0;

	rbd.fg.r = (double)info.start_color[0] / 255.0;
	rbd.fg.g = (double)info.start_color[1] / 255.0;
	rbd.fg.b = (double)info.start_color[2] / 255.0;
	rbd.fg.a = (double)info.start_color[3] / 255.0;

	rbd.bg.r = (double)info.end_color[0] / 255.0;
	rbd.bg.g = (double)info.end_color[1] / 255.0;
	rbd.bg.b = (double)info.end_color[2] / 255.0;
	rbd.bg.a = (double)info.end_color[3] / 255.0;
	
	switch (info.repeat) {
		case GIMP_REPEAT_NONE:
			rbd.repeat_func = gradient_repeat_none;
		break;
		case GIMP_REPEAT_SAWTOOTH:
			rbd.repeat_func = gradient_repeat_sawtooth;
		break;
		case GIMP_REPEAT_TRIANGULAR:
			rbd.repeat_func = gradient_repeat_triangular;
		break;
	}
	
	switch (info.gradient_type) {
		case GIMP_GRADIENT_RADIAL:
			rbd.dist = sqrt(SQR(info.end.x - info.start.x) + SQR(info.end.y - info.start.y));
		break;
		case GIMP_GRADIENT_SQUARE:
			rbd.dist = MAX (fabs (info.end.x - info.start.x), fabs (info.end.y - info.start.y));
		break;
		case GIMP_GRADIENT_LINEAR:
		case GIMP_GRADIENT_BILINEAR:
			rbd.dist = sqrt (SQR (info.end.x - info.start.x) + SQR (info.end.y - info.start.y));
			if (rbd.dist > 0.0) {
				rbd.vec[0] = (info.end.x - info.start.x) / rbd.dist;
				rbd.vec[1] = (info.end.y - info.start.y) / rbd.dist;
			}
		break;
		case GIMP_GRADIENT_CONICAL_SYMMETRIC:
		case GIMP_GRADIENT_CONICAL_ASYMMETRIC:
		case GIMP_GRADIENT_SPIRAL_CLOCKWISE:
		case GIMP_GRADIENT_SPIRAL_ANTICLOCKWISE:
			rbd.repeat_func = gradient_repeat_none;
			rbd.dist = sqrt (SQR (info.end.x - info.start.x) + SQR (info.end.y - info.start.y));
			if (rbd.dist > 0.0) {
				rbd.vec[0] = (info.end.x - info.start.x) / rbd.dist;
				rbd.vec[1] = (info.end.y - info.start.y) / rbd.dist;
			}
		break;
		/*
		case GIMP_GRADIENT_SHAPEBURST_ANGULAR:
		case GIMP_GRADIENT_SHAPEBURST_SPHERICAL:
		case GIMP_GRADIENT_SHAPEBURST_DIMPLED:
			rbd.dist = sqrt (SQR (ex - sx) + SQR (ey - sy));
			gradient_precalc_shapeburst (gimage, drawable, PR, rbd.dist);
		break;
		*/
	}
	
	rbd.offset = 0;
	rbd.sx = info.start.x - rect.origin.x;
	rbd.sy = info.start.y - rect.origin.y;
	rbd.gradient_type = info.gradient_type;
	
	if (info.supersample) {
		ppd.data = dest;
		ppd.width = destWidth;
		ppd.height = destHeight;
		ppd.rect = rect;
		ppd.spp = spp;
		gimp_adaptive_supersample_area (0, 0, (rect.size.width - 1), (rect.size.height - 1),
					  info.max_depth, info.threshold,
					  gradient_render_pixel, &rbd,
					  gradient_put_pixel, &ppd,
					  progress_callback);
    }
	else {
		int max_progress = rect.size.width * rect.size.height;
		int progress = 0;

		for (y = rect.origin.y; y < rect.origin.y + rect.size.height; y++) {
			for (x = rect.origin.x; x < rect.origin.x + rect.size.width; x++) {
				gradient_render_pixel (x - rect.origin.x, y - rect.origin.y, &color, &rbd);
				if (spp == 4) {
					dest[(y * destWidth + x) * spp] = color.r * 255.0;
					dest[(y * destWidth + x) * spp + 1] = color.g * 255.0;
					dest[(y * destWidth + x) * spp + 2] = color.b * 255.0;
					dest[(y * destWidth + x) * spp + 3] = color.a * 255.0;
				}
				else if (spp == 2) {
					double gray = INTENSITY (color.r, color.g, color.b);
					dest[(y * destWidth + x) * spp] = gray * 255.0;
					dest[(y * destWidth + x) * spp + 3] = color.a * 255.0;
				}
			}
			progress += rect.size.width;
			if (progress_callback)
				(* progress_callback) (max_progress, progress);
		}
	}
}
