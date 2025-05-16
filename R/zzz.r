
# nocov start
ENV <- new.env(parent = emptyenv())

.onLoad <- function (libname, pkgname) {
  
  ENV$pid_base62   <- rcpp_base62(Sys.getpid() + 26 * 62^3, 0, 4)
  ENV$start_time   <- as.numeric(Sys.time())
  ENV$uids_made    <- 0
  ENV$semaphores   <- c()
  ENV$msg_queues   <- c()
  ENV$mutexes      <- c()
  ENV$excl_locks   <- c()
  ENV$shared_locks <- c()
  
  finalizer <- function (e) {
    
    # Remove resources created with cleanup=TRUE
    for (x in e$semaphores) try(silent = TRUE, rcpp_sem_remove(x))
    for (x in e$msg_queues) try(silent = TRUE, rcpp_mq_remove(x))
    for (x in e$mutexes)    try(silent = TRUE, rcpp_mutex_remove(x))
    
    # Remove locks on remaining resources
    for (x in setdiff(e$excl_locks,   e$mutexes)) try(silent = TRUE, rcpp_mutex_unlock(x))
    for (x in setdiff(e$shared_locks, e$mutexes)) try(silent = TRUE, rcpp_mutex_unlock_sharable(x))
  }
  
  reg.finalizer(ENV, finalizer, onexit = TRUE)
  
}
# nocov end
