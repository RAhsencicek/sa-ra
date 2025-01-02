

import Foundation

public protocol DataControllerDelegate: AnyObject {
    func dataController(_ dataController: DataController, isConnectedTo deviceAmount: Int)
    func dataController(_ dataController: DataController, didReceive encryptedMessage: Message)
    func dataController(_ dataController: DataController, didReceiveAcknowledgement message: Message)
    func dataController(_ dataController: DataController, didReceiveRead message: Message)
    func dataController(_ dataController: DataController, didFailWith error: Error)
    func dataControllerDidRelayMessage(_ dataController: DataController)
}

