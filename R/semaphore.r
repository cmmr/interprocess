
#' Increment and Decrement an Integer
#' 
#' A semaphore is an integer that the operating system keeps track of. Any 
#' process that knows the semaphore's identifier can increment or decrement its 
#' value, though it cannot be decremented below zero.\cr\cr
#' When the semaphore is zero, calling `$wait(timeout_ms = 0)` will 
#' return `FALSE` whereas `$wait(timeout_ms = Inf)` will block until the 
#' semaphore is incremented by another process. If multiple processes are 
#' blocked, a single call to `$post()` will only unblock one of the 
#' blocked processes.\cr\cr
#' It is possible to wait for a specific amount of time, for example, 
#' `$wait(timeout_ms = 10000)` will wait for 10 seconds. If the 
#' semaphore is incremented within those 10 seconds, the function will 
#' immediately return `TRUE`. Otherwise it will return `FALSE` at the 10 second 
#' mark.
#' 
#' 
#' @family shared objects
#' @rdname semaphore
#' 
#' @param name    Unique ID. Alphanumeric, starting with a letter.
#' 
#' @param value   The initial value of the semaphore.
#' 
#' @param assert   
#' Apply an additional constraint.
#' * `'create'` - Error if the semaphore __already exists__.
#' * `'exists'` - Error if the semaphore __doesn't exist__.
#' * `NULL` - No constraint; create the semaphore if it doesn't exist.
#' 
#' @param cleanup   Remove the semaphore when the R session exits. If `FALSE`, 
#'        the semaphore will persist until `$remove()` is called or the 
#'        operating system is restarted.
#' 
#' @param file   Use a hash of this file/directory path as the semaphore name. 
#'        The file itself will not be read or modified, and does not need to 
#'        exist.
#' 
#' @param timeout_ms   Maximum time (in milliseconds) to block the process 
#'        while waiting for the operation to succeed. Use `0` or `Inf` to 
#'        return immediately or only when successful, respectively.
#' 
#' @param data   A `semaphore` object.
#' 
#' @param expr   Expression to evaluate if a semaphore is posted.
#' 
#' @param alt_expr   Expression to evaluate if `timeout_ms` is reached.
#' 
#' @param ...   Not used.
#' 
#' @return
#' `semaphore()` returns a `semaphore` object with the following methods:
#' * `$name`
#'   - Returns the semaphore's name (scalar character).
#' * `$post()`
#'   - Returns `TRUE` if the increment was successful, or `FALSE` on error.
#' * `$wait(timeout_ms = Inf)`
#'   - Returns `TRUE` if the decrement was successful, or `FALSE` if the timeout is reached.
#' * `$remove()`
#'   - Returns `TRUE` if the semaphore was successfully deleted from the operating system, or `FALSE` on error.\cr\cr
#' 
#' `with()` returns `eval(expr)` on success, or `eval(alt_expr)` if the timeout is reached.
#' 
#' @export
#' @examples
#' 
#' sem <- interprocess::semaphore()
#' print(sem)
#' 
#' sem$post()
#' sem$wait(timeout_ms = 0)
#' sem$wait(timeout_ms = 0)
#' 
#' sem$post()
#' with(sem, 'success', 'timed out', timeout_ms = 0)
#' with(sem, 'success', 'timed out', timeout_ms = 0)
#' 
#' sem$remove()

semaphore <- function (name = uid(), assert = NULL, value = 0, cleanup = FALSE, file = NULL) {
  
  if (!missing(file)) {
    if (!missing(name)) stop('Provide either `name` or `file`, not both.')
    name <- hash(normalizePath(file, winslash = '/', mustWork = FALSE))
  }
  
  name    <- validate_name(name,     'semaphore')
  value   <- validate_uint(value,    'semaphore')
  assert  <- validate_assert(assert, 'semaphore')
  cleanup <- validate_bool(cleanup,  'semaphore')
  
  tryCatch(
    error = function (e) open_error('semaphore', name, assert, e),
    expr  = switch(
      EXPR = assert,
      'create' = rcpp_sem_create_only(name, value),
      'exists' = rcpp_sem_open_only(name),
      'NULL'   = rcpp_sem_open_create(name, value) ))
  
  
  if (isTRUE(cleanup))
    ENV$semaphores <- c(ENV$semaphores, name)
  
  structure(
    class = c('semaphore', 'interprocess'),
    list(
      name   = name,
      post   = function ()                 sem_post(name),
      wait   = function (timeout_ms = Inf) sem_wait(name, timeout_ms),
      remove = function ()                 sem_remove(name)
    ))
}


#' @rdname semaphore
#' @export

with.semaphore <- function (data, expr, alt_expr = NULL, timeout_ms = Inf, ...) {
  
  if (!data$wait(timeout_ms)) expr <- alt_expr
  
  x <- eval(withVisible(expr), envir = parent.frame())
  if (x$visible) x$value else invisible(x$value)
}



sem_post <- function (name) {
  invisible(rcpp_sem_post(name)) # always TRUE
}


sem_wait <- function (name, timeout_ms = Inf) {
  
  timeout_ms <- validate_timeout(timeout_ms, 'semaphore')
  
  switch(
    EXPR = as.character(timeout_ms),
    'Inf' = invisible(rcpp_sem_wait(name)), # always TRUE
    '0'   = rcpp_sem_try_wait(name),
    rcpp_sem_timed_wait(name, timeout_ms) )
}


sem_remove <- function (name) {
  ENV$semaphores <- setdiff(ENV$semaphores, name)
  invisible(rcpp_sem_remove(name))
}

