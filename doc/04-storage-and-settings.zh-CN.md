# 存储与配置

## 文档目的

说明数据存在哪里、配置和密钥如何管理、日志如何落盘，便于后续扩展与排障。

## 持久化（SQLite）

### 数据库路径

`DatabaseManager` 会按优先级尝试：

- 首选：`~/Library/Application Support/WeChatVoiceRecorder/db.sqlite3`
- 兜底：`~/Documents/WeChatVoiceRecorder/db.sqlite3`
- 最后手段：临时目录下 `.../tmp/WeChatVoiceRecorder/db.sqlite3`

### 表结构

表 `meeting_tasks` 保存完整任务状态：

- 标识：`id`、`recording_id`、`created_at`、`title`
- 文件/云端：`local_file_path`、`oss_url`、`tingwu_task_id`
- 状态：`status`、`last_error`
- 输出：`raw_response`、`transcript`、`summary`、`key_points`、`action_items`

写入采用 `insert(or: .replace)`，以 `id` 为主键。

### 历史列表

`HistoryStore` 在初始化时加载任务，并提供：

- `refresh()`：按 `created_at` 倒序重新拉取
- `deleteTask(at:)`：按 UUID 删除任务记录

## 配置（UserDefaults）

`SettingsStore` 通过 UserDefaults 保存非密钥配置：

- OSS：region/bucket/prefix/endpoint
- 听悟：appKey、language
- 功能开关：summary/key points/action items/role split
- 日志：verbose 开关

## 密钥（Keychain）

`KeychainHelper` 使用 service：

- `com.wechatvoicerecorder.secrets`

accounts：

- `aliyun_ak_id`
- `aliyun_ak_secret`

`SettingsStore` 不会在 UI 层暴露明文密钥，只提供：

- `hasAccessKeyId` / `hasAccessKeySecret`
- save/read/clear 方法

## 日志

`SettingsStore.log(_:)`：

- 永远输出到控制台。
- 落盘条件：
  - 开启 verbose，或
  - message 包含 `error` / `failed` / `test`

日志文件路径：

- `~/Library/Application Support/WeChatVoiceRecorder/Logs/app.log`

设置页提供：

- 展示日志路径
- 打开日志目录
- 清空日志

