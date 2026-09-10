module Test.Checks
  ( run
  , properties
  , deferredReplay
  , success
  , failedSequence
  , nestedHandlers
  , causeAndIdentity
  , structuredResult
  , unsafeException
  ) where

import Prelude

import Data.Either (Either(..))
import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Console (log)
import Effect.Exception as Exception
import Effect.Exception.Unsafe (unsafeThrowException)
import Effect.Ref as Ref
import Test.Assert (assert, assertEqual)
import Test.Probe (hasCause, sameError)

run :: Effect Unit
run = do
  properties
  deferredReplay
  success
  failedSequence
  nestedHandlers
  causeAndIdentity
  structuredResult
  unsafeException

properties :: Effect Unit
properties = do
  let
    normal = Exception.error "message"
    named = Exception.errorWithName "details" "CustomError"
    unnamed = Exception.errorWithName "details" ""
  assertEqual { actual: show normal, expected: "Error: message" }
  assertEqual { actual: show named, expected: "CustomError: details" }
  assertEqual { actual: Exception.name unnamed, expected: "Error" }
  assertEqual { actual: show unnamed, expected: "details" }
  assertEqual { actual: show (Exception.error ""), expected: "Error" }
  assertEqual { actual: Exception.stack normal, expected: Nothing }
  log "[OK] error names, messages, rendering and absent native stack"

deferredReplay :: Effect Unit
deferredReplay = do
  ref <- Ref.new 0
  let
    failing = do
      Ref.modify_ (_ + 1) ref
      Exception.throw "deferred"
    action = Exception.catchException
      (\err -> Ref.modify_ (_ + 100) ref $> Exception.message err)
      failing
  initial <- Ref.read ref
  assertEqual { actual: initial, expected: 0 }
  first <- action
  firstState <- Ref.read ref
  assertEqual { actual: first, expected: "deferred" }
  assertEqual { actual: firstState, expected: 101 }
  second <- action
  secondState <- Ref.read ref
  assertEqual { actual: second, expected: "deferred" }
  assertEqual { actual: secondState, expected: 202 }
  log "[OK] throwing and catching effects are deferred and replayable"

success :: Effect Unit
success = do
  ref <- Ref.new 0
  result <- Exception.catchException
    (\_ -> Ref.modify_ (_ + 100) ref $> 0)
    (Ref.modify (_ + 1) ref)
  count <- Ref.read ref
  assertEqual { actual: result, expected: 1 }
  assertEqual { actual: count, expected: 1 }
  attempted <- Exception.try (pure 42)
  case attempted of
    Right value -> assertEqual { actual: value, expected: 42 }
    Left _ -> assert false
  log "[OK] successful effects bypass handlers and try returns Right"

failedSequence :: Effect Unit
failedSequence = do
  ref <- Ref.new ""
  attempted <- Exception.try do
    Ref.write "before" ref
    _ <- Exception.throw "stop"
    Ref.write "after" ref
  case attempted of
    Left err -> assertEqual { actual: Exception.message err, expected: "stop" }
    Right _ -> assert false
  trace <- Ref.read ref
  assertEqual { actual: trace, expected: "before" }
  log "[OK] exceptions stop the remaining Effect and Ref sequence"

nestedHandlers :: Effect Unit
nestedHandlers = do
  ref <- Ref.new 0
  let
    original = Exception.error "original"
    replacement = Exception.errorWithName "replacement" "HandlerError"
  attempted <- Exception.try $ Exception.catchException
    (\err -> do
      assert (sameError original err)
      Ref.modify_ (_ + 1) ref
      Exception.throwException replacement)
    (Exception.throwException original :: Effect Int)
  case attempted of
    Left err -> do
      assert (sameError replacement err)
      assertEqual { actual: Exception.name err, expected: "HandlerError" }
    Right _ -> assert false
  count <- Ref.read ref
  assertEqual { actual: count, expected: 1 }
  log "[OK] a handler exception reaches the outer handler exactly once"

causeAndIdentity :: Effect Unit
causeAndIdentity = do
  let
    cause = Exception.error "inner"
    outer = Exception.errorWithCause "outer" cause
  assert (hasCause outer cause)
  assert (not (sameError cause (Exception.error "inner")))
  attempted <- Exception.try $ Exception.catchException
    Exception.throwException
    (Exception.throwException outer :: Effect Int)
  case attempted of
    Left err -> do
      assert (sameError outer err)
      assert (hasCause err cause)
      assertEqual { actual: Exception.message err, expected: "outer" }
    Right _ -> assert false
  log "[OK] throwing, catching and rethrowing preserve error and cause identity"

structuredResult :: Effect Unit
structuredResult = do
  ref <- Ref.new { count: 3, label: "before" }
  attempted <- Exception.try do
    Ref.modify_ (\value -> value { count = value.count + 4, label = "after" }) ref
    Ref.read ref
  case attempted of
    Right value -> do
      assertEqual { actual: value.count, expected: 7 }
      assertEqual { actual: value.label, expected: "after" }
    Left _ -> assert false
  log "[OK] try preserves structured values from references"

unsafeException :: Effect Unit
unsafeException = do
  let original = Exception.error "unsafe"
  attempted <- Exception.try do
    pure (unsafeThrowException original :: Int)
  case attempted of
    Left err -> assert (sameError original err)
    Right _ -> assert false
  log "[OK] unsafeThrowException is intercepted while evaluating an effect"
