

test_that("validate", {
  
  expect_error(validate_name(123))
  expect_error(validate_name(NA_character_))
  expect_error(validate_name(''))
  expect_error(validate_name(c('a', 'b')))
  expect_error(validate_name(paste(collapse = '', rep('a', 251))))
  expect_error(validate_name('a_b'))
  expect_error(validate_name('1ab'))
  
  expect_error(validate_string(123))
  expect_error(validate_string(NA_character_))
  expect_error(validate_string(c('a', 'b')))
  
  expect_error(validate_timeout(-1))
  expect_error(validate_timeout(1.5))
  expect_error(validate_timeout(1:2))
  expect_error(validate_timeout(NA_integer_))
  
  expect_error(validate_assert('abc'))
  
  expect_error(validate_uint(-1))
  expect_error(validate_timeout(1.5))
  expect_error(validate_timeout(1:2))
  expect_error(validate_uint(Inf))
  
  expect_error(validate_bool(c(T, F)))
  expect_error(validate_bool(NA))
})

