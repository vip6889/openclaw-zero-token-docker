# 使用完整的Debian镜像，避免Alpine的兼容性问题
FROM node:22-bookworm AS builder

WORKDIR /app

# 安装构建依赖
RUN apt-get update && apt-get install -y \
    python3 \
    make \
    g++ \
    git \
    cmake \
    pkg-config \
    curl \
    wget \
    && rm -rf /var/lib/apt/lists/*

# 安装pnpm
RUN npm install -g pnpm@latest

# 复制依赖文件
COPY package*.json ./
COPY pnpm-lock.yaml ./

# 设置环境变量优化构建
ENV npm_config_optional=false
ENV npm_config_build_from_source=false
ENV SHARP_IGNORE_GLOBAL_LIBVIPS=1

# 安装依赖
RUN pnpm install --frozen-lockfile

# 复制源代码并构建
COPY . .
RUN pnpm build

# 生产运行镜像
FROM node:22-bookworm-slim
WORKDIR /app

# 安装必要的运行时库
RUN apt-get update && apt-get install -y \
    ca-certificates \
    libvips42 \
    && rm -rf /var/lib/apt/lists/*

# 安装pnpm
RUN npm install -g pnpm@latest

# 创建非root用户 - 简化版本，避免复杂的用户创建
RUN groupadd -g 1001 appgroup && \
    useradd -u 1001 -g appgroup -m -s /bin/bash appuser

# 从构建阶段复制文件
COPY --from=builder --chown=appuser:appgroup /app/package*.json ./
COPY --from=builder --chown=appuser:appgroup /app/pnpm-lock.yaml ./
COPY --from=builder --chown=appuser:appgroup /app/dist ./dist
COPY --from=builder --chown=appuser:appgroup /app/node_modules ./node_modules

# 复制必要的运行时文件
COPY --from=builder --chown=appuser:appgroup /app/public ./public
COPY --from=builder --chown=appuser:appgroup /app/*.json ./
COPY --from=builder --chown=appuser:appgroup /app/*.js ./
COPY --from=builder --chown=appuser:appgroup /app/*.md ./
COPY --from=builder --chown=appuser:appgroup /app/scripts ./scripts

# 设置权限
RUN chown -R appuser:appgroup /app

# 切换到非root用户
USER appuser

# 暴露端口
EXPOSE 3000

# 健康检查
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', (r) => {if (r.statusCode !== 200) throw new Error()})" || exit 1

# 启动命令
CMD ["node", "dist/server.js"]
