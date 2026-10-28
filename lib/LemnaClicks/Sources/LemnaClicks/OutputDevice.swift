import AudioToolbox
import CoreAudio

/// The CoreAudio reads and writes the player needs. None of this runs per click.
enum OutputDevice {
    static var defaultOutputAddress: AudioObjectPropertyAddress {
        AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain)
    }

    /// The system's default output device, nil when there is none.
    static func defaultID() -> AudioObjectID? {
        var address = defaultOutputAddress
        var device = AudioObjectID(kAudioObjectUnknown)
        var size = UInt32(MemoryLayout<AudioObjectID>.size)
        let status = AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &device)
        return status == noErr && device != kAudioObjectUnknown ? device : nil
    }

    /// Whether the default output is Bluetooth (classic or LE): such headphones play every click
    /// some 120–300 ms late, which no app can shorten, so the app warns once.
    static func defaultIsBluetooth() -> Bool {
        guard let device = defaultID() else { return false }
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyTransportType,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain)
        var transport: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)
        guard AudioObjectGetPropertyData(device, &address, 0, nil, &size, &transport) == noErr else { return false }
        return transport == kAudioDeviceTransportTypeBluetooth || transport == kAudioDeviceTransportTypeBluetoothLE
    }

    /// Asks the output unit for an IO buffer of `frames` (clamped to the device's range) and
    /// returns what it reads back, 0 if unknown. Apple TN2321: kAudioDevicePropertyBufferFrameSize
    /// can be set on the AUHAL itself (global scope, element 0), which passes it to its current
    /// device; the setting is this process's own (another process still reads the default 512).
    static func requestIOBuffer(_ frames: UInt32, on unit: AudioUnit?) -> UInt32 {
        guard let unit else { return 0 }
        var range = AudioValueRange()
        var rangeSize = UInt32(MemoryLayout<AudioValueRange>.size)
        var wanted = frames
        if AudioUnitGetProperty(unit, kAudioDevicePropertyBufferFrameSizeRange, kAudioUnitScope_Global, 0, &range, &rangeSize) == noErr,
           range.mMaximum >= range.mMinimum {
            wanted = UInt32(min(max(Double(frames), range.mMinimum), range.mMaximum))
        }
        let size = UInt32(MemoryLayout<UInt32>.size)
        _ = AudioUnitSetProperty(unit, kAudioDevicePropertyBufferFrameSize, kAudioUnitScope_Global, 0, &wanted, size)
        var accepted: UInt32 = 0
        var readSize = size
        let status = AudioUnitGetProperty(unit, kAudioDevicePropertyBufferFrameSize, kAudioUnitScope_Global, 0, &accepted, &readSize)
        return status == noErr ? accepted : 0
    }
}
