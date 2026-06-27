# ─────────────────────────────────────────────
#  Dockerfile — Static Site (nginx:alpine)
#  Serves HTML/CSS from a lightweight container
# ─────────────────────────────────────────────

FROM nginx:alpine

# Remove default nginx welcome page
RUN rm -rf /usr/share/nginx/html/*

# Copy our site into nginx's web root
COPY app/ /usr/share/nginx/html/

# Copy custom nginx config
COPY docker/nginx.conf /etc/nginx/conf.d/default.conf

# Expose port 80
EXPOSE 80

# Health check — Azure Container Apps uses this
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost:80/ || exit 1

CMD ["nginx", "-g", "daemon off;"]
