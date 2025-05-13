
open_error <- function (resource, name, assert, e) {
  
  action <- switch(
    EXPR = assert, 
    'create' = 'create', 
    'exists' = 'open', 
    'NULL'   = 'open or create' )
  
  msg <- paste('Could not', action, 'the', resource, 'named', shQuote(name))
  stop(msg, '.\n', sub('^Error\\: ', '', e), call. = FALSE)
}
