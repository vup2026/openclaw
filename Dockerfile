FROM docker.io/library/node:24-bookworm

WORKDIR /app

RUN apt-get update && apt-get install -y tini ca-certificates curl git && rm -rf /var/lib/apt/lists/*

RUN corepack enable

COPY package.json pnpm-lock.yaml pnpm-workspace.yaml .npmrc ./
COPY openclaw.mjs ./
COPY ui/package.json ./ui/package.json
COPY patches ./patches
COPY scripts ./scripts
COPY packages ./packages
COPY extensions ./extensions

RUN NODE_OPTIONS=--max-old-space-size=2048 pnpm install --frozen-lockfile \
    --config.supportedArchitectures.os=linux \
    --config.supportedArchitectures.libc=glibc

COPY . .

RUN pnpm build:docker || true
RUN pnpm ui:build || true

RUN ln -sf /app/openclaw.mjs /usr/local/bin/openclaw \
 && chmod 755 /app/openclaw.mjs

ENV NODE_ENV=production
ENV PORT=18789

EXPOSE 18789

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=5 \
  CMD node -e "fetch('http://0.0.0.0:18789/healthz').then((r)=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"

ENTRYPOINT ["tini", "-s", "--"]
CMD ["node", "openclaw.mjs", "gateway", "--bind", "lan"]
