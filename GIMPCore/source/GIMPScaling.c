#include "GIMPCore.h"
#include "GIMPBridge.h"
#include "PixelRegion.h"

void
scale_region (PixelRegion           *srcPR,
	      PixelRegion           *destPR,
              GimpInterpolationType  interpolation_type);

/* Note: cubic function no longer clips result */
static inline gdouble
cubic (gdouble dx,
       gint    jm1,
       gint    j,
       gint    jp1,
       gint    jp2)
{
  /* Catmull-Rom - not bad */
  return (gdouble) ((( ( - jm1 + 3 * j - 3 * jp1 + jp2 ) * dx +
		       ( 2 * jm1 - 5 * j + 4 * jp1 - jp2 ) ) * dx +
		     ( - jm1 + jp1 ) ) * dx + (j + j) ) / 2.0;
}

static void
rotate_pointers (gpointer *p, 
		 guint32   n)
{
  guint32  i;
  gpointer tmp;

  tmp = p[0];
  for (i = 0; i < n-1; i++)
    {
      p[i] = p[i+1];
    }
  p[i] = tmp;
}

static void
get_premultiplied_double_row (PixelRegion *srcPR,
			      gint         x,
			      gint         y,
			      gint         w,
			      gdouble     *row,
			      guchar      *tmp_src,
			      gint         n)
{
  gint b;
  gint bytes = srcPR->bytes;

  pixel_region_get_row (srcPR, x, y, w, tmp_src, n);

  if (pixel_region_has_alpha ())
    {
      /* premultiply the alpha into the double array */
      gdouble *irow  = row;
      gint     alpha = bytes - 1;
      gdouble  mod_alpha;

      for (x = 0; x < w; x++)
	{
	  mod_alpha = tmp_src[alpha] / 255.0;
	  for (b = 0; b < alpha; b++)
	    irow[b] = mod_alpha * tmp_src[b];
	  irow[b] = tmp_src[alpha];
	  irow += bytes;
	  tmp_src += bytes;
	}
    }
  else /* no alpha */
    {
      for (x = 0; x <  w*bytes; x++)
	row[x] = tmp_src[x];
    }

  /* set the off edge pixels to their nearest neighbor */
  for (b = 0; b < 2 * bytes; b++)
    row[-2*bytes + b] = row[(b%bytes)];
  for (b = 0; b < bytes * 2; b++)
    row[w*bytes + b] = row[(w - 1) * bytes + (b%bytes)];
}

// uses premultiplied doubles (alpha * pixel)
static void
expand_line (gdouble             *dest,
	     gdouble                 *src,
	     gint                  bytes,
	     gint                  old_width,
	     gint                   width,
	     GimpInterpolationType  interp)
{
    gdouble  ratio;
    gint     x,b;
    gint      src_col;
    gdouble  frac;
    gdouble *s;
    
    ratio = old_width / (gdouble) width;
    
    /* this could be opimized much more by precalculating the coeficients for each x */
    switch(interp)
    {
        case GIMP_INTERPOLATION_CUBIC:
            for (x = 0; x < width; x++)
            {
                src_col = ((int)((x) * ratio  + 2.0 - 0.5)) - 2;
                /* +2, -2 is there because (int) rounds towards 0 and we need to round down */
                frac = ((x) * ratio - 0.5) - src_col;
                s = &src[src_col * bytes];
                for (b = 0; b < bytes; b++) {
                    double v = cubic (frac, s[b - bytes], s[b], s[b+bytes], s[b+bytes*2]);
                    dest[b]=v;
                }
                dest += bytes;
            }
            break;
            
        case GIMP_INTERPOLATION_LINEAR:
            for (x = 0; x < width; x++)
            {
                src_col = ((int)((x) * ratio + 2.0 - 0.5)) - 2;
                /* +2, -2 is there because (int) rounds towards 0 and we need to round down */
                frac =          ((x) * ratio - 0.5) - src_col;
                s = &src[src_col * bytes];
                for (b = 0; b < bytes; b++)
                    dest[b] = ((s[b + bytes] - s[b]) * frac + s[b]);
                dest += bytes;
            }
            break;
            
        case GIMP_INTERPOLATION_NONE:
            g_assert_not_reached ();
            break;
    }
}

static void
shrink_line (gdouble               *dest,
	     gdouble               *src,
	     gint                  bytes,
	     gint                   old_width,
	     gint                   width,
	     GimpInterpolationType  interp)
{
  gint x, b;
  gdouble *source, *destp;
  register gdouble accum;
  register guint max;
  register gdouble mant, tmp;
  register const gdouble step = old_width / (gdouble) width;
  register const gdouble inv_step = 1.0 / step;
  gdouble position;

#if 0
  g_printerr ("shrink_line bytes=%d old_width=%d width=%d interp=%d "
              "step=%f inv_step=%f\n",
              bytes, old_width, width, interp, step, inv_step);
#endif

  for (b = 0; b < bytes; b++)
    {
    
      source = &src[b];
      destp = &dest[b];
      position = -1;
      
      mant = *source;
      
      for (x = 0; x < width; x++)
        {
          source+= bytes;
          accum = 0;
          max = ((int)(position+step)) - ((int)(position));
          max--;

          while (max)
            {
              accum += *source;
              source += bytes;
              max--;
            }

          tmp = accum + mant;
          mant = ((position+step) - (int)(position + step));
          mant *= *source;
          tmp += mant;
          tmp *= inv_step;
          mant = *source - mant;
          *(destp) = tmp;
          destp += bytes;
          position += step;
      
        }
    }
}

