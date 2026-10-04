/// Typed Gleam wrappers for AtomVM ESP32-specific APIs (`esp` module).
///
/// Source: [`libs/avm_esp32/src/esp.erl`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/esp.erl).
/// Docs: [Module esp](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/esp.html)
/// (prefer [release-0.7](https://doc.atomvm.org/release-0.7/) guides when available).
import gleam/option.{type Option}

/// Errors from ESP NIFs and helpers.
pub type Error {
  Failed
  NotSupported
  Badarg
  Timeout
  NotFound
  Other(String)
}

/// Why the chip last restarted.
///
/// See [esp_reset_reason()](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/esp.html#esp-reset-reason).
pub type ResetReason {
  EspRstUnknown
  EspRstPoweron
  EspRstExt
  EspRstSw
  EspRstPanic
  EspRstIntWdt
  EspRstTaskWdt
  EspRstWdt
  EspRstDeepsleep
  EspRstBrownout
  EspRstSdio
  EspRstUsb
  EspRstJtag
  EspRstEfuse
  EspRstPwrGlitch
  EspRstCpuLockup
  OtherReason(String)
}

/// Cause of the last wakeup from sleep.
///
/// See [esp_wakeup_cause()](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/esp.html#esp-wakeup-cause).
pub type WakeupCause {
  SleepWakeupExt0
  SleepWakeupExt1
  SleepWakeupTimer
  SleepWakeupTouchpad
  SleepWakeupUlp
  SleepWakeupGpio
  SleepWakeupUart
  SleepWakeupWifi
  SleepWakeupCocpu
  SleepWakeupCocpuTrapTrig
  SleepWakeupBt
  OtherCause(String)
}

/// Network interface for [`get_mac`](#get_mac).
///
/// See [interface()](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/esp.html#interface).
pub type Interface {
  WifiSta
  WifiSoftap
}

/// One flash partition from [`partition_list`](#partition_list).
///
/// Upstream props are always `[]` in AtomVM 0.7 and are omitted here.
///
/// See [esp_partition()](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/esp.html#esp-partition).
pub type Partition {
  Partition(
    id: BitArray,
    partition_type: Int,
    subtype: Int,
    address: Int,
    size: Int,
  )
}

/// Filesystem type for [`mount`](#mount). Only `fat` is supported in 0.7.
pub type Filesystem {
  Fat
}

/// One mount option for SDMMC / SDSPI.
///
/// See [mount_options()](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/esp.html#mount-options).
pub type MountOption {
  Clk(Int)
  Cmd(Int)
  D0(Int)
  D1(Int)
  D2(Int)
  D3(Int)
  Width(Int)
  SpiHost(String)
  Cs(Int)
  Cd(Int)
}

/// Opaque handle for a mounted filesystem resource.
///
/// See [mounted_fs()](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/esp.html#mounted-fs).
pub type MountedFs

/// Task watchdog configuration: timeout (ms), idle-core mask, trigger panic.
///
/// See [task_wdt_config()](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/esp.html#task-wdt-config).
pub type TaskWdtConfig {
  TaskWdtConfig(timeout_ms: Int, idle_core_mask: Int, trigger_panic: Bool)
}

/// Opaque handle from [`task_wdt_add_user`](#task_wdt_add_user).
///
/// See [task_wdt_user_handle()](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/esp.html#task-wdt-user-handle).
pub type TaskWdtUserHandle

/// Format an `Error` for logging.
pub fn error_to_string(error: Error) -> String {
  case error {
    Failed -> "error"
    NotSupported -> "not_supported"
    Badarg -> "badarg"
    Timeout -> "timeout"
    NotFound -> "not_found"
    Other(reason) -> reason
  }
}

/// Read a binary from NVS, or `None` when the key is absent.
///
/// `namespace` and `key` are turned into Erlang atoms.
///
/// See [`esp:nvs_get_binary/2`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/esp.html#nvs-get-binary-2).
@external(erlang, "atomvm_gleam_esp_ffi", "nvs_get_binary")
pub fn nvs_get_binary(
  namespace: String,
  key: String,
) -> Result(Option(BitArray), Error)

/// Fetch a binary from NVS (`{ok, Value}` / `{error, not_found}`).
///
/// See [`esp:nvs_fetch_binary/2`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/esp.html#nvs-fetch-binary-2).
@external(erlang, "atomvm_gleam_esp_ffi", "nvs_fetch_binary")
pub fn nvs_fetch_binary(
  namespace: String,
  key: String,
) -> Result(BitArray, Error)

