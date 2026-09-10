// Error data can travel through Rust's Send panic payload without making
// PureScript Value or its Rc-backed closures Send.
#[derive(Debug)]
pub struct PurustExceptionError {
    pub message: String,
    pub name: String,
    pub cause: Option<std::sync::Arc<PurustExceptionError>>,
}

fn purust_exception_box(error: std::sync::Arc<PurustExceptionError>) -> crate::UnknownType {
    crate::Value::Class(std::rc::Rc::new(error))
}

pub fn purust_exception_unbox(error: &crate::UnknownType) -> std::sync::Arc<PurustExceptionError> {
    error.unwrap_class::<std::sync::Arc<PurustExceptionError>>().clone()
}

pub fn purust_exception_raise(error: crate::UnknownType) -> ! {
    // resume_unwind bypasses the panic hook: handled PureScript exceptions
    // must not print an unrelated Rust panic diagnostic.
    std::panic::resume_unwind(Box::new(purust_exception_unbox(&error)))
}

pub fn purust_exception_try(
    action: impl FnOnce() -> crate::UnknownType,
) -> Result<crate::UnknownType, crate::UnknownType> {
    match std::panic::catch_unwind(std::panic::AssertUnwindSafe(action)) {
        Ok(value) => Ok(value),
        Err(payload) => match payload.downcast::<std::sync::Arc<PurustExceptionError>>() {
            Ok(error) => Err(purust_exception_box(*error)),
            Err(payload) => std::panic::resume_unwind(payload),
        },
    }
}

fn purust_exception_effect(action: impl Fn() -> crate::UnknownType + 'static) -> crate::UnknownType {
    crate::Value::Func1(purust_core::Func1::Shared(std::rc::Rc::new(move |_| action())))
}

pub fn Effect_Exception_error(message: String) -> crate::UnknownType {
    Effect_Exception_errorWithName(message, "Error".to_owned())
}

pub fn Effect_Exception_errorWithCause(message: String, cause: crate::UnknownType) -> crate::UnknownType {
    purust_exception_box(std::sync::Arc::new(PurustExceptionError {
        message,
        name: "Error".to_owned(),
        cause: Some(purust_exception_unbox(&cause)),
    }))
}

pub fn Effect_Exception_errorWithName(message: String, name: String) -> crate::UnknownType {
    purust_exception_box(std::sync::Arc::new(PurustExceptionError {
        message,
        name,
        cause: None,
    }))
}

pub fn Effect_Exception_message(error: crate::UnknownType) -> String {
    purust_exception_unbox(&error).message.clone()
}

pub fn Effect_Exception_name(error: crate::UnknownType) -> String {
    let name = purust_exception_unbox(&error).name.clone();
    if name.is_empty() { "Error".to_owned() } else { name }
}

pub fn Effect_Exception_showErrorImpl(error: crate::UnknownType) -> String {
    let error = purust_exception_unbox(&error);
    if error.name.is_empty() {
        error.message.clone()
    } else if error.message.is_empty() {
        error.name.clone()
    } else {
        format!("{}: {}", error.name, error.message)
    }
}

pub fn Effect_Exception_stackImpl<T>(
    _just: purust_core::Func1<crate::UnknownType, T>,
    nothing: T,
    _error: crate::UnknownType,
) -> T {
    // A native Rust error has no JavaScript stack trace.
    nothing
}

pub fn Effect_Exception_throwException(error: crate::UnknownType) -> crate::UnknownType {
    purust_exception_effect(move || purust_exception_raise(error.clone()))
}

pub fn Effect_Exception_catchException(
    handler: purust_core::Func1<crate::UnknownType, crate::UnknownType>,
    action: crate::UnknownType,
) -> crate::UnknownType {
    purust_exception_effect(move || match purust_exception_try(|| action.unwrap_func1()(crate::Value::Unit)) {
        Ok(value) => value,
        Err(error) => handler(error).unwrap_func1()(crate::Value::Unit),
    })
}
