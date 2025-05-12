
#' Shared and Exclusive Locks
#' 
#' Mutually exclusive (mutex) locks are used to control access to shared
#' resources.\cr\cr
#' An _exclusive lock_ grants permission to one process at a time, for 
#' example to update the contents of a database file. While an exclusive lock 
#' is active, no other exclusive or shared locks will be granted.\cr\cr
#' Multiple _shared locks_ can be held by different processes at the same 
#' time, for example to read a database file. While a shared lock is active, no 
#' exclusive locks will be granted.
#' 
#' 
#' @rdname mutex
#' 
#' @param name    Unique ID. Alphanumeric, starting with a letter.
#' 
#' @param assert   
#' Apply an additional constraint.
#' * `'create'` - Error if the mutex _already exists_.
#' * `'exists'` - Error if the mutex _doesn't exist_.
#' * `NULL` - No constraint; create the mutex if it doesn't exist.
#' 
#' @param cleanup   Remove the mutex when the R session exits. If `FALSE`, 
#'        the mutex will persist until `$remove()` is called or the operating 
#'        system is restarted.
#' 
#' @param file   Use a hash of this file/directory path as the mutex name. The 
#'        file itself will not be read or modified, and does not need to exist.
#' 
#' @param shared   If `FALSE` (the default) an exclusive lock is returned. 
#'        If `TRUE`, a shared lock is returned instead. See description.
#' 
#' @param timeout_ms   Maximum time (in milliseconds) to block the process 
#'        while waiting for the operation to succeed. Use `0` or `Inf` to 
#'        return immediately or only when successful, respectively.
#' 
#' @param data   A `mutex` object.
#' 
#' @param expr   Expression to evaluate if the mutex is acquired.
#' 
#' @param alt_expr   Expression to evaluate if `timeout_ms` is reached.
#' 
#' @param ...   Not used.
#' 
#' @return
#' `mutex()` returns a `mutex` object with the following methods:
#' * `$name`
#'   - Returns the mutex's name (scalar character).
#' * `$lock(shared = FALSE, timeout_ms = Inf)`
#'   - Returns `TRUE` if the lock is acquired, or `FALSE` if the timeout is reached.
#' * `$unlock(warn = TRUE)`
#'   - Returns `TRUE` if successful, or `FALSE` (with optional warning) if the mutex wasn't locked.
#' * `$remove()`
#'   - Returns `TRUE` on success, or `FALSE` if the mutex wasn't found.\cr\cr
#' 
#' `with()` returns `eval(expr)` if the lock was acquired, or `eval(alt_expr)` if the timeout is reached.
#' 
#' 
#' @section Error Handling:
#' 
#' The `with()` wrapper automatically unlocks the mutex if an error stops 
#' evaluation of `expr`. If you are directly calling `lock()`, be sure that
#' `unlock()` is registered with error handlers or added to `on.exit()`. 
#' Otherwise, the lock will persist until the process terminates.
#' 
#' 
#' @section Duplicate Mutexes:
#' 
#' Mutex locks are per-process. If a process already has a lock, it can not 
#' attempt to acquire a second lock on the same mutex.
#' 
#' 
#' 
#' @export
#' @examples
#' 
#' tmp <- tempfile()
#' mut <- interprocess::mutex(file = tmp)
#' 
#' print(mut)
#' 
#' # Exclusive lock to write the file
#' with(mut, writeLines('some data', tmp))
#' 
#' # Use a shared lock to read the file
#' with(mut,
#'   shared     = TRUE,
#'   timeout_ms = 0, 
#'   expr       = readLines(tmp), 
#'   alt_expr   = warning('Mutex was locked. Giving up.') )
#' 
#' # Directly lock/unlock with safeguards
#' if (mut$lock(timeout_ms = 0)) {
#'   local({
#'     on.exit(mut$unlock())
#'     writeLines('more data', tmp)
#'   })
#' } else {
#'   warning('Mutex was locked. Giving up.')
#' }
#' 
#' mut$remove()
#' unlink(tmp)

mutex <- function (name = uid('M'), assert = NULL, cleanup = FALSE, file = NULL) {
  
  if (!missing(file)) {
    if (!missing(name)) stop('Provide either `name` or `file`, not both.')
    name <- hash(normalizePath(file, winslash = '/', mustWork = FALSE))
  }
  
  name    <- validate_name(name,     'mutex')
  assert  <- validate_assert(assert, 'mutex')
  cleanup <- validate_bool(cleanup,  'mutex')
  
  switch(
    EXPR = assert,
    'create' = rcpp_mutex_create_only(name),
    'exists' = rcpp_mutex_open_only(name),
    'NULL'   = rcpp_mutex_open_create(name) )
  
  if (isTRUE(cleanup))
    ENV$mutexes <- c(ENV$mutexes, name)
  
  structure(
    class = c('mutex', 'interprocess'),
    list(
      name   = name,
      lock   = function (shared = FALSE, timeout_ms = Inf) mutex_lock(name, shared, timeout_ms),
      unlock = function (warn = TRUE) mutex_unlock(name, warn),
      remove = function () mutex_remove(name)
    ))
}


#' @rdname mutex
#' @export

with.mutex <- function (data, expr, alt_expr = NULL, shared = FALSE, timeout_ms = Inf, ...) {
  
  if (data$lock(shared, timeout_ms)) {
    on.exit(data$unlock())
  } else {
    expr <- alt_expr # nocov
  }
  
  x <- eval(withVisible(expr), envir = parent.frame())
  if (x$visible) x$value else invisible(x$value)
}



mutex_lock <- function (name, shared = FALSE, timeout_ms = Inf) {
  
  shared     <- validate_bool(shared,        'mutex')
  timeout_ms <- validate_timeout(timeout_ms, 'mutex')
  
  
  if (name %in% c(ENV$excl_locks, ENV$shared_locks))
    stop('mutex is already locked by this process')
    
  
  # ______________________________
  # Shared Lock
  # ______________________________
  if (isTRUE(shared)) {
    
    success <- switch(
      EXPR = as.character(timeout_ms),
      'Inf' = rcpp_mutex_lock_sharable(name), # always TRUE
      '0'   = rcpp_mutex_try_lock_sharable(name),
      rcpp_mutex_timed_lock_sharable(name, timeout_ms) )
    
    if (isTRUE(success))
      ENV$shared_locks <- c(ENV$shared_locks, name)
  }
  
  # ______________________________
  # Exclusive Lock
  # ______________________________
  else {
    
    success <- switch(
      EXPR = as.character(timeout_ms),
      'Inf' = rcpp_mutex_lock(name), # always TRUE
      '0'   = rcpp_mutex_try_lock(name),
      rcpp_mutex_timed_lock(name, timeout_ms) )
    
    if (isTRUE(success))
      ENV$excl_locks <- c(ENV$excl_locks, name)
  }
  
  if (timeout_ms == Inf) invisible(TRUE) else success
}


mutex_unlock <- function (name, warn = TRUE) {
  
  if (name %in% ENV$excl_locks) {
    ENV$excl_locks <- setdiff(ENV$excl_locks, name)
    rcpp_mutex_unlock(name)  # always TRUE
  }
  
  else if (name %in% ENV$shared_locks) {
    ENV$shared_locks <- setdiff(ENV$shared_locks, name)
    rcpp_mutex_unlock_sharable(name)  # always TRUE
  }
  
  else {
    if (warn) warning('mutex is not locked by this process')
    return (FALSE)
  }
  
  invisible(TRUE)
}


mutex_remove <- function (name) {
  ENV$mutexes <- setdiff(ENV$mutexes, name)
  invisible(rcpp_mutex_remove(name))
}


