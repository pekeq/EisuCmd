//
//  KeyEventTap.swift
//  EisuCmd
//
//  Created by hideo-m on 2021/12/31.
//

import Foundation
import Carbon.HIToolbox

/*
 Notes about key events:
    cmd down
      type=12, flags=1048840, code=55, repeat=0, kbtype=54
    cmd+a down
      type=10, flags=1048840, code=0, repeat=0, kbtype=54
    cmd+a up
      type=11, flags=1048840, code=0, repeat=0, kbtype=54
    cmd up
      type=12, flags=256, code=55, repeat=0, kbtype=54

    eisu down
      type=10, flags=256, code=102, repeat=0, kbtype=54
    eisu up
      type=11, flags=256, code=102, repeat=0, kbtype=54

 What is flags=1048840?:
    1048840 = 1048576(maskCommand) + 256(maskNonCoalesced) + 8(NX_DEVICELCMDKEYMASK)
*/

let CmdKeyEventFlags = CGEventFlags(rawValue: (CGEventFlags.maskCommand.rawValue | CGEventFlags.maskNonCoalesced.rawValue | UInt64(NX_DEVICELCMDKEYMASK)))

// true while Eisu key is pressing
fileprivate var isEisuPressing = false

fileprivate func dumpEvent(_ event: CGEvent, _ msg: String = "") {
    #if DEBUG
    let code = event.getIntegerValueField(.keyboardEventKeycode)
    let ar = event.getIntegerValueField(.keyboardEventAutorepeat)
    let kt = event.getIntegerValueField(.keyboardEventKeyboardType)
    print("\(msg)type=\(event.type.rawValue), flags=\(event.flags.rawValue), code=\(code), repeat=\(ar), kbtype=\(kt)")
    #endif
}

fileprivate func eventCallback(tapProxy: CGEventTapProxy,
                               eventType: CGEventType,
                               event: CGEvent,
                               data: UnsafeMutableRawPointer?) -> Unmanaged<CGEvent>? {
    dumpEvent(event, "eventCallback:")

    switch eventType {
    case CGEventType.keyDown:
        return onKeyDown(event)
    case CGEventType.keyUp:
        return onKeyUp(event)
    case CGEventType.flagsChanged:
        return onFlagsChanged(event)
    default:
        return Unmanaged.passRetained(event)
    }
}

fileprivate func onKeyDown(_ event: CGEvent) -> Unmanaged<CGEvent>? {
    let keycode = event.getIntegerValueField(.keyboardEventKeycode)

    if (keycode == kVK_JIS_Eisu) {
        let autorepeat = event.getIntegerValueField(.keyboardEventAutorepeat)

        // ignore autorepeat since using Eisu key repeat is unusual
        if (autorepeat != 0) {
            return nil
        }

        // transform event to Command key
        event.type = CGEventType.flagsChanged
        event.flags = CmdKeyEventFlags
        event.setIntegerValueField(.keyboardEventKeycode, value: Int64(kVK_Command))
        isEisuPressing = true

        dumpEvent(event, "onKeyDown(Eisu):")
        return Unmanaged.passRetained(event)
    }

    // append command key flag while Eisu key pressing
    if (isEisuPressing) {
        event.flags = CmdKeyEventFlags
    }

    dumpEvent(event, "onKeyDown:")
    return Unmanaged.passRetained(event)
}

fileprivate func onKeyUp(_ event: CGEvent) -> Unmanaged<CGEvent>? {
    let keycode = event.getIntegerValueField(.keyboardEventKeycode)

    if (keycode == kVK_JIS_Eisu) {
        isEisuPressing = false

        let autorepeat = event.getIntegerValueField(.keyboardEventAutorepeat)

        // autorepeat will not occur when keyup, I paranoid
        if (autorepeat != 0) {
            return nil
        }

        // transform event to Command key
        event.type = CGEventType.flagsChanged
        event.setIntegerValueField(.keyboardEventKeycode, value: Int64(kVK_Command))
        dumpEvent(event, "onKeyUp(Eisu Cmdup2):")

        return Unmanaged.passRetained(event)
    }

    if (isEisuPressing) {
        event.flags = CmdKeyEventFlags
    }

    dumpEvent(event, "onKeyUp:")
    return Unmanaged.passRetained(event)
}

fileprivate func onFlagsChanged(_ event: CGEvent) -> Unmanaged<CGEvent>? {
    return Unmanaged.passRetained(event)
}

class KeyEventTap {
    func listen() {
        let eventMask =
            (1 << CGEventType.keyDown.rawValue) |
            (1 << CGEventType.keyUp.rawValue)
//            (1 << CGEventType.flagsChanged.rawValue)

        let observer = UnsafeMutableRawPointer(Unmanaged.passRetained(self).toOpaque())
        
        print("tapping")
        
        guard let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: eventCallback,
            userInfo: observer)
        else {
            print("tapCreate(): Failed")
            exit(1)
        }
        
        
        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
        CFRunLoopRun()
    }
}
