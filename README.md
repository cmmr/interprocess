# interprocess

<!-- badges: start -->
[![cran](https://www.r-pkg.org/badges/version/interprocess)](https://CRAN.R-project.org/package=interprocess)
[![dev](https://github.com/cmmr/interprocess/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/cmmr/interprocess/actions/workflows/R-CMD-check.yaml)
[![conda](https://anaconda.org/conda-forge/r-interprocess/badges/version.svg)](https://anaconda.org/conda-forge/r-interprocess)
[![covr](https://codecov.io/gh/cmmr/interprocess/graph/badge.svg)](https://app.codecov.io/gh/cmmr/interprocess)
<!-- badges: end -->


The goal of `interprocess` is to synchronize concurrent R processes.

Allows R to access low-level operating system mechanisms for performing atomic 
operations on shared data structures. Mutexes provide shared and exclusive 
locks. Semaphores act as counters. Message queues move text strings from one 
process to another. All these interprocess communication (IPC) tools can 
optionally block with or without a timeout.

Works cross-platform, including Windows, MacOS, and Linux, and can be used to 
synchronize a mixture of R sessions and other types of processes if needed.

Implemented using the [Boost C++ library](https://boost.org/libs/interprocess).


## Installation

``` r
# Install the latest stable version from CRAN:
install.packages("interprocess")

# Or the development version from GitHub:
install.packages("pak")
pak::pak("cmmr/interprocess")
```



## Usage

Mutexes, semaphores, and message queues are managed by the operating system. 
Any process that knows the resource's name can access it. Therefore, sharing 
the resource name (a short text string) amongst cooperating processes enables
communication and synchronization.

These names can be any alphanumeric string that starts with a letter and is no
longer than 250 characters. The `mutex()`, `semaphore()`, and `queue()` 
functions will default to generating a unique identifier, or you can provide a 
custom or pre-existing one with the `name` parameter. If the resource is 
associated with a specific file or directory, the `file` parameter can be used 
to derive a name from normalizing and hashing that path.

Setting `cleanup = TRUE` will automatically remove the resource when the R 
session exits. Otherwise, the resource will persist until `$remove()` is called 
or the operating system is restarted.



### Mutexes

An exclusive lock is acquired by default. For a shared lock, use 
`$lock(shared = TRUE)`.

``` r
tmp <- tempfile()
mut <- interprocess::mutex(file = tmp)

mut$name
#> [1] "S6qYUQK2SwA"

with(mut, writeLines('Important Data', tmp))

with(mut, shared = TRUE, readLines(tmp))
#> [1] "Important Data"

mut$remove()
unlink(tmp)
```



### Semaphores

The semaphore's value can be incremented with `$post()` and decremented with 
`$wait()`. The initial value can also be set in the constructor.

``` r
sem <- interprocess::semaphore(name = 'mySemaphore')

sem$name
#> [1] "mySemaphore"

sem$post()
sem$post()

sem$wait(timeout_ms = 0)
#> [1] TRUE

sem$wait(timeout_ms = 0)
#> [1] TRUE

sem$wait(timeout_ms = 0)
#> [1] FALSE

sem$remove()
```



### Message Queues

The constructor's `max_count` and `max_nchar` parameters determine how much 
memory is allocated for the queue.

``` r
mq <- interprocess::queue(max_count = 2, max_nchar = 5)

mq$name
#> [1] "akRKb4iymMcAFV"

mq$send('Hello')
mq$send('Hi', priority = 1)

mq$receive(timeout_ms = 0)
#> [1] "Hi"

mq$receive(timeout_ms = 0)
#> [1] "Hello"

mq$receive(timeout_ms = 0)
#> [1] NULL

mq$remove()
```

