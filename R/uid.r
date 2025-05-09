
#' Generate Names
#' 
#' To ensure broad compatibility across different operating systems, names of 
#' mutexes, semaphores, and message queues should start with a letter followed 
#' by up to 249 alphanumeric characters. These functions generate names meeting 
#' these requirements.\cr\cr
#' * `uid()`: 12-character encoding of PID and time since epoch.
#' * `hash()`: 12-character hash of any string (hash space = 2^64).
#' 
#' `uid()`s will not collide with a `hash()`.
#' * `uid()`s never start with `'Z'`.
#' * `hash()`s always start with `'Z'`.
#' 
#' `uid()`s will not collide with a `ps::ps_string()`.
#' * `uid()`s are always 12 characters long.
#' * `ps::ps_string()`s are always 11 characters long.
#' 
#' `uid()`s will not collide with each other.
#' * The first 4 characters encode the current PID.
#' * The last 8 characters encode sequential 1/10000 second intervals that the 
#' current process was alive. Attempting to generate more than 10,000 UIDs per 
#' second will cause the process to momentarily sleep.
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
  # - maximum of 10,000 UIDs/second
  # - time overflows on Nov 22nd, 2661
  # - PID <= 6,765,201 (std max = 4,194,304)
  
  ENV$uid_time <- ENV$uid_time + 1
  
  max_time <- floor(as.numeric(Sys.time() + 0.01) * 10000)
  if (max_time < ENV$uid_time) Sys.sleep(0.001) # nocov
  
  map <- c(letters, LETTERS, 0:9)
  
  paste(collapse = '', map[1 + c(
    floor(ENV$pid      / 51 ^ (3:0)) %% 51,
    floor(ENV$uid_time / 62 ^ (7:0)) %% 62 )])
}



#' @rdname uid
#' @export

hash <- function (str) {
  
  str <- as.character(str)
  stopifnot(isTRUE(!is.na(str)))
  
  value <- rcpp_hash(str)
  map   <- c(letters, LETTERS, 0:9)
  
  paste(
    collapse = '', 
    c('Z', map[1 + floor(value / 62 ^ (10:0)) %% 62 ]) )
}

