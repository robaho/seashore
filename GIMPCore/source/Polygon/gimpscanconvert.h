/* The GIMP -- an image manipulation program
 * Copyright (C) 1995-1999 Spencer Kimball and Peter Mattis
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */

#include "GIMPCore.h"
#include "GIMPBridge.h"
#include "art_svp_render_aa.h"

typedef struct _GimpScanConvert GimpScanConvert;

struct _GimpScanConvert
{
  gdouble         ratio_xy;

  gboolean        clip;
  gint            clip_x;
  gint            clip_y;
  gint            clip_w;
  gint            clip_h;

  gboolean        got_first;
  gboolean        need_closing;
  GimpVector2     first;
  GimpVector2     prev;

  gboolean        have_open;
  guint           num_nodes;
  ArtVpath       *vpath;

  ArtSVP         *svp;      /* Sorted vector path
                               (extension no longer possible)          */

  /* stuff necessary for the rendering callback */
  //GimpChannelOps  op;
  guchar         *buf;
  gint            rowstride;
  gint            x0, x1;
  gboolean        antialias;
  gint				spp;
};

GimpScanConvert * gimp_scan_convert_new        (void);

void      gimp_scan_convert_free               (GimpScanConvert *sc);
void      gimp_scan_convert_set_pixel_ratio    (GimpScanConvert *sc,
                                                gdouble          ratio_xy);
void      gimp_scan_convert_set_clip_rectangle (GimpScanConvert *sc,
                                                gint             x,
                                                gint             y,
                                                gint             width,
                                                gint             height);
void      gimp_scan_convert_add_polyline       (GimpScanConvert *sc,
                                                guint            n_points,
                                                GimpVector2     *points,
                                                gboolean         closed);
void      gimp_scan_convert_finish				(GimpScanConvert *sc);
