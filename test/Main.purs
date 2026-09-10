module Test.Main where

import Prelude

import Effect (Effect)
import Effect.Console (log)
import Effect.Exception (catchException, error, message, name, throwException, errorWithCause, errorWithName)
import Test.Assert (assert)
import Data.Either (Either(..))

main :: Effect Unit
main = do
  log "Testing throwException and catchException"
  res1 <- catchException (\e -> pure (Left (message e))) do
    _ <- throwException (error "Test error")
    pure (Right "Should not be reached")
  case res1 of
    Left msg -> assert (msg == "Test error")
    Right _ -> assert false

  log "Testing another caught exception"
  res2 <- catchException (\e -> pure (Left (message e))) do
    _ <- throwException (error "another panic")
    pure (Right "skip")
  case res2 of
    Left msg -> assert (msg == "another panic")
    Right _ -> assert false

  log "Testing Error properties"
  let e = error "Some error"
  assert (message e == "Some error")
  assert (name e == "Error")
  -- The PureScript/JavaScript API takes message, then name.
  let e2 = errorWithName "Custom message" "CustomError"
  assert (message e2 == "Custom message")
  assert (name e2 == "CustomError")
  let e3 = errorWithCause "Outer error" e
  assert (message e3 == "Outer error")
  log "All tests passed"
