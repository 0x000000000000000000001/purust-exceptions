# purust-exceptions

Native Rust implementation of the PureScript exception API for Purust.

`throwException` and `catchException` return deferred, replayable `Effect`
actions. Errors preserve their message, name, cause, and identity when caught or
rethrown. `errorWithName` takes the message first and the name second, matching
the PureScript and JavaScript API. Native errors return `Nothing` from `stack`;
`show` renders their name and message.

The error data lives in an `Arc`. Rust unwinding carries that error handle,
without requiring PureScript `Value` or its `Rc` closures to implement `Send`.
Handled PureScript exceptions do not print panic diagnostics. Other Rust panics
continue unwinding, so invalid generated code and native runtime faults are not
silently converted into recoverable PureScript errors.

The public Rust helpers `purust_exception_try` and `purust_exception_raise`
provide the same transport to asynchronous runtimes such as Aff.

## Tests

```bash
bin/test
bin/test -c
```

The Bash runner uses Spago installed in the sibling `purust` compiler and
prefers the TAST compiler fork in `../../purescript`. Set `PURS` to choose its
executable explicitly. `-c` also rebuilds Purust and clears this package's Spago
cache. Every run regenerates this package's TAST and Rust output.

Tests retain the exception assertions from `gopurs-exceptions`, with the
`errorWithName` arguments corrected to the PureScript API. Additional tests cover
Effect/Ref sequencing, deferred replay, successful and failing `try`, nested
handlers, preserved error and cause identity, structured values, and
`unsafeThrowException`. The runner checks exact output and verifies that uncaught
errors, throwing handlers, and native Rust panics exit unsuccessfully.

## Installation

Add `exceptions` to your package dependencies and select this native package in
the workspace:

```yaml
workspace:
  extraPackages:
    exceptions:
      path: ../purust-exceptions
```

## Documentation

Module documentation is [published on Pursuit](http://pursuit.purescript.org/packages/purescript-exceptions).
