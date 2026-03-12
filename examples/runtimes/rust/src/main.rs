use lambda_runtime::{service_fn, tracing, Error, LambdaEvent};
use serde::Serialize;

#[derive(Serialize)]
struct Response {
    status_code: u16,
    message: String,
}

async fn handler(_event: LambdaEvent<serde_json::Value>) -> Result<Response, Error> {
    Ok(Response {
        status_code: 200,
        message: "Hello from Rust Lambda!".to_string(),
    })
}

#[tokio::main]
async fn main() -> Result<(), Error> {
    tracing::init_default_subscriber();
    lambda_runtime::run(service_fn(handler)).await
}
