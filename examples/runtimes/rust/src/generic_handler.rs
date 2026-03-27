use lambda_runtime::{Error, LambdaEvent};
use serde::Serialize;
use serde_json::Value;

/// This is a made-up example of what an outgoing message structure may look like.
/// There is no restriction on what it can be. The runtime requires responses
/// to be serialized into json. The runtime pays no attention
/// to the contents of the outgoing message payload.
#[derive(Serialize)]
pub(crate) struct Response {
    status_code: u16,
    runtime: String,
    architecture: &'static str,
    message: String,
}

/// This is the main body for the function.
/// Write your code inside it.
/// There are some code example in the following URLs:
/// - https://github.com/awslabs/aws-lambda-rust-runtime/tree/main/examples
/// - https://github.com/aws-samples/serverless-rust-demo/
pub(crate) async fn function_handler(_event: LambdaEvent<Value>) -> Result<Response, Error> {
    let resp = Response {
        status_code: 200,
        runtime: env!("RUSTC_VERSION").to_string(),
        architecture: std::env::consts::ARCH,
        message: "Hello from Rust Lambda!".to_string(),
    };

    Ok(resp)
}

#[cfg(test)]
mod tests {
    use super::*;
    use lambda_runtime::{Context, LambdaEvent};

    #[tokio::test]
    async fn test_function_handler() {
        let event = LambdaEvent::new(serde_json::json!({}), Context::default());
        let response = function_handler(event).await.unwrap();
        assert_eq!(response.status_code, 200);
        assert_eq!(response.message, "Hello from Rust Lambda!");
    }
}
