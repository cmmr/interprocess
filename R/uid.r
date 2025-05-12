
#' Generate Names
#' 
#' To ensure broad compatibility across different operating systems, names of 
#' mutexes, semaphores, and message queues should start with a letter followed 
#' by up to 249 alphanumeric characters. These functions generate names meeting 
#' these requirements.\cr\cr
#' * `uid()`: 13-character encoding of PID and time since epoch.
#' * `hash()`: 11-character hash of any string (hash space = 2^64).
#' 
#' `uid()`s encode sequential millisecond intervals, beginning at the current
#' process's start time. If the number of requested UIDs exceeds the number of 
#' milliseconds the process has been alive, then the process will momentarily
#' sleep before returning.
#' 
#' `uid()`, `hash()`, and `ps::ps_string()` all return strings of different
#' lengths, thereby preventing unintended collisions.
#' 
#' @rdname uid
#' 
#' @param prefix   A single letter (a-z or A-Z). The following defaults are 
#'        used throughout this package:
#'        * `'M'` - Mutex
#'        * `'Q'` - Message queue
#'        * `'S'` - Semaphore
#'        * `'U'` - General purpose unique id.
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

uid <- function (prefix = 'U') {
  
  stopifnot(is.character(prefix))
  stopifnot(prefix %in% c(letters, LETTERS))
  
  # Constraints:
  # - maximum of 1,000 UIDs/second
  # - time overflows on Dec 2nd, 8888
  # - PID <= 768,369,472 (std max = 4,194,304)
  
  ENV$uid_time <- ENV$uid_time + 1
  if (ENV$uid_time > floor(as.numeric(Sys.time()) * 1000))
    Sys.sleep(0.001) # nocov
  
  map <- c(letters, LETTERS, 0:9)
  
  str <- paste(collapse = '', map[1 + c(
    floor(ENV$uid_time / 62 ^ (7:0)) %% 62 )])
  
  paste0(prefix, ENV$pid_code, str)
}



#' @rdname uid
#' @export

hash <- function (str) {
  
  str <- as.character(str)
  stopifnot(isTRUE(!is.na(str)))
  
  value <- rcpp_hash(str)
  map   <- c(letters, LETTERS, 0:9)
  
  # first character will always be 'a' - 'u'
  paste(
    collapse = '', 
    map[1 + floor(value / 62 ^ (10:0)) %% 62 ] )
}

