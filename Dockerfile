# 1. 使用 Node.js 22 Alpine 版本（体积小，适合你的设备）
FROM node:22-alpine AS builder

# 2. 设置工作目录
WORKDIR /app

# 3. 安装系统依赖（根据指南需要 git 和 chrome 相关依赖，虽然运行时可能不需要完整 chrome，但构建时可能需要）
# 这里我们只安装构建所需的最小依赖
RUN apk add --no-cache git python3 make g++

# 4. 复制 package 文件并安装依赖
# 利用 Docker 缓存层，只有 package.json 变动时才重新安装
COPY package.json pnpm-lock.yaml* ./
# 安装 pnpm
RUN npm install -g pnpm
# 设置淘宝镜像源（根据你提供的网页解析内容，使用 npmmirror 加速）
RUN pnpm config set registry https://registry.npmmirror.com
# 安装依赖
RUN pnpm install --frozen-lockfile

# 5. 复制源码并构建
COPY . .
# 根据安装指南执行构建命令
RUN pnpm run build && pnpm ui:build

# ----------------------------------------------------
# 第二阶段：运行时镜像（保持镜像尽可能小）
FROM node:22-alpine

WORKDIR /app

# 安装运行时必要依赖（如需要）
# RUN apk add --no-cache ...

# 从构建阶段复制编译好的文件
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/node_modules ./node_modules

# 暴露端口（根据项目实际端口，假设是 3000 或指南中提到的 3001）
EXPOSE 3000

# 启动命令（根据指南，入口文件是 dist/index.mjs）
CMD ["node", "dist/index.mjs"]
