# Dockerfile.no-build
FROM node:22-bookworm

WORKDIR /app

# 安装最少的依赖
RUN apt-get update && apt-get install -y \
    python3 \
    make \
    g++ \
    git \
    && rm -rf /var/lib/apt/lists/*

# 安装pnpm
RUN npm install -g pnpm@latest

# 复制项目文件
COPY . .

# 设置关键环境变量，跳过所有原生模块编译
ENV npm_config_optional=false
ENV npm_config_build_from_source=false
ENV SHARP_IGNORE_GLOBAL_LIBVIPS=1
ENV SKIP_KOFFI_BUILD=1
ENV SKIP_LLAMA_CPP_BUILD=1
ENV SKIP_ROLLDOWN_BUILD=1

# 安装依赖（强制跳过所有脚本）
RUN pnpm install --ignore-scripts --frozen-lockfile

# 暴露端口
EXPOSE 3000

# 直接运行开发服务器
CMD ["pnpm", "start"]