/// Write a binary to NVS (`esp:nvs_put_binary/3`).
///
/// See [`esp:nvs_put_binary/3`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/esp.html#nvs-put-binary-3).
@external(erlang, "atomvm_gleam_esp_ffi", "nvs_put_binary")
pub fn nvs_put_binary(
  namespace: String,
  key: String,
  value: BitArray,
) -> Result(Nil, Error)

/// Erase a key from NVS.
///
/// See [`esp:nvs_erase_key/2`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/esp.html#nvs-erase-key-2).
@external(erlang, "atomvm_gleam_esp_ffi", "nvs_erase_key")
pub fn nvs_erase_key(namespace: String, key: String) -> Result(Nil, Error)

/// Erase all keys in an NVS namespace.
///
/// See [`esp:nvs_erase_all/1`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/esp.html#nvs-erase-all-1).
@external(erlang, "atomvm_gleam_esp_ffi", "nvs_erase_all")
pub fn nvs_erase_all(namespace: String) -> Result(Nil, Error)

/// Reformat the entire NVS partition. Deletes all NVS data.
///
/// See [`esp:nvs_reformat/0`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/esp.html#nvs-reformat-0).
@external(erlang, "atomvm_gleam_esp_ffi", "nvs_reformat")
pub fn nvs_reformat() -> Result(Nil, Error)

/// Factory-programmed default MAC address (6 bytes).
///
/// See [`esp:get_default_mac/0`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/esp.html#get-default-mac-0).
@external(erlang, "atomvm_gleam_esp_ffi", "get_default_mac")
pub fn get_default_mac() -> Result(BitArray, Error)

/// MAC address of a network interface (6 bytes).
///
/// See [`esp:get_mac/1`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/esp.html#get-mac-1).
@external(erlang, "atomvm_gleam_esp_ffi", "get_mac")
pub fn get_mac(interface: Interface) -> Result(BitArray, Error)

/// Reason for the last restart.
///
/// See [`esp:reset_reason/0`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/esp.html#reset-reason-0).
@external(erlang, "atomvm_gleam_esp_ffi", "reset_reason")
pub fn reset_reason() -> ResetReason

/// Restart the ESP device. Does not return on success.
///
/// See [`esp:restart/0`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/esp.html#restart-0).
@external(erlang, "atomvm_gleam_esp_ffi", "restart")
pub fn restart() -> Nil

/// Chip clock frequency in Hz.
///
/// See [`esp:freq_hz/0`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/esp.html#freq-hz-0).
@external(erlang, "atomvm_gleam_esp_ffi", "freq_hz")
pub fn freq_hz() -> Result(Int, Error)

/// Enable GPIO wake from light sleep (after `gpio:wakeup_enable/2`).
///
/// See [`esp:sleep_enable_gpio_wakeup/0`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/esp.html#sleep-enable-gpio-wakeup-0).
@external(erlang, "atomvm_gleam_esp_ffi", "sleep_enable_gpio_wakeup")
pub fn sleep_enable_gpio_wakeup() -> Result(Nil, Error)

/// Enter light sleep until a configured wake source fires.
///
/// See [`esp:light_sleep/0`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/esp.html#light-sleep-0).
@external(erlang, "atomvm_gleam_esp_ffi", "light_sleep")
pub fn light_sleep() -> Result(Nil, Error)

/// Enter deep sleep. Never returns; the program restarts on wake.
///
/// See [`esp:deep_sleep/0`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/esp.html#deep-sleep-0).
@external(erlang, "atomvm_gleam_esp_ffi", "deep_sleep")
pub fn deep_sleep() -> Nil

/// Enter deep sleep for `sleep_ms` milliseconds. Never returns.
///
/// See [`esp:deep_sleep/1`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/esp.html#deep-sleep-1).
@external(erlang, "atomvm_gleam_esp_ffi", "deep_sleep_ms")
pub fn deep_sleep_ms(sleep_ms: Int) -> Nil

/// Cause of the last wakeup, or `None` when undefined.
///
/// See [`esp:sleep_get_wakeup_cause/0`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/esp.html#sleep-get-wakeup-cause-0).
@external(erlang, "atomvm_gleam_esp_ffi", "sleep_get_wakeup_cause")
pub fn sleep_get_wakeup_cause() -> Result(Option(WakeupCause), Error)

