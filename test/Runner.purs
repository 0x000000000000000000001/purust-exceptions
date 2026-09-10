module Test.Runner where

import Prelude

import Effect (Effect)
import Effect.Console (log)
import Effect.Exception as Exception
import Test.Checks as Checks
import Test.Main as Original
import Test.Probe (rustPanic, scenario)

main :: Effect Unit
main = case scenario of
  0 -> do
    Original.main
    Checks.run
  1 -> do
    _ <- Exception.throw "unhandled Exception"
    log "UNREACHABLE"
  2 -> do
    _ <- Exception.catchException
      (\_ -> Exception.throw "unhandled handler exception")
      (Exception.throw "original")
    log "UNREACHABLE"
  3 -> do
    _ <- Exception.catchException (const (pure 0)) rustPanic
    log "UNREACHABLE"
  10 -> Checks.properties
  11 -> Checks.deferredReplay
  12 -> Checks.success
  13 -> Checks.failedSequence
  14 -> Checks.nestedHandlers
  15 -> Checks.causeAndIdentity
  16 -> Checks.structuredResult
  17 -> Checks.unsafeException
  _ -> Exception.throw "Unknown test scenario"
