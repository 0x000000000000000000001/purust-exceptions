pub fn Test_Probe_scenario() -> i64 {
    std::thread::spawn(|| {
        std::thread::sleep(std::time::Duration::from_secs(10));
        eprintln!("Exception test timed out after 10 seconds");
        std::process::exit(124);
    });
    std::env::args().nth(1).unwrap_or_else(|| "0".to_owned()).parse().expect("integer scenario")
}

pub fn Test_Probe_sameErrorImpl(message: String, first: crate::UnknownType, second: crate::UnknownType) -> bool {
    let first = Purs_Effect_Exception::purust_exception_unbox(&first);
    let second = Purs_Effect_Exception::purust_exception_unbox(&second);
    first.message == message && std::sync::Arc::ptr_eq(&first, &second)
}

pub fn Test_Probe_hasCause(outer: crate::UnknownType, expected: crate::UnknownType) -> bool {
    let outer = Purs_Effect_Exception::purust_exception_unbox(&outer);
    let expected = Purs_Effect_Exception::purust_exception_unbox(&expected);
    outer.cause.as_ref().is_some_and(|cause| std::sync::Arc::ptr_eq(cause, &expected))
}

pub fn Test_Probe_rustPanic() -> crate::UnknownType {
    crate::Value::Func1(purust_core::Func1::Shared(std::rc::Rc::new(move |_| {
        panic!("intentional native Rust panic")
    })))
}
