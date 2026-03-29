# Rust API Starter

A modular and scalable Rust API starter built with Axum, designed as a foundation for trading market connectors.

## Features

- **Axum** - Fast and ergonomic web framework
- **Structured logging** - Using `tracing` with configurable log levels
- **OpenAPI documentation** - Auto-generated with Scalar UI at `/docs`
- **Error handling** - Centralized error types with proper HTTP responses
- **Docker ready** - Multi-stage build with tests
- **Git hooks** - Pre-commit formatting/linting + conventional commits validation
- **SonarQube** - Code quality analysis integration
- **DependencyTrack** - SBOM generation and vulnerability tracking

## Prerequisites

- **Rust** 1.75+ (stable)
- **Docker** (optional, for containerization)
- **Git** (for hooks)

## Architecture

```
src/
├── main.rs          # Application entry point
├── lib.rs           # Module exports
├── config.rs        # Configuration (env variables)
├── error.rs         # Centralized error handling
├── routes.rs        # Route definitions + OpenAPI setup
└── handlers/
    ├── mod.rs       # Handler module exports
    └── health.rs    # Health check endpoint
```

## Quick Start

### Local Development

```bash
# Install dependencies and build
cargo build

# Run the server
cargo run

# Run tests
cargo test

# Format code
cargo fmt

# Run linter
cargo clippy
```

### Environment Variables

| Variable   | Default   | Description          |
|------------|-----------|----------------------|
| `HOST`     | `0.0.0.0` | Server bind address  |
| `PORT`     | `3000`    | Server port          |
| `RUST_LOG` | `info`    | Log level            |

### Docker

```bash
# Build the image (includes tests)
docker build -t rust-api-starter .

# Run the container
docker run -p 3000:3000 rust-api-starter
```

## API Endpoints

| Method | Path      | Description                    |
|--------|-----------|--------------------------------|
| GET    | `/health` | Health check                   |
| GET    | `/docs`   | Scalar API documentation       |

## Git Hooks Setup

Install the git hooks to enable automatic formatting and conventional commits validation:

```bash
# Unix/macOS/Git Bash
sh .githooks/install.sh

# Or manually configure
git config core.hooksPath .githooks
```

### Conventional Commits

Commit messages must follow the [Conventional Commits](https://www.conventionalcommits.org/) format:

```
<type>(<scope>): <description>

Types: feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert
```

Examples:
- `feat: add user authentication`
- `fix(api): resolve timeout issue`
- `docs: update README`

## Development

### Adding New Endpoints

1. Create a handler in `src/handlers/`
2. Add the route in `src/routes.rs`
3. Document with `#[utoipa::path]` macro
4. Register in `ApiDoc` struct for OpenAPI

### Error Handling

Use the centralized `AppError` type:

```rust
use crate::error::{AppError, AppResult};

async fn my_handler() -> AppResult<Json<MyResponse>> {
    // Return errors with proper HTTP status
    Err(AppError::NotFound("Resource not found".to_string()))
}
```

## Security & Code Quality

### SonarQube Analysis

Run code quality analysis and upload results to SonarQube:

```bash
# Set environment variables
export SONAR_HOST_URL="https://sonar.example.com"
export SONAR_TOKEN="your-token"
export SONAR_PROJECT_KEY="rust-api-starter"  # optional

# Run analysis
./scripts/sonar-scan.sh
```

### DependencyTrack (SBOM)

Generate and upload Software Bill of Materials:

```bash
# Generate SBOM (CycloneDX format)
./scripts/sbom-generate.sh

# Upload to DependencyTrack
export DTRACK_URL="https://dtrack.example.com"
export DTRACK_API_KEY="your-api-key"
export DTRACK_PROJECT_UUID="project-uuid"
./scripts/dtrack-upload.sh
```

### CI/CD Docker Build

Use `Dockerfile.ci` for builds with security analysis:

```bash
# Build with all analyses
docker build -f Dockerfile.ci -t rust-api-starter:ci \
  --build-arg RUN_SONAR=true \
  --build-arg RUN_DTRACK=true \
  --build-arg SONAR_HOST_URL="https://sonar.example.com" \
  --build-arg SONAR_TOKEN="$SONAR_TOKEN" \
  --build-arg DTRACK_URL="https://dtrack.example.com" \
  --build-arg DTRACK_API_KEY="$DTRACK_API_KEY" \
  --build-arg DTRACK_PROJECT_UUID="$DTRACK_PROJECT_UUID" \
  .
```

| Variable | Description |
|----------|-------------|
| `RUN_SONAR` | Enable SonarQube analysis (true/false) |
| `RUN_DTRACK` | Enable DependencyTrack SBOM (true/false) |
| `SONAR_HOST_URL` | SonarQube server URL |
| `SONAR_TOKEN` | SonarQube authentication token |
| `DTRACK_URL` | DependencyTrack API URL |
| `DTRACK_API_KEY` | DependencyTrack API key |
| `DTRACK_PROJECT_UUID` | DependencyTrack project UUID |

## License

MIT
