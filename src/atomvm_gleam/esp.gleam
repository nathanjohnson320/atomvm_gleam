/// Typed Gleam wrappers for AtomVM ESP32-specific APIs (`esp` module).
///
/// Source / docs: [`libs/avm_esp32/src/esp.erl`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/esp.erl#L1)
/// (prefer [release-0.7](https://doc.atomvm.org/release-0.7/) guides; 0.6 eavmlib edoc is incomplete).
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
/// Includes AtomVM 0.7 variants (`EspRstUsb`, `EspRstJtag`, `EspRstEfuse`,
/// `EspRstPwrGlitch`, `EspRstCpuLockup`) that are absent from 0.6 eavmlib edoc.
///
/// See [esp_reset_reason()](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/esp.erl#L80).
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
/// See [esp_wakeup_cause()](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/esp.erl#L98).
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
/// See [interface()](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/esp.erl#L126).
pub type Interface {
  WifiSta
  WifiSoftap
}

/// One flash partition from [`partition_list`](#partition_list).
///
/// Upstream props are always `[]` in AtomVM 0.7 and are omitted here.
///
/// See [esp_partition()](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/esp.erl#L117).
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
/// See [mount_options()](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/esp.erl#L149).
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
/// See [mounted_fs()](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/esp.erl#L136).
pub type MountedFs

/// Task watchdog configuration: timeout (ms), idle-core mask, trigger panic.
///
/// See [task_wdt_config()](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/esp.erl#L129).
pub type TaskWdtConfig {
  TaskWdtConfig(timeout_ms: Int, idle_core_mask: Int, trigger_panic: Bool)
}

/// Opaque handle from [`task_wdt_add_user`](#task_wdt_add_user).
///
/// See [task_wdt_user_handle()](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/esp.erl#L134).
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
/// See [`esp:nvs_get_binary/2`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/esp.erl#L412).
@external(erlang, "atomvm_gleam_esp_ffi", "nvs_get_binary")
pub fn nvs_get_binary(
  namespace: String,
  key: String,
) -> Result(Option(BitArray), Error)

/// Read a binary from the default `atomvm` NVS namespace (`esp:nvs_get_binary/1`).
///
/// See [`esp:nvs_get_binary/1`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/esp.erl#L399).
pub fn nvs_get_binary_default(key: String) -> Result(Option(BitArray), Error) {
  nvs_get_binary("atomvm", key)
}

/// Fetch a binary from NVS (`{ok, Value}` / `{error, not_found}`).
///
/// See [`esp:nvs_fetch_binary/2`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/esp.erl#L389).
@external(erlang, "atomvm_gleam_esp_ffi", "nvs_fetch_binary")
pub fn nvs_fetch_binary(
  namespace: String,
  key: String,
) -> Result(BitArray, Error)

/// Write a binary to NVS (`esp:nvs_put_binary/3`).
///
/// See [`esp:nvs_put_binary/3`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/esp.erl#L477).
@external(erlang, "atomvm_gleam_esp_ffi", "nvs_put_binary")
pub fn nvs_put_binary(
  namespace: String,
  key: String,
  value: BitArray,
) -> Result(Nil, Error)

/// Deprecated alias of [`nvs_put_binary`](#nvs_put_binary) (`esp:nvs_set_binary/3`).
///
/// See [`esp:nvs_set_binary/3`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/esp.erl#L462).
@external(erlang, "atomvm_gleam_esp_ffi", "nvs_set_binary")
pub fn nvs_set_binary(
  namespace: String,
  key: String,
  value: BitArray,
) -> Result(Nil, Error)

/// Write a binary to the default `atomvm` NVS namespace (`esp:nvs_set_binary/2`).
///
/// See [`esp:nvs_set_binary/2`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/esp.erl#L448).
pub fn nvs_set_binary_default(
  key: String,
  value: BitArray,
) -> Result(Nil, Error) {
  nvs_set_binary("atomvm", key, value)
}

