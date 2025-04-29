# Stage 1: Clone submodules
FROM alpine/git AS git-clone

WORKDIR /src
COPY . .

# Initialize and shallow clone submodules
RUN git submodule update --init --recursive --depth=1

# Stage 2: Build the Hugo site
FROM ghcr.io/gohugoio/hugo:v0.147.0 AS builder

WORKDIR /src

# Accept an optional build argument
ARG HUGO_BASEURL=https://behzadan.com

# Copy code (with updated submodules) from git-clone stage
COPY --from=git-clone --chown=1000:1000 /src .

# Use the baseURL passed at build-time (or default)
RUN hugo --gc --minify --baseURL "${HUGO_BASEURL}"

# Stage 3: Serve with nginx
FROM nginx:alpine

COPY --from=builder /src/public /usr/share/nginx/html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]

