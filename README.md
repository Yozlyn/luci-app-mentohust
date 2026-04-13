# luci-app-mentohust

OpenWrt LuCI 界面支持 MentoHUST 802.1x 认证客户端。

## 编译信息
- 手动构建 (Manual Build) with Cache
- SDK: OpenWrt 23.05.5

## 本地编译环境

建议：
- 仓库放在 WSL/Linux 文件系统里，不要放在Windows环境，I/O 会稳定很多。
- 首次进入新环境时先装依赖，再下载 SDK 进行构建。
- 本地脚本会缓存 SDK 与 `dl` 下载目录，重复编译不会每次都重新拉全量依赖。

### 1. 安装依赖

```bash
bash scripts/setup-wsl-build-env.sh
```

### 2. 本地编译

```bash
bash scripts/build-local.sh
```

编译完成后：
- SDK 会展开到仓库内的 `sdk/`
- SDK 压缩包和下载缓存会放到 `./.cache/`
- 最终生成的 `.ipk` 会复制到 `dist/`
- 构建日志会写到 `build-logs/local-build.log`

### 3. 并发策略

`scripts/build-local.sh` 会根据宿主机 CPU 和内存决定默认并发数：
- 预留约 3 GiB 给系统和其它进程
- 按每 1.5 GiB 估算一个编译并发
- 默认上限 16 线程

指定构建：

```bash
JOBS=12 bash scripts/build-local.sh
```

构建时刷新 SDK 或跳过 feeds 更新：

```bash
bash scripts/build-local.sh --refresh-sdk
bash scripts/build-local.sh --skip-feeds
```