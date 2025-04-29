
err <- function (x, obj, ...) {
  var <- evalq(substitute(x), envir = parent.frame())
  stop('`', var, '` parameter for ', obj, ' ', ..., call. = FALSE)
}


validate_name <- function (x, obj) {
  
  if (!is.character(x) || !isTRUE(!is.na(x)))
    err(x, obj, 'must be a single string (scalar character)')
  
  if (nchar(x) == 0)
    err(x, obj, 'cannot be an empty string')
  
  if (!inherits(x, 'AsIs')) {
    
    if (nchar(x) > 250)
      err(x, obj, 
          'maximum length is 250 characters\n',
          'Length received: ', char(x), ' characters' )
    
    ch <- strsplit(x, '', fixed = TRUE)[[1]]
    
    if (!all(ch %in% c(letters, LETTERS, 0:9)))
      err(x, obj, 
          'can only contain letters and numbers\n',
          'Argument received: "', x ,'"')
    
    if (!ch[[1]] %in% c(letters, LETTERS))
      err(x, obj, 
          'must start with a letter\n',
          'Argument received: "', x ,'"')
  }
  
  return (x)
}


validate_string <- function (x, obj) {
  
  if (is.character(x) && isTRUE(!is.na(x)))
    return (x)
  
  err(x, obj, 
      'must be a single string (scalar character)\n',
      'Argument received: "', encodeString(x, quote = "`") ,'"' )
}


validate_timeout <- function (x, obj) {
  
  if (identical(x, Inf)) return (Inf)
  if (isTRUE(x == 0))    return (0L)
  
  if (isTRUE(x >= 0) && x %% 1 == 0)
    return (as.integer(x))
  
  err(x, obj, 'must be an unsigned integer or Inf')
}


validate_assert <- function (x, obj) {
  
  if (is.null(x)) return ('NULL')
  
  if (is.character(x) && isTRUE(nchar(x) > 0)) {
    x <- tolower(x)
    if (startsWith('create', x)) return ('create')
    if (startsWith('exists', x)) return ('exists')
  }
  
  err(x, obj, 'must be "create", "exists", or NULL')
}


validate_uint <- function (x, obj) {
  
  if (isTRUE(x >= 0) && x < Inf && x %% 1 == 0)
    return (as.integer(x))
  
  err(x, obj, 'must be an unsigned integer')
}


validate_bool <- function (x, obj) {
  
  if (isTRUE(x) || isFALSE(x))
    return (x)
  
  err(x, obj, 'must be TRUE or FALSE')
}