/// Erase a key from NVS.
///
/// See [`esp:nvs_erase_key/2`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/esp.erl#L502).
@external(erlang, "atomvm_gleam_esp_ffi", "nvs_erase_key")
pub fn nvs_erase_key(namespace: String, key: String) -> Result(Nil, Error)

/// Erase a key from the default `atomvm` NVS namespace (`esp:nvs_erase_key/1`).
///
/// See [`esp:nvs_erase_key/1`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/esp.erl#L490).
pub fn nvs_erase_key_default(key: String) -> Result(Nil, Error) {
  nvs_erase_key("atomvm", key)
}

/// Erase all keys in an NVS namespace.
///
/// See [`esp:nvs_erase_all/1`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/esp.erl#L521).
@external(erlang, "atomvm_gleam_esp_ffi", "nvs_erase_all")
pub fn nvs_erase_all(namespace: String) -> Result(Nil, Error)

/// Erase all keys in the default `atomvm` NVS namespace (`esp:nvs_erase_all/0`).
///
/// See [`esp:nvs_erase_all/0`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/esp.erl#L511).
pub fn nvs_erase_all_default() -> Result(Nil, Error) {
  nvs_erase_all("atomvm")
}

/// Reformat the entire NVS partition. Deletes all NVS data.
///
/// See [`esp:nvs_reformat/0`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/esp.erl#L532).
@external(erlang, "atomvm_gleam_esp_ffi", "nvs_reformat")
pub fn nvs_reformat() -> Result(Nil, Error)

/// Factory-programmed default MAC address (6 bytes).
///
/// See [`esp:get_default_mac/0`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/esp.erl#L689).
@external(erlang, "atomvm_gleam_esp_ffi", "get_default_mac")
pub fn get_default_mac() -> Result(BitArray, Error)

/// MAC address of a network interface (6 bytes).
///
/// See [`esp:get_mac/1`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/esp.erl#L675).
@external(erlang, "atomvm_gleam_esp_ffi", "get_mac")
pub fn get_mac(interface: Interface) -> Result(BitArray, Error)

/// Reason for the last restart.
///
/// See [`esp:reset_reason/0`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/esp.erl#L183).
@external(erlang, "atomvm_gleam_esp_ffi", "reset_reason")
pub fn reset_reason() -> ResetReason

/// Restart the ESP device. Does not return on success.
///
/// See [`esp:restart/0`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/esp.erl#L174).
@external(erlang, "atomvm_gleam_esp_ffi", "restart")
pub fn restart() -> Nil

/// Chip clock frequency in Hz.
///
/// See [`esp:freq_hz/0`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/esp.erl#L662).
@external(erlang, "atomvm_gleam_esp_ffi", "freq_hz")
pub fn freq_hz() -> Result(Int, Error)

/// Microseconds since boot or wakeup from deep sleep.
///
/// See [`esp:timer_get_time/0`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/esp.erl#L765).
@external(erlang, "atomvm_gleam_esp_ffi", "timer_get_time")
pub fn timer_get_time() -> Result(Int, Error)

/// Enable GPIO wake from light sleep (after `gpio:wakeup_enable/2`).
///
/// See [`esp:sleep_enable_gpio_wakeup/0`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/esp.erl#L318).
@external(erlang, "atomvm_gleam_esp_ffi", "sleep_enable_gpio_wakeup")
pub fn sleep_enable_gpio_wakeup() -> Result(Nil, Error)

/// Enter light sleep until a configured wake source fires.
///
/// See [`esp:light_sleep/0`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/esp.erl#L309).
@external(erlang, "atomvm_gleam_esp_ffi", "light_sleep")
pub fn light_sleep() -> Result(Nil, Error)

/// Enter deep sleep. Never returns; the program restarts on wake.
///
/// See [`esp:deep_sleep/0`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/esp.erl#L298).
@external(erlang, "atomvm_gleam_esp_ffi", "deep_sleep")
pub fn deep_sleep() -> Nil

