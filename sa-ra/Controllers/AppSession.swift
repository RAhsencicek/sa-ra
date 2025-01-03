

import Foundation
import SwiftUI
import CoreData
import Combine
import DataController


class AppSession: ObservableObject  {
    
    private var cancellables = Set<AnyCancellable>()
    
    @Published var bannerDataShouldShow = false
    @Published var bannerData: BannerModifier.BannerData = .init(title: "", message: "") {
        didSet {
            withAnimation(.spring()) {
                bannerDataShouldShow = true
            }
        }
    }
    
   
    let context: NSManagedObjectContext
    
  
    @Published var routedCounter: Int = 0
    
   
    @Published var refreshID = UUID()
    
    @Published private(set) var connectedDevicesAmount = 0
    
    
    
    var seenMessages: [Int32] = []
    
   
    var peripheralMessages: [String : [Date]] = [:]
    
    
    var senderOfMessageID: [Int32 : String] = [:]
    
    private var dataController: LiveDataController
    
  
    init(context: NSManagedObjectContext) {
        self.context = context
        self.dataController = LiveDataController(config: .init(usernameWithRandomDigits: ""))
        dataController.delegate = self
        setupBindings()
    }
    
    private func setupBindings() {
       
        UsernameValidator.shared.$userInfo.sink { [unowned self] userInfo in
            guard let userInfo else { return }
            let usernameWithDigits = userInfo.asString
            dataController = LiveDataController(
                config: .init(usernameWithRandomDigits: usernameWithDigits))
            dataController.delegate = self
        }.store(in: &cancellables)
    }
    
    func addUserFromQrScan(_ result: String) {
        do {
            try ScanHandler.retrieve(result: result, context: context)
            showBanner(.init(title: "User added", message: "All good! The user has been added.", kind: .success))
        } catch ScanHandler.ScanHandlerError.userPreviouslyAdded {
            showBanner(.init(title: "Oops", message: "The user has been added ", kind: .normal))
        } catch ScanHandler.ScanHandlerError.invalidFormat {
            showBanner(.init(title: "Oops", message: "The scanned QR code does not look correct.", kind: .error))
        } catch {
            showErrorMessage(error.localizedDescription)
        }
    }
    
    func send(text message: String, conversation: ConversationEntity) async {
        var messageToBeStored: Message
        do {
           
            guard let receipentPublicKey = conversation.publicKey, let receipent = conversation.author else {
                fatalError("Tried to fetch public key of conversation but it was nil")
            }
            
            guard let usernameWithDigits = UsernameValidator.shared.userInfo?.asString else {
                fatalError("Tried to send a message without having a username, developer error.")
            }
            
            let privateKey = try CryptoHandler.fetchPrivateKey()
            let receiverPublicKey = try CryptoHandler.convertPublicKeyStringToKey(receipentPublicKey)
            let symmetricKey = try CryptoHandler.deriveSymmetricKey(privateKey: privateKey, publicKey: receiverPublicKey)
            let encryptedText = try CryptoHandler.encryptMessage(
                text: message, symmetricKey: symmetricKey)
            
            let messageId = Int32.random(in: 0...Int32.max)
            let sendMessageInformation = SendMessageInformation(id: messageId, encryptedText: encryptedText, receipentWithDigits: receipent)
            try await dataController.send(message: sendMessageInformation)
            
            messageToBeStored = Message(
                id: messageId,
                kind: .regular,
                sender: usernameWithDigits,
                receiver: receipent,
                text: message)
        } catch DataControllerError.noConnectedDevices {
            showBanner(.init(
                title: "Message in queue",
                message: "There are currently no connected devices. The message will be delivered later.",
                kind: .normal))
            return
        } catch {
            showErrorMessage(error.localizedDescription)
            return
        }
        
        // Save the message to local storage
        let localMessage = MessageEntity(context: context)
        
        localMessage.receiver = messageToBeStored.receiver
        localMessage.status = MessageStatus.sent.rawValue
        localMessage.text = messageToBeStored.text
        localMessage.date = Date()
        localMessage.id = messageToBeStored.id
        localMessage.sender = messageToBeStored.sender
        
        conversation.lastMessage = "You: " + messageToBeStored.text
        conversation.date = Date()
        conversation.addToMessages(localMessage)
        
        // Context should be saved on main thread
        DispatchQueue.main.async { [weak self] in
            do {
                try self?.context.save()
            } catch {
                self?.showErrorMessage(error.localizedDescription)
            }
        }
    }
    
   
    func sendReadMessages(for conversation: ConversationEntity) async {
        guard let usernameWithDigits = UsernameValidator.shared.userInfo?.asString else {
            fatalError("Tried to send read messages before username was set.")
        }
        guard let receiver = conversation.author else {
            showBanner(.init(title: "Oops", message: "Could not find contact and thus not send read message.", kind: .normal))
            return
        }
        guard let messageEntities = conversation.messages?.allObjects as? [MessageEntity] else {
            showBanner(.init(title: "Oops", message: "No messages found in this conversation.", kind: .normal))
            return
        }
        
        let messageEntitiesWithReceivedStatus = messageEntities
            .filter { MessageStatus(rawValue: $0.status) == .received }
        
        guard messageEntitiesWithReceivedStatus.count > 0 else { return }
        
        var readMessageText: String = "READ/"
        for messageEntity in messageEntitiesWithReceivedStatus {
            readMessageText += "\(messageEntity.id)/"
        }
        
        let messageRead = Message(
            id: Int32.random(in: 0...Int32.max),
            kind: .read,
            sender: usernameWithDigits,
            receiver: receiver,
            text: readMessageText)
        
        do {
            try await dataController.sendAcknowledgementOrRead(message: messageRead)
        } catch {
            showErrorMessage(error.localizedDescription)
        }
    }
    
