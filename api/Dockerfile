# Stage 1: Build Environment
FROM rust:slim-buster AS builder

WORKDIR /usr/src/app

# Copy the manifest files first to leverage Docker layer caching
COPY Cargo.toml Cargo.lock ./

# Create a dummy main.rs to build and cache the dependencies
RUN mkdir src && echo "fn main() {}" > src/main.rs
RUN cargo build --release
RUN rm -rf src

# Copy the actual source code
COPY . .

# Touch the source files to invalidate the dummy build and compile the real application
RUN find . -name "*.rs" -exec touch {} +
RUN cargo build --release


# Stage 2: Production Environment
FROM debian:buster-slim

# Install CA certificates (often required for secure external API/network calls)
RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*

# Security Best Practice: Create a non-root user to run the application
RUN useradd -m -U -s /bin/false appuser
USER appuser

WORKDIR /app

# Copy the compiled binary from the builder stage
COPY --from=builder /usr/src/app/target/release/api ./api

# Expose the default port for actix-web
EXPOSE 8080

# Run the binary
CMD ["./api"]
