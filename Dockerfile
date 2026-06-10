FROM docker.io/library/node:24-bookworm

WORKDIR /app

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

HEALTHCHECK --interval=3m --timeout=10s --start-period=15s --retries=3 \
  CMD node -e "fetch('http://127.0.0.1:18789/healthz').then((r)=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"

ENTRYPOINT ["tini", "-s", "--"]
CMD ["node", "openclaw.mjs", "gateway"]
  