    func showBanner(_ bannerData: BannerModifier.BannerData) {
        self.bannerData = bannerData
    }
    
    func showErrorMessage(_ error: String) {
        showBanner(.init(title: "Something went wrong", message: error, kind: .error))
    }
}
    

extension AppSession {
    private func receive(encryptedMessage: Message) async {
        await context.perform { [weak self] in
            guard let self else { return }
            do {
                let conversation = self.getConversationFor(message: encryptedMessage)
                guard let conversation else { return }

                let decryptedMessageText = try self.decryptMessageToText(
                    message: encryptedMessage,
                    conversation: conversation)

                guard let usernameWithDigits = UsernameValidator.shared.userInfo?.asString else {
                    self.showErrorMessage("Could not find your current username.")
                    return
                }

                let date = Date()

                let localMessage = LocalMessage(
                    id: encryptedMessage.id,
                    sender: encryptedMessage.sender,
                    receiver: usernameWithDigits,
                    text: decryptedMessageText,
                    date: date,
                    status: .received)

                let messageEntity = MessageEntity(context: self.context)
                messageEntity.id = localMessage.id
                messageEntity.receiver = localMessage.receiver
                messageEntity.sender = localMessage.sender
                messageEntity.status = localMessage.status.rawValue
                messageEntity.text = localMessage.text
                messageEntity.date = localMessage.date

                conversation.addToMessages(messageEntity)
                conversation.lastMessage = decryptedMessageText
                conversation.date = Date()

                try self.context.save()
                
                Task {
                    await self.sendAcknowledgement(of: messageEntity)
                    self.sendNotificationWith(text: localMessage.text, from: localMessage.sender)
                }
            } catch {
                self.showErrorMessage("Could not save newly received message.")
            }
        }
    }
    
    #warning("Refactor method")
    private func receiveAcknowledgement(message: Message) {
        Task {
            context.perform {
                let conversation = self.getConversationFor(message: message)
                guard let conversation else {
                    return
                }
                
                let components = message.text.components(separatedBy: "/")
                guard components.first == Message.Kind.acknowledgement.asString && components.count == 2 else {
                    return
                }
                
                let messages = conversation.messages?.allObjects as! [MessageEntity]
                
                guard let id = Int(components[1]) else { return }
                let messagesWithId = messages.filter { $0.id == id }
                messagesWithId.forEach { $0.status = MessageStatus.delivered.rawValue }
                
                DispatchQueue.main.async {
                    do {
                        try self.context.save()
                        self.refreshID = UUID()
                    } catch {
                        self.showErrorMessage(error.localizedDescription)
                    }
                }
            }
        }
    }
    
