
#' @export
format.interprocess <- function (x, ...) x$name

#' @export
as.character.interprocess <- function (x, ...) x$name

#' @export
print.interprocess <- function (x, ...)
  cat(file = stdout(), '<', class(x)[[1]], '> "', x$name, '"\n', sep = '')