static void
get_scaled_row (void                 **src,
		gint                   y,
		gint                   new_width,
		PixelRegion           *srcPR,
		gdouble               *row,
		guchar                *src_tmp,
                GimpInterpolationType  interpolation_type)
{
/* get the necesary lines from the source image, scale them,
   and put them into src[] */
  rotate_pointers(src, 4);
  if (y < 0)
    y = 0;
  if (y < srcPR->h)
    {
      get_premultiplied_double_row (srcPR, 0, y, srcPR->w,
                                    row, src_tmp, 1);
      if (new_width > srcPR->w)
        expand_line(src[3], row, srcPR->bytes, 
                    srcPR->w, new_width, interpolation_type);
      else if (srcPR->w > new_width)
        shrink_line(src[3], row, srcPR->bytes, 
                    srcPR->w, new_width, interpolation_type);
      else /* no scailing needed */
        memcpy(src[3], row, sizeof (double) * new_width * srcPR->bytes);
    }
  else
    memcpy(src[3], src[2], sizeof (double) * new_width * srcPR->bytes);
}

static void
scale_region_no_resample (PixelRegion *srcPR,
			  PixelRegion *destPR)
{
  gint   *x_src_offsets;
  gint   *y_src_offsets;
  guchar *src;
  guchar *dest;
  gint    width, height, orig_width, orig_height;
  gint    last_src_y;
  gint    row_bytes;
  gint    x, y, b;
  gint   bytes;

  orig_width = srcPR->w;
  orig_height = srcPR->h;

  width = destPR->w;
  height = destPR->h;

  bytes = srcPR->bytes;

  /*  the data pointers...  */
  x_src_offsets = (int *) g_malloc (width * bytes * sizeof(int));
  y_src_offsets = (int *) g_malloc (height * sizeof(int));
  src  = (guchar *) g_malloc (orig_width * bytes);
  dest = (guchar *) g_malloc (width * bytes);
  
  /*  pre-calc the scale tables  */
  for (b = 0; b < bytes; b++)
    {
      for (x = 0; x < width; x++)
	{
	  x_src_offsets [b + x * bytes] = b + bytes * ((x * orig_width + orig_width / 2) / width);
	}
    }
  for (y = 0; y < height; y++)
    {
      y_src_offsets [y] = (y * orig_height + orig_height / 2) / height;
    }
  
  /*  do the scaling  */
  row_bytes = width * bytes;
  last_src_y = -1;
  for (y = 0; y < height; y++)
    {
      /* if the source of this line was the same as the source
       *  of the last line, there's no point in re-rescaling.
       */
      if (y_src_offsets[y] != last_src_y)
	{
	  pixel_region_get_row (srcPR, 0, y_src_offsets[y], orig_width, src, 1);
	  for (x = 0; x < row_bytes ; x++)
	    {
	      dest[x] = src[x_src_offsets[x]];
	    }
	  last_src_y = y_src_offsets[y];
	}

      pixel_region_set_row (destPR, 0, y, width, dest);
    }
  
  g_free (x_src_offsets);
  g_free (y_src_offsets);
  g_free (src);
  g_free (dest);
}


