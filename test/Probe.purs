module Test.Probe where

import Effect (Effect)
import Effect.Exception (Error, message)

foreign import scenario :: Int
-- Observe the public error message as well as the native identity. This also
-- makes the probe's dependency on Effect.Exception visible to code generation.
sameError :: Error -> Error -> Boolean
sameError first second = sameErrorImpl (message first) first second

foreign import sameErrorImpl :: String -> Error -> Error -> Boolean
foreign import hasCause :: Error -> Error -> Boolean
foreign import rustPanic :: Effect Int
