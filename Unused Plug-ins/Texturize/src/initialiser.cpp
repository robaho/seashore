#include "GIMPBridge.h"
#include "texturize.h"

guchar **
init_guchar_tab_2d (gint x, gint y)
{
  guchar ** tab;
  gint i, j;
  tab=(guchar**)malloc(x * sizeof(guchar*));

  for (i=0; i<x; i++) {
    tab[i] = (guchar*) malloc(y * sizeof(guchar));
  }

  for (i=0; i<x; i++) {
    for (j=0; j<y; j++) tab[i][j] = 0;
  }

  return tab;
}
