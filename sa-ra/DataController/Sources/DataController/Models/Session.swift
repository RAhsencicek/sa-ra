


import Foundation
import CoreBluetooth
import UIKit


struct Session {
    /// Name of the device.
    static let deviceName = UIDevice.current.name
    /// Bluetooth service UUID
    static let UUID = CBUUID(string: "D6B52A44-E586-4502-9F98-4799C8B95C86")
    /// The unique UUID of the characteristic (the chat functionality part)
    static let characteristicsUUID = CBUUID(string: "54C89B72-F7EE-4A0A-8382-7367C3E151A5")
}