/// Enter deep sleep for `sleep_ms` milliseconds. Never returns.
///
/// See [`esp:deep_sleep/1`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/esp.erl#L340).
@external(erlang, "atomvm_gleam_esp_ffi", "deep_sleep_ms")
pub fn deep_sleep_ms(sleep_ms: Int) -> Nil

/// Cause of the last wakeup, or `None` when undefined.
///
/// See [`esp:sleep_get_wakeup_cause/0`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/esp.erl#L192).
@external(erlang, "atomvm_gleam_esp_ffi", "sleep_get_wakeup_cause")
pub fn sleep_get_wakeup_cause() -> Result(Option(WakeupCause), Error)

/// Enable ext0 deep-sleep wakeup on `pin` at `level` (`0` or `1`).
///
/// See [`esp:sleep_enable_ext0_wakeup/2`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/esp.erl#L204).
@external(erlang, "atomvm_gleam_esp_ffi", "sleep_enable_ext0_wakeup")
pub fn sleep_enable_ext0_wakeup(pin: Int, level: Int) -> Result(Nil, Error)

/// Enable ext1 deep-sleep wakeup (`mask` bitset, `mode` 0..3).
///
/// Prefer [`sleep_enable_ext1_wakeup_io`](#sleep_enable_ext1_wakeup_io) on newer ESP-IDF.
///
/// See [`esp:sleep_enable_ext1_wakeup/2`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/esp.erl#L225).
@external(erlang, "atomvm_gleam_esp_ffi", "sleep_enable_ext1_wakeup")
pub fn sleep_enable_ext1_wakeup(mask: Int, mode: Int) -> Result(Nil, Error)

/// Enable ext1 deep-sleep wakeup IOs (`mask` bitset, `mode` 0..3).
///
/// See [`esp:sleep_enable_ext1_wakeup_io/2`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/esp.erl#L248).
@external(erlang, "atomvm_gleam_esp_ffi", "sleep_enable_ext1_wakeup_io")
pub fn sleep_enable_ext1_wakeup_io(mask: Int, mode: Int) -> Result(Nil, Error)

/// Disable previously configured ext1 wakeup IOs (`mask` bitset).
///
/// See [`esp:sleep_disable_ext1_wakeup_io/1`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/esp.erl#L261).
@external(erlang, "atomvm_gleam_esp_ffi", "sleep_disable_ext1_wakeup_io")
pub fn sleep_disable_ext1_wakeup_io(mask: Int) -> Result(Nil, Error)

/// Enable GPIO deep-sleep wakeup (`mask` bitset, `mode` 0..1).
///
/// See [`esp:deep_sleep_enable_gpio_wakeup/2`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/esp.erl#L280).
@external(erlang, "atomvm_gleam_esp_ffi", "deep_sleep_enable_gpio_wakeup")
pub fn deep_sleep_enable_gpio_wakeup(mask: Int, mode: Int) -> Result(Nil, Error)

/// Enable ULP wakeup from deep sleep.
///
/// See [`esp:sleep_enable_ulp_wakeup/0`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/esp.erl#L288).
@external(erlang, "atomvm_gleam_esp_ffi", "sleep_enable_ulp_wakeup")
pub fn sleep_enable_ulp_wakeup() -> Result(Nil, Error)

/// Enable timer wakeup from light sleep after `sleep_us` microseconds.
///
/// See [`esp:sleep_enable_timer_wakeup/1`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/esp.erl#L328).
@external(erlang, "atomvm_gleam_esp_ffi", "sleep_enable_timer_wakeup")
pub fn sleep_enable_timer_wakeup(sleep_us: Int) -> Result(Nil, Error)

/// List flash partitions.
///
/// See [`esp:partition_list/0`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/esp.erl#L579).
@external(erlang, "atomvm_gleam_esp_ffi", "partition_list")
pub fn partition_list() -> Result(List(Partition), Error)

