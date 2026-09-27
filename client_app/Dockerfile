# =============================================================
# Stage 1: Build Flutter Web Release
# =============================================================
FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

# Copy dependency manifests first for Docker layer caching
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Copy source files
COPY . .

# Pass API URL at build time (Defaults to production)
ARG API_URL=https://api.looplyn.tech/api/v1
ENV API_URL=$API_URL

# Compile optimized web bundle
RUN flutter build web --release --dart-define=API_URL=$API_URL

# =============================================================
# Stage 2: Serve via Lightweight Nginx Alpine
# =============================================================
FROM nginx:alpine

# Clean default nginx website
RUN rm -rf /usr/share/nginx/html/*

# Copy compiled Flutter web assets
COPY --from=build /app/build/web /usr/share/nginx/html

# Copy custom Nginx configuration with SPA routing
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:80/ || exit 1

CMD ["nginx", "-g", "daemon off;"]
