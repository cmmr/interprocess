
#' Generate Names
#' 
#' To ensure broad compatibility across different operating systems, names of 
#' mutexes, semaphores, and message queues should start with a letter followed 
#' by up to 249 alphanumeric characters. These functions generate names meeting 
#' these requirements.\cr\cr
#' * `uid()`: 14-character encoding of PID and microseconds since epoch.
#' * `hash()`: 11-character hash of any string (hash space = 2^64).
#' 
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
  
  process_id <- Sys.getpid()
  unix_time  <- as.numeric(Sys.time())
  
  whole_secs <- as.integer(unix_time)
  micro_secs <- as.integer(unix_time %% 1 * 1000000)
  
  map <- c(letters, LETTERS, 0:9)
  
  paste(collapse = '', map[1 + c(
    floor(process_id / 52 ^ (3:0)) %% 52,
    floor(whole_secs / 62 ^ (5:0)) %% 62,
    floor(micro_secs / 62 ^ (3:0)) %% 62 )])
}



#' @rdname uid
#' @export

hash <- function (str) {
  
  str <- as.character(str)
  stopifnot(isTRUE(!is.na(str)))
  
  value <- rcpp_hash(str)
  
  result <- c()
  map    <- c(letters, LETTERS, 0:9)
  
  for (base in c(52, rep(62, 10))) {
    rem    <- value %% base
    result <- c(result, map[1 + rem])
    value  <- value - floor(value / base)
  }
  
  paste(collapse = '', result)
}

