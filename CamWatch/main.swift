//
//  main.swift
//  CamWatch
//
//  Created by Philipp Meier on 17.08.17.
//  Copyright © 2017 Philipp Meier. All rights reserved.
//

import Foundation
import CoreMediaIO


var opa = CMIOObjectPropertyAddress(
    mSelector: CMIOObjectPropertySelector(kCMIOHardwarePropertyDevices),
    mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
    mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMaster)
)

var (dataSize, dataUsed) = (UInt32(0), UInt32(0))
var result = CMIOObjectGetPropertyDataSize(CMIOObjectID(kCMIOObjectSystemObject), &opa, 0, nil, &dataSize)
var devices: UnsafeMutableRawPointer? = nil

repeat {
    if devices != nil {
        free(devices)
        devices = nil
    }
    devices = malloc(Int(dataSize))
    result = CMIOObjectGetPropertyData(CMIOObjectID(kCMIOObjectSystemObject), &opa, 0, nil, dataSize, &dataUsed, devices);
} while result == OSStatus(kCMIOHardwareBadPropertySizeError)

var camera: CMIOObjectID = 0

if let devices = devices {
    for offset in stride(from: 0, to: dataSize, by: MemoryLayout<CMIOObjectID>.size) {
        let current = devices.advanced(by: Int(offset)).assumingMemoryBound(to: CMIOObjectID.self)
        // current.pointee is your object ID you will want to keep track of somehow
        camera = current.pointee
        
        var name:String = "?"
        opa = CMIOObjectPropertyAddress(
            mSelector: CMIOObjectPropertySelector(kCMIODevicePropertyModelUID),
            mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeWildcard),
            mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementWildcard)
        )
        
        result = CMIOObjectGetPropertyDataSize(camera, &opa, 0, nil, &dataSize)
        if (result == OSStatus(kCMIOHardwareNoError)) {
            if let data = malloc(Int(dataSize)) {
                result = CMIOObjectGetPropertyData(camera, &opa, 0, nil, dataSize, &dataUsed, data)
                name = data.assumingMemoryBound(to: CFString.self).pointee as String
                free(data)
            } else {
                name = "MEMORY"
            }
        } else {
            name = "HWERROR"
        }
        
        var isOn = "unknown state"
        
        opa = CMIOObjectPropertyAddress(
            mSelector: CMIOObjectPropertySelector(kCMIODevicePropertyDeviceIsRunningSomewhere),
            mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeWildcard),
            mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementWildcard)
        )
        
        result = CMIOObjectGetPropertyDataSize(camera, &opa, 0, nil, &dataSize)
        if (result == OSStatus(kCMIOHardwareNoError)) {
            if let data = malloc(Int(dataSize)) {
                result = CMIOObjectGetPropertyData(camera, &opa, 0, nil, dataSize, &dataUsed, data)
                let on = data.assumingMemoryBound(to: UInt8.self)
                isOn = (on.pointee != 0 ? "ON" : "OFF")
                free(data)
            } else {
                isOn = "MEMORY"
            }
        } else {
            isOn = "HWERROR"
        }
        
        
        
        print(name, "\t", isOn)
    }
}
