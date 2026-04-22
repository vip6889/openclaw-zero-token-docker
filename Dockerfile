# Dockerfile
FROM node:22-bookworm AS builder

WORKDIR /app

# 安装所有必要的构建工具
RUN apt-get update && apt-get install -y \
    python3 make g++ git cmake pkg-config curl wget \
    python3-pip python3-setuptools libvips-dev \
    && rm -rf /var/lib/apt/lists/*

# 安装pnpm
RUN npm install -g pnpm@latest

# 复制依赖定义
COPY package*.json ./
COPY pnpm-lock.yaml ./

# 在资源充足的云端，可以尝试完整安装（不使用 --ignore-scripts）
RUN pnpm install --frozen-lockfile

# 复制源码并构建
COPY . .
RUN pnpm build

# 生产运行镜像
FROM node:22-bookworm-slim
WORKDIR /app

RUN apt-get update && apt-get install -y \
    ca-certificates libvips42 \
    && rm -rf /var/lib/apt/lists/*

RUN npm install -g pnpm@latest

RUN groupadd -g 1001 -S nodejs && \
    useradd -r -u 1001 -g nodejs nodejs

COPY --from=builder --chown=nodejs:nodejs /app/package*.json ./
COPY --from=builder --chown=nodejs:nodejs /app/pnpm-lock.yaml ./
COPY --from=builder --chown=nodejs:nodejs /app/dist ./dist
COPY --from=builder --chown=nodejs:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=nodejs:nodejs /app/public ./public
COPY --from=builder --chown=nodejs:nodejs /app/*.json ./
COPY --from=builder --chown=nodejs:nodejs /app/*.js ./
COPY --from=builder --chown=nodejs:nodejs /app/scripts ./scripts

USER nodejs
EXPOSE 3000
CMD ["node", "dist/server.js"]
