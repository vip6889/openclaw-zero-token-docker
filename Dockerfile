# 使用Node.js 24.13.0 Alpine版本（GitHub Actions强制要求）
FROM node:24.13.0-alpine AS builder

# 设置工作目录
WORKDIR /app

# 安装必要的系统依赖（最小化安装）
RUN apk add --no-cache git python3 make g++

# 明确指定pnpm版本并配置官方镜像源
RUN npm install -g pnpm@latest && \
    pnpm config set registry https://registry.npmjs.org/

# 清理缓存并安装依赖（关键：移除--frozen-lockfile）
RUN pnpm cache clean --force && \
    pnpm install

# 复制源码并构建
COPY . .
RUN pnpm run build && pnpm ui:build

# ----------------------------------------------------
# 运行时镜像（保持最小化）
FROM node:24.13.0-alpine

WORKDIR /app

# 从构建阶段复制编译好的文件
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/node_modules ./node_modules

# 暴露端口
EXPOSE 3000

# 启动命令
CMD ["node", "dist/index.mjs"]
