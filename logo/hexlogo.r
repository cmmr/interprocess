
library(ggplot2)
library(magick)

ggplot() + 
  geom_polygon(
    mapping = aes(
      x = 1000 * sqrt(3)/2 * c(0, 1, 1, 0, -1, -1), 
      y = 1000 * .5 * c(2, 1, -1, -2, -1, 1) ),
    color     = '#0078a5',
    fill      = 'white',
    linewidth = 6 ) + 
  coord_fixed(ratio = 1) +
  theme_void() +
  theme(rect = element_rect(fill = 'transparent')) +
  annotate(
    geom   = 'text', 
    label  = 'interprocess',
    family = 'Brownland',
    color  = '#181a1b',
    size   = 20,
    x      = 0, 
    y      = 470 ) +
  annotation_raster(
    raster = image_read('logo/cartoon.png'),
    xmin = -775, xmax = 775,
    ymin = -610, ymax = 262 )


ggsave(
  path     = 'logo',
  filename = 'interprocess.png', 
  device   = 'png',
  width    = 2000, 
  height   = 2000, 
  dpi      = 380, 
  units    = 'px',
  bg       = 'transparent' )

image_read('logo/interprocess.png') |>
  image_trim() |>
  image_resize('x200') |>
  image_write('man/figures/logo.png')
