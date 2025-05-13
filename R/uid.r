
#' Generate Names
#' 
#' To ensure broad compatibility across different operating systems, names of 
#' mutexes, semaphores, and message queues should start with a letter followed 
#' by up to 249 alphanumeric characters. These functions generate names meeting 
#' these requirements.\cr\cr
#' * `uid()`: 11-character encoding of PID and time since epoch.
#' * `hash()`: 11-character hash of any string (hash space = 2^64).
#' 
#' `uid()`s encode sequential 1/100 second intervals, beginning at the current
#' process's start time. If the number of requested UIDs exceeds the number of 
#' 1/100 seconds that the process has been alive, then the process will 
#' momentarily sleep before returning.
#' 
#' A `uid()` begins with `A - R`; a `hash()` begins with `a - v`.
#' 
#' @rdname uid
#' 
#' @param str   A string (scalar character).
#' 
#' @return   A string (scalar character) that can be used as a mutex, 
#'           semaphore, or message queue name.
#' 
#' @export
#' @examples
#' 
#'     library(interprocess)
#'     
#'     uid()
#'     
#'     hash('192.168.1.123:8011')
#'     

uid <- function () {
  
  # Constraints:
  # - maximum of 100 UIDs/second
  # - time overflows on Dec 14th, 3085
  # - PID < 4,194,304 (current std max)
  
  start_time    <- ENV$start_time
  curr_time     <- as.numeric(Sys.time())
  ENV$uids_made <- ENV$uids_made + 1
  
  if (ENV$uids_made / 100 > curr_time - start_time)
    Sys.sleep(0.02) # nocov
  
  paste(collapse = '', c(
    ENV$pid_base62,
    rcpp_base62(start_time, ENV$uids_made, 7) ))
}



#' @rdname uid
#' @export

hash <- function (str) {
  str <- as.character(str)
  stopifnot(isTRUE(!is.na(str)))
  rcpp_hash(str)
}