/// Enable ext0 deep-sleep wakeup on `pin` at `level` (`0` or `1`).
///
/// See [`esp:sleep_enable_ext0_wakeup/2`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/esp.html#sleep-enable-ext0-wakeup-2).
@external(erlang, "atomvm_gleam_esp_ffi", "sleep_enable_ext0_wakeup")
pub fn sleep_enable_ext0_wakeup(pin: Int, level: Int) -> Result(Nil, Error)

/// Enable ext1 deep-sleep wakeup IOs (`mask` bitset, `mode` 0..3).
///
/// See [`esp:sleep_enable_ext1_wakeup_io/2`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/esp.html#sleep-enable-ext1-wakeup-io-2).
@external(erlang, "atomvm_gleam_esp_ffi", "sleep_enable_ext1_wakeup_io")
pub fn sleep_enable_ext1_wakeup_io(mask: Int, mode: Int) -> Result(Nil, Error)

/// Disable previously configured ext1 wakeup IOs (`mask` bitset).
///
/// See [`esp:sleep_disable_ext1_wakeup_io/1`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/esp.html#sleep-disable-ext1-wakeup-io-1).
@external(erlang, "atomvm_gleam_esp_ffi", "sleep_disable_ext1_wakeup_io")
pub fn sleep_disable_ext1_wakeup_io(mask: Int) -> Result(Nil, Error)

/// Enable GPIO deep-sleep wakeup (`mask` bitset, `mode` 0..1).
///
/// See [`esp:deep_sleep_enable_gpio_wakeup/2`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/esp.html#deep-sleep-enable-gpio-wakeup-2).
@external(erlang, "atomvm_gleam_esp_ffi", "deep_sleep_enable_gpio_wakeup")
pub fn deep_sleep_enable_gpio_wakeup(mask: Int, mode: Int) -> Result(Nil, Error)

/// Enable ULP wakeup from deep sleep.
///
/// See [`esp:sleep_enable_ulp_wakeup/0`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/esp.html#sleep-enable-ulp-wakeup-0).
@external(erlang, "atomvm_gleam_esp_ffi", "sleep_enable_ulp_wakeup")
pub fn sleep_enable_ulp_wakeup() -> Result(Nil, Error)

/// Enable timer wakeup from light sleep after `sleep_us` microseconds.
///
/// See [`esp:sleep_enable_timer_wakeup/1`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/esp.html#sleep-enable-timer-wakeup-1).
@external(erlang, "atomvm_gleam_esp_ffi", "sleep_enable_timer_wakeup")
pub fn sleep_enable_timer_wakeup(sleep_us: Int) -> Result(Nil, Error)

/// List flash partitions.
///
/// See [`esp:partition_list/0`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/esp.html#partition-list-0).
@external(erlang, "atomvm_gleam_esp_ffi", "partition_list")
pub fn partition_list() -> Result(List(Partition), Error)

/// Read `size` bytes from partition `id` at `offset`.
///
/// See [`esp:partition_read/3`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/esp.html#partition-read-3).
@external(erlang, "atomvm_gleam_esp_ffi", "partition_read")
pub fn partition_read(
  id: BitArray,
  offset: Int,
  size: Int,
) -> Result(BitArray, Error)

/// Write `data` to partition `id` at `offset`.
///
/// See [`esp:partition_write/3`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/esp.html#partition-write-3).
@external(erlang, "atomvm_gleam_esp_ffi", "partition_write")
pub fn partition_write(
  id: BitArray,
  offset: Int,
  data: BitArray,
) -> Result(Nil, Error)

/// Erase from `offset` to the end of partition `id`.
///
/// See [`esp:partition_erase_range/2`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/esp.html#partition-erase-range-2).
@external(erlang, "atomvm_gleam_esp_ffi", "partition_erase_range")
pub fn partition_erase_range(id: BitArray, offset: Int) -> Result(Nil, Error)

/// Erase `size` bytes of partition `id` starting at `offset`.
///
/// See [`esp:partition_erase_range/3`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/esp.html#partition-erase-range-3).
@external(erlang, "atomvm_gleam_esp_ffi", "partition_erase_range_size")
pub fn partition_erase_range_size(
  id: BitArray,
  offset: Int,
  size: Int,
) -> Result(Nil, Error)

