#include "GIMPCore.h"
#include "GIMPBridge.h"
#include "Channel.h"

void
gimp_channel_add_segment (GimpChannel *mask,
			  gint         x,
			  gint         y,
			  gint         width,
			  gint         value)
{
  guchar      *data;
  gint         val;
  gint         x2;

  /*  check horizontal extents...  */
  x2 = x + width;
  x2 = CLAMP (x2, 0, GIMP_ITEM (mask)->width);
  x  = CLAMP (x,  0, GIMP_ITEM (mask)->width);
  width = x2 - x;
  if (!width)
    return;

  if (y < 0 || y > GIMP_ITEM (mask)->height)
    return;
/*
  pixel_region_init (&maskPR, GIMP_DRAWABLE (mask)->tiles,
		     x, y, width, 1, TRUE);

  for (pr = pixel_regions_register (1, &maskPR);
       pr != NULL;
       pr = pixel_regions_process (pr))
*/
    {
      data = (mask)->data;
      data += y * (mask)->width;
	  data += x;
	  while (width--)
	{
	  val = *data + value;
	  if (val > 255)
	    val = 255;
	  *data++ = val;
	}
    }
}

void
gimp_channel_combine_ellipse (GimpChannel    *mask,
			      gint            x,
			      gint            y,
			      gint            w,
			      gint            h,
			      gboolean        antialias)
{
  gint   i, j;
  gint   x0, x1, x2;
  gint   val, last;
  gfloat a_sqr, b_sqr, aob_sqr;
  gfloat w_sqr, h_sqr;
  gfloat y_sqr;
  gfloat t0, t1;
  gfloat r;
  gfloat cx, cy;
  gfloat rad;
  gfloat dist;

  if (!w || !h)
    return;

  a_sqr = (w * w / 4.0);
  b_sqr = (h * h / 4.0);
  aob_sqr = a_sqr / b_sqr;

  cx = x + w / 2.0;
  cy = y + h / 2.0;

  for (i = y; i < (y + h); i++)
    {
      if (i >= 0 && i < GIMP_ITEM (mask)->height)
	{
	  /*  Non-antialiased code  */
	  if (!antialias)
	    {
	      y_sqr = (i + 0.5 - cy) * (i + 0.5 - cy);
	      rad = sqrt (a_sqr - a_sqr * y_sqr / (double) b_sqr);
	      x1 = ROUND (cx - rad);
	      x2 = ROUND (cx + rad);

		  gimp_channel_add_segment (mask, x1, i, (x2 - x1), 255);
	    }
	  /*  antialiasing  */
	  else
	    {
	      x0 = x;
	      last = 0;
	      h_sqr = (i + 0.5 - cy) * (i + 0.5 - cy);
	      for (j = x; j < (x + w); j++)
		{
		  w_sqr = (j + 0.5 - cx) * (j + 0.5 - cx);

		  if (h_sqr != 0)
		    {
		      t0 = w_sqr / h_sqr;
		      t1 = a_sqr / (t0 + aob_sqr);
		      r = sqrt (t1 + t0 * t1);
		      rad = sqrt (w_sqr + h_sqr);
		      dist = rad - r;
		    }
		  else
		    dist = -1.0;

		  if (dist < -0.5)
		    val = 255;
		  else if (dist < 0.5)
		    val = (int) (255 * (1 - (dist + 0.5)));
		  else
		    val = 0;

		  if (last != val && last)
		    {
			  gimp_channel_add_segment (mask, x0, i, j - x0, last);
		    }

		  if (last != val)
		    {
		      x0 = j;
		      last = val;
		      /* because we are symetric accross the y axis we can
			 skip ahead a bit if we are inside the ellipse*/
		      if (val == 255 && j < cx)
			j = cx + (cx - j) - 1;
		    }
		}

	      if (last)
		{
                      gimp_channel_add_segment (mask, x0, i, j - x0, last);
		}
	    }

	}
    }

}

void GCDrawEllipse(unsigned char *dest, int destWidth, int destHeight, IntRect rect, unsigned int antialiased)
{
	GimpChannel destChannel;
	
	if (!dest)
		return;
	destChannel = channel_make(dest, destWidth, destHeight);
	gimp_channel_combine_ellipse(&destChannel, rect.origin.x, rect.origin.y, rect.size.width, rect.size.height, antialiased);
}

