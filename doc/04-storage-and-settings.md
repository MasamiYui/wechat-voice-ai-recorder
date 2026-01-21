# Storage and Settings

## Purpose

Explain where data is stored, how settings and secrets are handled, and how logs work.

## Persistence (SQLite)

### Database location

`DatabaseManager` attempts to place the DB at:

- Preferred: `~/Library/Application Support/WeChatVoiceRecorder/db.sqlite3`
- Fallback: `~/Documents/WeChatVoiceRecorder/db.sqlite3`
- Last resort: `~/Library/Caches/.../tmp/WeChatVoiceRecorder/db.sqlite3` (temporary directory)

### Schema

Table `meeting_tasks` stores the full task state:

- Identifiers: `id`, `recording_id`, `created_at`, `title`
- Files and cloud: `local_file_path`, `oss_url`, `tingwu_task_id`
- Status: `status`, `last_error`
- Outputs: `raw_response`, `transcript`, `summary`, `key_points`, `action_items`

Writes use `insert(or: .replace)` keyed by `id`.

### HistoryStore

`HistoryStore` loads tasks on init and exposes:

- `refresh()` re-fetches tasks ordered by `created_at` descending.
- `deleteTask(at:)` deletes rows by UUID.

## Settings (UserDefaults)

`SettingsStore` persists non-secret configuration via UserDefaults:

- OSS: region/bucket/prefix/endpoint
- Tingwu: appKey, language
- Feature toggles: summary/key points/action items/role split
- Logging: verbose logging flag

## Secrets (Keychain)

`KeychainHelper` stores secrets under service:

- `com.wechatvoicerecorder.secrets`

Accounts used:

- `aliyun_ak_id`
- `aliyun_ak_secret`

`SettingsStore` never exposes secrets in clear text to the UI; it only provides:

- `hasAccessKeyId` / `hasAccessKeySecret`
- methods to save/read/clear

## Logs

`SettingsStore.log(_:)`:

- Always prints to stdout.
- Writes to a file only when:
  - verbose logging enabled, or
  - message contains `error` / `failed` / `test`

Log file:

- `~/Library/Application Support/WeChatVoiceRecorder/Logs/app.log`

Settings UI provides:

- show current log path
- open log folder
- clear log