/// Read `size` bytes from partition `id` at `offset`.
///
/// See [`esp:partition_read/3`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/esp.erl#L595).
@external(erlang, "atomvm_gleam_esp_ffi", "partition_read")
pub fn partition_read(
  id: BitArray,
  offset: Int,
  size: Int,
) -> Result(BitArray, Error)

/// Memory-map `size` bytes of partition `id` at `offset` into RAM.
///
/// The mapping is released when all references are garbage collected.
///
/// See [`esp:partition_mmap/3`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/esp.erl#L612).
@external(erlang, "atomvm_gleam_esp_ffi", "partition_mmap")
pub fn partition_mmap(
  id: BitArray,
  offset: Int,
  size: Int,
) -> Result(BitArray, Error)

/// Write `data` to partition `id` at `offset`.
///
/// See [`esp:partition_write/3`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/esp.erl#L629).
@external(erlang, "atomvm_gleam_esp_ffi", "partition_write")
pub fn partition_write(
  id: BitArray,
  offset: Int,
  data: BitArray,
) -> Result(Nil, Error)

/// Erase from `offset` to the end of partition `id`.
///
/// See [`esp:partition_erase_range/2`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/esp.erl#L549).
@external(erlang, "atomvm_gleam_esp_ffi", "partition_erase_range")
pub fn partition_erase_range(id: BitArray, offset: Int) -> Result(Nil, Error)

/// Erase `size` bytes of partition `id` starting at `offset`.
///
/// See [`esp:partition_erase_range/3`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/esp.erl#L569).
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
/// See [`esp:rtc_slow_get_binary/0`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/esp.erl#L642).
@external(erlang, "atomvm_gleam_esp_ffi", "rtc_slow_get_binary")
pub fn rtc_slow_get_binary() -> Result(BitArray, Error)

/// Store a binary in RTC slow memory (survives reset and deep sleep).
///
/// See [`esp:rtc_slow_set_binary/1`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/esp.erl#L653).
@external(erlang, "atomvm_gleam_esp_ffi", "rtc_slow_set_binary")
pub fn rtc_slow_set_binary(bin: BitArray) -> Result(Nil, Error)

/// Mount a filesystem and return a handle for [`umount`](#umount).
///
/// See [`esp:mount/4`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/esp.erl#L366).
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
/// See [`esp:umount/1`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/esp.erl#L375).
@external(erlang, "atomvm_gleam_esp_ffi", "umount")
pub fn umount(mounted: MountedFs) -> Result(Nil, Error)

/// Initialize the task watchdog timer.
///
/// See [`esp:task_wdt_init/1`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/esp.erl#L700).
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
/// See [`esp:task_wdt_reconfigure/1`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/esp.erl#L711).
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
/// See [`esp:task_wdt_deinit/0`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/esp.erl#L722).
@external(erlang, "atomvm_gleam_esp_ffi", "task_wdt_deinit")
pub fn task_wdt_deinit() -> Result(Nil, Error)

/// Register a task watchdog user; returns a handle for reset/delete.
///
/// See [`esp:task_wdt_add_user/1`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/esp.erl#L733).
@external(erlang, "atomvm_gleam_esp_ffi", "task_wdt_add_user")
pub fn task_wdt_add_user(username: String) -> Result(TaskWdtUserHandle, Error)

/// Reset the timer for a previously registered watchdog user.
///
/// See [`esp:task_wdt_reset_user/1`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/esp.erl#L744).
@external(erlang, "atomvm_gleam_esp_ffi", "task_wdt_reset_user")
pub fn task_wdt_reset_user(handle: TaskWdtUserHandle) -> Result(Nil, Error)

/// Unsubscribe a watchdog user.
///
/// See [`esp:task_wdt_delete_user/1`](https://github.com/atomvm/AtomVM/blob/release-0.7/libs/avm_esp32/src/esp.erl#L755).
@external(erlang, "atomvm_gleam_esp_ffi", "task_wdt_delete_user")
pub fn task_wdt_delete_user(handle: TaskWdtUserHandle) -> Result(Nil, Error)
