use axum::{routing::get, Router};
use utoipa::OpenApi;
use utoipa_scalar::{Scalar, Servable};

use crate::handlers::{self, health_check};

#[derive(OpenApi)]
#[openapi(
    paths(handlers::health::health_check),
    components(schemas(handlers::health::HealthResponse)),
    tags(
        (name = "Health", description = "Health check endpoints")
    ),
    info(
        title = "Rust API Starter",
        version = "0.1.0",
        description = "A Rust API starter for trading market connector"
    )
)]
pub struct ApiDoc;

pub fn create_router() -> Router {
    Router::new()
        .route("/health", get(health_check))
        .merge(Scalar::with_url("/docs", ApiDoc::openapi()))
}

#[cfg(test)]
mod tests {
    use super::*;
    use axum::body::Body;
    use axum::http::StatusCode;
    use http_body_util::BodyExt;
    use tower::ServiceExt;

    #[tokio::test]
    async fn test_health_endpoint() {
        let app = create_router();

        let response = app
            .oneshot(
                axum::http::Request::builder()
                    .uri("/health")
                    .body(Body::empty())
                    .unwrap(),
            )
            .await
            .unwrap();

        assert_eq!(response.status(), StatusCode::OK);

        let body = response.into_body().collect().await.unwrap().to_bytes();
        let body: serde_json::Value = serde_json::from_slice(&body).unwrap();

        assert_eq!(body["status"], "ok");
    }

    #[tokio::test]
    async fn test_docs_endpoint() {
        let app = create_router();

        let response = app
            .oneshot(
                axum::http::Request::builder()
                    .uri("/docs")
                    .body(Body::empty())
                    .unwrap(),
            )
            .await
            .unwrap();

        assert_eq!(response.status(), StatusCode::OK);
    }
}