    #warning("Refactor method")
    private func receiveRead(message: Message) {
        context.perform {
            let conversation = self.getConversationFor(message: message)
            guard let conversation else { return }
            
            
            var components = message.text.components(separatedBy: "/")
            guard components.first == "READ" && components.count > 1 else {
                return
            }
            
            
            components.removeFirst()
            components.removeLast()
            
            let intComponents = components.map {Int32($0)!}
            
            let messages = conversation.messages?.allObjects as! [MessageEntity]
            
            for message in messages {
                if intComponents.contains(message.id) {
                    message.status = MessageStatus.read.rawValue
                }
            }
            
            self.refreshID = UUID()
            do {
                try self.context.save()
            } catch {
                self.showErrorMessage(error.localizedDescription)
            }
        }
    }
    
    private func sendAcknowledgement(of message: MessageEntity) async {
        guard let usernameWithDigits = UsernameValidator.shared.userInfo?.asString else {
            fatalError("ACK sent but username has not been set. This is not allowed.")
        }
        
        guard let receiver = message.sender else {
            fatalError("Cannot send ACK when there is no receiver. This is not allowed.")
        }
        
        let ackText = "\(Message.Kind.acknowledgement.asString)/\(message.id)"
        let ackMessage = Message(
            id: Int32.random(in: 0...Int32.max),
            kind: .acknowledgement,
            sender: usernameWithDigits,
            receiver: receiver,
            text: ackText)
        
        do {
            try await dataController.sendAcknowledgementOrRead(message: ackMessage)
        } catch {
            showErrorMessage(error.localizedDescription)
        }
    }
}

extension AppSession: DataControllerDelegate {
    func dataController(_ dataController: DataController, isConnectedTo deviceAmount: Int) {
        connectedDevicesAmount = deviceAmount
    }
    
    func dataControllerDidRelayMessage(_ dataController: DataController) {
        routedCounter += 1
    }
    
    func dataController(_ dataController: DataController, didReceive encryptedMessage: Message) {
        Task {
            await receive(encryptedMessage: encryptedMessage)
        }
    }
    
    func dataController(_ dataController: DataController, didReceiveAcknowledgement message: Message) {
        receiveAcknowledgement(message: message)
    }
    
    func dataController(_ dataController: DataController, didReceiveRead message: Message) {
        receiveRead(message: message)
    }
    
    func dataController(_ dataController: DataController, didFailWith error: Error) {
        ()
    }
}


extension AppSession {
    
    private func getConversationFor(message: Message) -> ConversationEntity? {
        let fetchRequest = ConversationEntity.fetchRequest()
        let conversations = try? fetchRequest.execute()
        guard let conversations else { return nil }
        let conversation = conversations
            .first(where: { $0.author == message.sender })
        if let conversation {
            return conversation
        } else {
            self.showErrorMessage("Received a message for you, but the sender has not been added as a contact.")
            return nil
        }
    }
    private func decryptMessageToText(message: Message, conversation: ConversationEntity) throws -> String {
        let publicKeyOfSender = try CryptoHandler.convertPublicKeyStringToKey(conversation.publicKey)
        let symmetricKey = try CryptoHandler.deriveSymmetricKey(privateKey: CryptoHandler.fetchPrivateKey(), publicKey: publicKeyOfSender)
        return CryptoHandler.decryptMessage(text: message.text, symmetricKey: symmetricKey)
    }
    
    private func sendNotificationWith(text: String, from sender: String) {
        let content = UNMutableNotificationContent()
        content.title = sender.components(separatedBy: "#").first ?? "Maybe: \(sender)"
        content.body = text
        content.sound = UNNotificationSound.default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: 0.01,
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }
}

