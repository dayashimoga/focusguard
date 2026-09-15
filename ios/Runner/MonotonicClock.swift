import Foundation
import Darwin

/// Hardware-backed monotonic time provider for iOS resistant to wall-clock changes.
/// Uses mach_continuous_time() which continues ticking while the device is sleeping.
public final class MonotonicClock {

    private static var timebaseInfo: mach_timebase_info_data_t = {
        var info = mach_timebase_info_data_t()
        mach_timebase_info(&info)
        return info
    }()

    /// Returns monotonic elapsed milliseconds since system boot.
    public static func elapsedRealtime() -> Int64 {
        let machTime = mach_continuous_time()
        let nanos = (machTime * UInt64(timebaseInfo.numer)) / UInt64(timebaseInfo.denom)
        return Int64(nanos / 1_000_000)
    }

    /// Returns wall clock milliseconds for logging and UI display only.
    public static func currentTimeMillis() -> Int64 {
        return Int64(Date().timeIntervalSince1970 * 1000)
    }
}