void
scale_region (PixelRegion           *srcPR,
	      PixelRegion           *destPR,
              GimpInterpolationType  interpolation_type)
{
  gdouble *src[4];
  guchar  *src_tmp;
  guchar  *dest;
  gdouble  *row, *accum;
  gint     bytes, b;
  gint     width, height;
  gint     orig_width, orig_height;
  gdouble  y_rat;
  gint     i;
  gint     old_y = -4, new_y;
  gint     x, y;

  if (interpolation_type == GIMP_INTERPOLATION_NONE)
    {
      scale_region_no_resample (srcPR, destPR);
      return;
    }

  orig_width = srcPR->w;
  orig_height = srcPR->h;

  width = destPR->w;
  height = destPR->h;
	
  /*
  g_printerr ("scale_region: (%d x %d) -> (%d x %d)\n",
              orig_width, orig_height, width, height);
  */
  
  /*  find the ratios of old y to new y  */
  y_rat = (double) orig_height / (double) height;

  bytes = destPR->bytes;

  /*  the data pointers...  */
  for (i = 0; i < 4; i++)
    src[i]    = g_new (double, (width) * bytes);
  dest   = g_new (guchar, width * bytes);

  src_tmp = g_new (guchar, orig_width * bytes);

 /* offset the row pointer by 2*bytes so the range of the array 
    is [-2*bytes] to [(orig_width + 2)*bytes] */
  row = g_new(gdouble, (orig_width + 2*2) * bytes);
  row += bytes*2;

  accum = g_new(gdouble, (width) * bytes);

  /*  Scale the selected region  */
  
  for (y = 0; y < height;  y++)
    {
      if (height < orig_height)
        {
          gint max;
          double frac;
          const double inv_ratio = 1.0 / y_rat;
          if (y == 0) /* load the first row if this it the first time through  */
            get_scaled_row((void **)&src[0], 0, width, srcPR, row,
                           src_tmp,
                           interpolation_type);
          new_y = (int)((y) * y_rat);
          frac = 1.0 - (y*y_rat - new_y);
          for (x  = 0; x < width*bytes; x++)
	accum[x] = src[3][x] * frac;
          
          max = ((int)((y+1) *y_rat)) - (new_y);
          max--;
          
          get_scaled_row((void **)&src[0], ++new_y, width, srcPR, row,
                         src_tmp,
                         interpolation_type);
          
          while (max > 0)
            {
              for (x  = 0; x < width*bytes; x++)
                accum[x] += src[3][x];
              get_scaled_row((void **)&src[0], ++new_y, width, srcPR, row,
                             src_tmp,
                       interpolation_type);
              max--;
            }
          frac = (y + 1)*y_rat - ((int)((y + 1)*y_rat));
          for (x  = 0; x < width*bytes; x++)
            {
              accum[x] += frac * src[3][x];
              accum[x] *= inv_ratio;
            }
        }      
      else if (height > orig_height)
        {
          new_y = floor((y) * y_rat - .5);
          
          while (old_y <= new_y)
            { /* get the necesary lines from the source image, scale them,
                 and put them into src[] */
              get_scaled_row((void **)&src[0], old_y + 2, width, srcPR, row,
                             src_tmp,
                             interpolation_type);
              old_y++;
            }
          switch(interpolation_type)
            {
            case GIMP_INTERPOLATION_CUBIC:
              {
                double p0, p1, p2, p3;
                double dy = ((y) * y_rat - .5) - new_y;
                p0 = cubic(dy, 1, 0, 0, 0);
                p1 = cubic(dy, 0, 1, 0, 0);
                p2 = cubic(dy, 0, 0, 1, 0);
                p3 = cubic(dy, 0, 0, 0, 1);
                for (x = 0; x < width * bytes; x++)
                  accum[x] = p0 * src[0][x] + p1 * src[1][x] +
                    p2 * src[2][x] + p3 * src[3][x];
              } break;
              
            case GIMP_INTERPOLATION_LINEAR:
              {
                double idy = ((y) * y_rat - 0.5) - new_y;
                double dy = 1.0 - idy;
                for (x = 0; x < width * bytes; x++)
                  accum[x] = dy * src[1][x] + idy * src[2][x];
              } break;
              
            case GIMP_INTERPOLATION_NONE:
              g_assert_not_reached ();
              break;
            }
        }
      else /* height == orig_height */
        {
          get_scaled_row ((void **)&src[0], y, width, srcPR, row,
                          src_tmp,
                          interpolation_type);
          memcpy(accum, src[3], sizeof(gdouble) * width * bytes);
        }

      if (pixel_region_has_alpha ())
        { /* unmultiply the alpha */
          double inv_alpha;
          double *p = accum;
          gint alpha = bytes - 1;
          gint result;
          guchar *d = dest;
          for (x = 0; x < width; x++)
            {
              if (p[alpha] > 0.001)
                {
                  inv_alpha = 255.0 / p[alpha];
                  for (b = 0; b < alpha; b++)
                    {
                      result = RINT(inv_alpha * p[b]);
                      if (result < 0)
                        d[b] = 0;
                      else if (result > 255)
                        d[b] = 255;
                      else
                        d[b] = result;
                    }
                  result = RINT(p[alpha]);
                  if (result > 255)
                    d[alpha] = 255;
                  else
                    d[alpha] = result;
                }
              else /* alpha <= 0 */
                for (b = 0; b <= alpha; b++)
                  d[b] = 0;
              d += bytes;
              p += bytes;
            }
        }
      else
        {
          gint w = width * bytes;
          for (x = 0; x < w; x++)
            {
              if (accum[x] < 0.0)
                dest[x] = 0;
              else if (accum[x] > 255.0)
                dest[x] = 255;
              else
                dest[x] = RINT(accum[x]);
            }
        }
      pixel_region_set_row (destPR, 0, y, width, dest);
    }
  
  /*  free up temporary arrays  */
  g_free (accum);
  for (i = 0; i < 4; i++)
    g_free (src[i]);
  g_free (src_tmp);
  g_free (dest);
  row -= 2*bytes;
  g_free (row);
}

void GCScalePixels(unsigned char *dest, int destWidth, int destHeight, unsigned char *src, int srcWidth, int srcHeight, int interpolation, int spp)
{
	PixelRegion srcPR = pixel_region_make(src, srcWidth, srcHeight, spp);
	PixelRegion destPR = pixel_region_make(dest, destWidth, destHeight, spp); 
	
	scale_region(&srcPR, &destPR, interpolation);
}
