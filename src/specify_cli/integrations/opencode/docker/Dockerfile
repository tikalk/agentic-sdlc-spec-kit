FROM node:24-alpine

WORKDIR /app

RUN apk add --no-cache git curl

# Download and extract OpenCode binary for Linux
RUN apk add --no-cache tar && \
    OPENCODE_VERSION=1.14.37 && \
    ARCH=$(uname -m | sed 's/x86_64/x64/;s/aarch64/arm64/') && \
    cd /tmp && \
    curl -L https://github.com/anomalyco/opencode/releases/download/v${OPENCODE_VERSION}/opencode-linux-${ARCH}-musl.tar.gz \
      -o opencode.tar.gz && \
    tar -xzf opencode.tar.gz && \
    mv opencode /usr/local/bin/ && \
    chmod +x /usr/local/bin/opencode && \
    rm opencode.tar.gz

RUN addgroup -g 2000 opencode && \
    adduser -D -u 2000 -G opencode opencode

RUN mkdir -p /workspace && \
    chown -R opencode:opencode /workspace /app

USER opencode

EXPOSE 3000

CMD ["opencode", "serve", "--hostname", "0.0.0.0", "--port", "3000"]
