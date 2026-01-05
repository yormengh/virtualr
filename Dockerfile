# Multi-stage Dockerfile for building and serving the Vite React app

# --- Build stage ---
FROM node:18-bullseye-slim AS builder
WORKDIR /app
ENV NODE_ENV=development

# Install dependencies (use package-lock if present). We need devDeps for the build (vite/rollup).
COPY package.json package-lock.json* ./
RUN if [ -f package-lock.json ]; then \
  npm ci --prefer-offline --no-audit --progress=false; \
  else \
  npm install --prefer-offline --no-audit --progress=false; \
  fi

COPY . .
RUN npm run build


# --- Production stage ---
FROM nginx:stable-alpine AS runner

# Copy built assets
COPY --from=builder /app/dist /usr/share/nginx/html

# Replace default nginx config with simple SPA fallback for Vite-built app
RUN rm /etc/nginx/conf.d/default.conf && \
  cat > /etc/nginx/conf.d/default.conf <<'NGINX_CONF'
server {
		listen 8080;
		server_name _;
		root /usr/share/nginx/html;
		index index.html;

		location / {
			try_files $uri $uri/ /index.html;
		}
}
NGINX_CONF

EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]