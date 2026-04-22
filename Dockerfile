# 使用稳定、工具链完整的 Debian 基础镜像
FROM node:22-bookworm

WORKDIR /app

# 1. 安装最基础的编译工具（为潜在的原生模块回退做准备）
RUN apt-get update && apt-get install -y \
    python3 \
    make \
    g++ \
    git \
    && rm -rf /var/lib/apt/lists/*

# 2. 安装 pnpm
RUN npm install -g pnpm@latest

# 3. 复制项目所有文件到容器
COPY . .

# 4. 设置关键环境变量，强制跳过所有原生模块的编译
ENV npm_config_optional=false
ENV npm_config_build_from_source=false
ENV SHARP_IGNORE_GLOBAL_LIBVIPS=1
ENV SKIP_KOFFI_BUILD=1
ENV SKIP_LLAMA_CPP_BUILD=1
ENV SKIP_ROLLDOWN_BUILD=1
# 此变量可告知某些工具链跳过特定平台的编译
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true

# 5. 安装项目依赖，并忽略所有安装后脚本（--ignore-scripts）
# 使用 --frozen-lockfile 确保依赖版本与 lock 文件一致
RUN pnpm install --frozen-lockfile --ignore-scripts

# 6. 暴露应用端口
EXPOSE 3000

# 7. 以开发模式启动应用（核心：跳过 pnpm build）
CMD ["pnpm", "start"]