/// Binary currently stored in RTC slow memory.
///
/// Must only be called after a successful [`rtc_slow_set_binary`](#rtc_slow_set_binary).
///
/// See [`esp:rtc_slow_get_binary/0`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/esp.html#rtc-slow-get-binary-0).
@external(erlang, "atomvm_gleam_esp_ffi", "rtc_slow_get_binary")
pub fn rtc_slow_get_binary() -> Result(BitArray, Error)

/// Store a binary in RTC slow memory (survives reset and deep sleep).
///
/// See [`esp:rtc_slow_set_binary/1`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/esp.html#rtc-slow-set-binary-1).
@external(erlang, "atomvm_gleam_esp_ffi", "rtc_slow_set_binary")
pub fn rtc_slow_set_binary(bin: BitArray) -> Result(Nil, Error)

/// Mount a filesystem and return a handle for [`umount`](#umount).
///
/// See [`esp:mount/4`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/esp.html#mount-4).
pub fn mount(
  source: String,
  target: String,
  filesystem: Filesystem,
  options: List(MountOption),
) -> Result(MountedFs, Error) {
  mount_ffi(source, target, filesystem, options)
}

@external(erlang, "atomvm_gleam_esp_ffi", "mount")
fn mount_ffi(
  source: String,
  target: String,
  filesystem: Filesystem,
  options: List(MountOption),
) -> Result(MountedFs, Error)

/// Unmount a filesystem previously returned by [`mount`](#mount).
///
/// See [`esp:umount/1`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/esp.html#umount-1).
@external(erlang, "atomvm_gleam_esp_ffi", "umount")
pub fn umount(mounted: MountedFs) -> Result(Nil, Error)

/// Initialize the task watchdog timer.
///
/// See [`esp:task_wdt_init/1`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/esp.html#task-wdt-init-1).
pub fn task_wdt_init(config: TaskWdtConfig) -> Result(Nil, Error) {
  let TaskWdtConfig(timeout_ms:, idle_core_mask:, trigger_panic:) = config
  task_wdt_init_ffi(timeout_ms, idle_core_mask, trigger_panic)
}

@external(erlang, "atomvm_gleam_esp_ffi", "task_wdt_init")
fn task_wdt_init_ffi(
  timeout_ms: Int,
  idle_core_mask: Int,
  trigger_panic: Bool,
) -> Result(Nil, Error)

/// Update the task watchdog timer configuration.
///
/// See [`esp:task_wdt_reconfigure/1`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/esp.html#task-wdt-reconfigure-1).
pub fn task_wdt_reconfigure(config: TaskWdtConfig) -> Result(Nil, Error) {
  let TaskWdtConfig(timeout_ms:, idle_core_mask:, trigger_panic:) = config
  task_wdt_reconfigure_ffi(timeout_ms, idle_core_mask, trigger_panic)
}

@external(erlang, "atomvm_gleam_esp_ffi", "task_wdt_reconfigure")
fn task_wdt_reconfigure_ffi(
  timeout_ms: Int,
  idle_core_mask: Int,
  trigger_panic: Bool,
) -> Result(Nil, Error)

/// Deinitialize the task watchdog timer.
///
/// See [`esp:task_wdt_deinit/0`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/esp.html#task-wdt-deinit-0).
@external(erlang, "atomvm_gleam_esp_ffi", "task_wdt_deinit")
pub fn task_wdt_deinit() -> Result(Nil, Error)

/// Register a task watchdog user; returns a handle for reset/delete.
///
/// See [`esp:task_wdt_add_user/1`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/esp.html#task-wdt-add-user-1).
@external(erlang, "atomvm_gleam_esp_ffi", "task_wdt_add_user")
pub fn task_wdt_add_user(username: String) -> Result(TaskWdtUserHandle, Error)

/// Reset the timer for a previously registered watchdog user.
///
/// See [`esp:task_wdt_reset_user/1`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/esp.html#task-wdt-reset-user-1).
@external(erlang, "atomvm_gleam_esp_ffi", "task_wdt_reset_user")
pub fn task_wdt_reset_user(handle: TaskWdtUserHandle) -> Result(Nil, Error)

/// Unsubscribe a watchdog user.
///
/// See [`esp:task_wdt_delete_user/1`](https://doc.atomvm.org/latest/apidocs/erlang/eavmlib/esp.html#task-wdt-delete-user-1).
@external(erlang, "atomvm_gleam_esp_ffi", "task_wdt_delete_user")
pub fn task_wdt_delete_user(handle: TaskWdtUserHandle) -> Result(Nil, Error)
