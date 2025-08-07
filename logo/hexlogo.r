
library(ggplot2)
library(ggpattern)
library(magick)
library(magrittr)

ggplot() + 
  geom_polygon_pattern(
    mapping = aes(
      x = 1200 * sqrt(3)/2 * c(0, 1, 1, 0, -1, -1), 
      y = 1200 * .5 * c(2, 1, -1, -2, -1, 1) ),
    pattern          = 'image',
    pattern_type     = 'fit',
    pattern_filename = 'logo/cartoon.png',
    color            = 'black',
    fill             = 'white',
    linewidth        = 4 ) + 
  coord_fixed(ratio = 1) +
  theme_void() +
  theme(rect = element_rect(fill = 'transparent')) +
  annotate(
    geom   = 'text', 
    label  = 'interprocess',
    family = 'Brownland',
    size   = 22,
    x      = 0, 
    y      = 550 )



ggsave(
  path     = 'logo',
  filename = 'interprocess.png', 
  device   = 'png',
  width    = 2000, 
  height   = 2000, 
  dpi      = 380, 
  units    = 'px',
  bg       = 'transparent' )


# pkgdown website sets logo width to 120px
image_read('logo/interprocess.png') %>%
  image_trim() %>%
  image_resize('120x') %>%
  image_write('man/figures/logo.png')


# height = 200px (150pt) for joss paper
image_read('logo/interprocess.png') %>%
  image_trim() %>%
  image_resize('x200') %>%
  image_write('joss/figures/logo.png')
