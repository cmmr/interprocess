
#' Send Text Messages Between Processes
#' 
#' An interprocess queue that ensures each message is delivered to only one
#' reader, at which time the message is removed from the queue. Ideal for 
#' producer/consumer situations where the message defines work waiting to be 
#' processed. The message itself can be any scalar character, for example, a 
#' JSON string or path to an RDS file.
#' 
#' 
#' @family shared objects
#' @rdname queue
#' 
#' @param name    Unique ID. Alphanumeric, starting with a letter.
#' 
#' @param max_count   The maximum number of messages that can be stored in 
#'        the queue at the same time. Attempting to send additional messages
#'        will cause `send()` to block or return `FALSE`. Ignored if the queue 
#'        already exists.
#' 
#' @param max_nchar   The maximum number of characters in each message. 
#'        Attempting to send larger messages will throw an error. Ignored if 
#'        the queue already exists.
#' 
#' @param assert
#' Apply an additional constraint.
#' * `'create'` - Error if the queue __already exists__.
#' * `'exists'` - Error if the queue __doesn't exist__.
#' * `NULL` - No constraint; create the queue if it doesn't exist.
#' 
#' @param cleanup   Remove the queue when the R session exits. If `FALSE`, 
#'        the queue will persist until `$remove()` is called or the operating 
#'        system is restarted.
#' 
#' @param file   Use a hash of this file/directory path as the queue name. The 
#'        file itself will not be read or modified, and does not need to exist.
#' 
#' @param timeout_ms   Maximum time (in milliseconds) to block the process 
#'        while waiting for the operation to succeed. Use `0` or `Inf` to 
#'        return immediately or only when successful, respectively.
#' 
#' @param data   A `queue` object.
#' 
#' @param expr   Expression to evaluate if a message is received. The message
#'        can be accessed by `.` in this context. See examples.
#' 
#' @param alt_expr   Expression to evaluate if `timeout_ms` is reached.
#' 
#' @param ...   Not used.
#' 
#' @return
#' `queue()` returns a `queue` object with the following methods:
#' * `$name`
#'   - Returns the message queue's name (scalar character).
#' * `$send(msg, timeout_ms = Inf, priority = 0)`
#'   - Returns `TRUE` on success, or `FALSE` if the timeout is reached.
#'   - `msg`: The message (scalar character) to add to the message queue.
#'   - `priority`: Higher priority messages will be retrieved from the queue first. `0` = lowest priority; integers only.
#' * `$receive(timeout_ms = Inf)`
#'   - Returns the next message from the queue, or `NULL` if the timeout is reached.
#' * `$count()`
#'   - Returns the number of messages currently in the queue (scalar integer).
#' * `$max_count()`
#'   - Returns the maximum number of messages the queue can hold (scalar integer).
#' * `$max_nchar()`
#'   - Returns the maximum number of characters per message (scalar integer).
#' * `$remove()`
#'   - Returns `TRUE` if the queue was successfully deleted from the operating system, or `FALSE` on error.\cr\cr
#' 
#' `with()` returns `eval(expr)` on success; `eval(alt_expr)` otherwise.
#' 
#' @export
#' @examples
#' 
#' mq <- interprocess::queue()
#' print(mq)
#' 
#' mq$send(paste('my favorite number is', floor(runif(1) * 100)))
#' mq$count()
#' 
#' mq$receive()
#' mq$receive(timeout_ms = 0)
#' 
#' mq$send('The Matrix has you...')
#' with(mq, paste('got message:', .), 'no messages', timeout_ms = 0)
#' with(mq, paste('got message:', .), 'no messages', timeout_ms = 0)
#' 
#' mq$remove()

queue <- function (name = uid(), assert = NULL, max_count = 100, max_nchar = 128, cleanup = FALSE, file = NULL) {
  
  if (!missing(file)) {
    if (!missing(name)) stop('Provide either `name` or `file`, not both.')
    name <- hash(normalizePath(file, winslash = '/', mustWork = FALSE))
  }
  
  name      <- validate_name(name,      'queue')
  assert    <- validate_assert(assert,  'queue')
  max_count <- validate_uint(max_count, 'queue')
  max_nchar <- validate_uint(max_nchar, 'queue')
  cleanup   <- validate_bool(cleanup,   'queue')
  
  tryCatch(
    error = function (e) open_error('message queue', name, assert, e),
    expr  = switch(
      EXPR = assert,
      'create' = rcpp_queue_create_only(name, max_count, max_nchar),
      'exists' = rcpp_queue_open_only(name),
      'NULL'   = rcpp_queue_open_create(name, max_count, max_nchar) ))
  
  if (isTRUE(cleanup))
    ENV$msg_queues <- c(ENV$msg_queues, name)
  
  structure(
    class = c('queue', 'interprocess'),
    list(
      name      = name,
      send      = function (msg, timeout_ms = Inf, priority = 0) queue_send(name, msg, timeout_ms, priority),
      receive   = function (timeout_ms = Inf)                    queue_receive(name, timeout_ms),
      count     = function ()                                    queue_count(name),
      remove    = function ()                                    queue_remove(name),
      max_count = function ()                                    queue_max_count(name),
      max_nchar = function ()                                    queue_max_nchar(name)
    ))
}


#' @rdname queue
#' @export

with.queue <- function (data, expr, alt_expr = NULL, timeout_ms = Inf, ...) {
  
  if (is.null(msg <- data$receive(timeout_ms))) {
    expr <- alt_expr
  }
  else {
    
    # Assign msg to . in expr's evaluation environment.
    # Ensure that .'s value is restored afterwards.
    
    pos <- parent.frame()
    
    if (exists('.', pos)) {
      old_dot <- get('.', pos)
      on.exit(assign('.', old_dot, pos))
    } else {
      on.exit(remove('.', pos = pos))
    }
    
    assign('.', msg, pos)
  }
  
  x <- eval(withVisible(expr), envir = parent.frame())
  if (x$visible) x$value else invisible(x$value)
}



queue_send <- function (name, msg, timeout_ms = Inf, priority = 0) {
  
  msg        <- validate_string(msg,         'queue')
  timeout_ms <- validate_timeout(timeout_ms, 'queue')
  priority   <- validate_uint(priority,      'queue')
  
  switch(
    EXPR = as.character(timeout_ms),
    'Inf' = invisible(rcpp_queue_send(name, msg, priority)),
    '0'   = rcpp_queue_try_send(name, msg, priority),
    rcpp_queue_timed_send(name, msg, priority, timeout_ms) )
}


queue_receive <- function (name, timeout_ms = Inf) {
  
  timeout_ms <- validate_timeout(timeout_ms, 'queue')
  
  msg <- switch(
    EXPR = as.character(timeout_ms),
    'Inf' = rcpp_queue_receive(name),
    '0'   = rcpp_queue_try_receive(name),
    rcpp_queue_timed_receive(name, timeout_ms) )
  
  if (is.na(msg)) NULL else msg
}


queue_count <- function (name) {
  size_t <- rcpp_queue_get_num_msg(name)
  as.integer(size_t)
}


queue_max_count <- function (name) {
  size_t <- rcpp_queue_get_max_msg(name)
  as.integer(size_t)
}


queue_max_nchar <- function (name) {
  size_t <- rcpp_queue_get_max_msg_size(name)
  as.integer(size_t)
}


queue_remove <- function (name) {
  ENV$msg_queues <- setdiff(ENV$msg_queues, name)
  invisible(rcpp_queue_remove(name))
}
