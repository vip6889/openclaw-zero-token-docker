# 使用Node.js 24.13.0 Alpine版本（兼容GitHub Actions最新要求）
FROM node:24.13.0-alpine AS builder

# 设置工作目录
WORKDIR /app

# 安装系统依赖（最小化安装）
RUN apk add --no-cache git python3 make g++

# 复制package文件并安装依赖
COPY package.json pnpm-lock.yaml* ./

# 安装pnpm并配置官方镜像源（避免淘宝镜像同步问题）
RUN npm install -g pnpm && \
    pnpm config set registry https://registry.npmjs.org/

# 清理缓存并安装依赖（更可靠的安装方式）
RUN pnpm cache clean --force && \
    pnpm install

# 复制源码并构建
COPY . .
# 执行构建命令
RUN pnpm run build && pnpm ui:build

# ----------------------------------------------------
# 第二阶段：运行时镜像（保持镜像尽可能小）
FROM node:24.13.0-alpine

WORKDIR /app

# 从构建阶段复制编译好的文件
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/node_modules ./node_modules

# 暴露端口（根据项目实际端口）
EXPOSE 3000

# 启动命令
CMD ["node", "dist/index.mjs"]
