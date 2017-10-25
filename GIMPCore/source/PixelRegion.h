typedef struct
{
  guchar      *data;           /*  pointer to region data        */
//  gint         offx;           /*  tile offsets                  */
//  gint         offy;           /*  tile offsets                  */
//  gint         rowstride;      /*  bytes per pixel row           */
//  gint         x;              /*  origin                        */
//  gint         y;              /*  origin                        */
  gint         w;              /*  width of region               */
  gint         h;              /*  height of region              */
  gint         bytes;          /*  bytes per pixel               */
//  gboolean     dirty;          /*  will this region be dirtied?  */
} PixelRegion;


static inline PixelRegion pixel_region_make(unsigned char *data, int width, int height, int spp)
{
	PixelRegion pr;
	
	pr.data = data;
	pr.w = width;
	pr.h = height;
	pr.bytes = spp;
	
	return pr;
}

static inline void pixel_region_info(PixelRegion pr, int *width, int *height, int *spp)
{
	*width = pr.w;
	*height = pr.h;
	*spp = pr.bytes;
}

static inline gboolean pixel_region_has_alpha()
{
	return TRUE;
}

static inline void pixel_region_set_row(PixelRegion *pr, gint x, gint y, gint w, guchar *data)
{
	memcpy(pr->data + (y * pr->w  + x) * pr->bytes, data, w * pr->bytes); 
}

static inline void pixel_region_get_row(PixelRegion *pr, gint x, gint y, gint w, guchar *data, gint subsample)
{
	int i, j;
	
	if (subsample == 1) {
		memcpy(data, pr->data + (y * pr->w  + x) * pr->bytes, w * pr->bytes);
	}
	else {
		for (i = 0; i < w; i++) {
			for (j = 0; j < pr->bytes; j++) {
				data[i * pr->bytes + j] = pr->data[(y * pr->w + x + i * subsample) * pr->bytes + j];
			}
		}
	}
}

