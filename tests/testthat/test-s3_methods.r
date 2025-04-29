

test_that("s3_methods", {
  
  m <- mutex()
  
  expect_identical(format(m), m$name)
  expect_identical(as.character(m), m$name)
  expect_output(print(m))
  
  expect_true(m$remove())
})

