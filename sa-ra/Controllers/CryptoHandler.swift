

import UIKit
import CryptoKit


class CryptoHandler {
    enum CryptoHandlerError: Error, LocalizedError {
        case conversationKeyNotFound
        case keyInWrongFormat
        case textCannotBeUtf8Converted
        case textCannotBeEncrypted
        case userPrivateKeyNotFound
            
        public var errorDescription: String? {
            switch self {
            case .conversationKeyNotFound:
                return NSLocalizedString("No cryptography key found for this conversation.", comment: "No key found")
            case .keyInWrongFormat:
                return NSLocalizedString("Public/Private key is in wrong format.", comment: "Wrong key format")
            case .textCannotBeEncrypted:
                return NSLocalizedString("The message text cannot be encrypted.", comment: "Not able to encrypt message text")
            case .textCannotBeUtf8Converted:
                return NSLocalizedString("Cannot convert text to UTF8 format.", comment: "UTF8 conversion failure")
            case .userPrivateKeyNotFound:
                return NSLocalizedString("Your private key could not be found.", comment: "Private key not found")
            }
        }
    }
    
   
    static func fetchPublicKeyString() -> String {
        let defaults = UserDefaults.standard
        
       
        if let privateKeyText = defaults.string(forKey: UserDefaultsKey.privateKey.rawValue),
            let privateKey = try? convertPrivateKeyStringToKey(privateKeyText) {
            let publicKeyText = convertPublicKeyToString(privateKey.publicKey)
            return publicKeyText
        }
        
  
        let privateKey = generatePrivateKey()
        let privateKeyText = convertPrivateKeyToString(privateKey)
        let publicKeyText = convertPublicKeyToString(privateKey.publicKey)
        defaults.setValue(privateKeyText, forKey: UserDefaultsKey.privateKey.rawValue)
        return publicKeyText
    }


    
    static func fetchPrivateKey() throws -> P256.KeyAgreement.PrivateKey {
        guard let privateKey = UserDefaults.standard.string(forKey: UserDefaultsKey.privateKey.rawValue) else {
            throw CryptoHandlerError.userPrivateKeyNotFound
        }
        return try convertPrivateKeyStringToKey(privateKey)
    }

    
    static func generatePrivateKey() -> P256.KeyAgreement.PrivateKey {
        P256.KeyAgreement.PrivateKey()
    }

    
    static func convertPrivateKeyToString(_ privateKey: P256.KeyAgreement.PrivateKey) -> String {
        let rawPrivateKey = privateKey.rawRepresentation
        let privateKeyBase64 = rawPrivateKey.base64EncodedString()
        let percentEncodedPrivateKey = privateKeyBase64.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!
        return percentEncodedPrivateKey
    }

    
    static func convertPublicKeyToString(_ publicKey: P256.KeyAgreement.PublicKey) -> String {
        let rawPublicKey = publicKey.rawRepresentation
        let base64PublicKey = rawPublicKey.base64EncodedString()
        let encodedPublicKey = base64PublicKey.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!
        return encodedPublicKey
    }

    
    static func convertPrivateKeyStringToKey(_ privateKey: String) throws -> P256.KeyAgreement.PrivateKey {
        guard let privateKeyBase64 = privateKey.removingPercentEncoding else { throw CryptoHandlerError.keyInWrongFormat }
        guard let rawPrivateKey = Data(base64Encoded: privateKeyBase64) else { throw CryptoHandlerError.keyInWrongFormat }
        return try P256.KeyAgreement.PrivateKey(rawRepresentation: rawPrivateKey)
    }

   
    static func convertPublicKeyStringToKey(_ publicKey: String?) throws -> P256.KeyAgreement.PublicKey {
        guard let publicKey else { throw CryptoHandlerError.conversationKeyNotFound }
        guard let publicKeyBase64 = publicKey.removingPercentEncoding else { throw CryptoHandlerError.keyInWrongFormat }
        guard let rawPublicKey = Data(base64Encoded: publicKeyBase64) else { throw CryptoHandlerError.keyInWrongFormat }
        return try P256.KeyAgreement.PublicKey(rawRepresentation: rawPublicKey)
    }


   
    static func deriveSymmetricKey(privateKey: P256.KeyAgreement.PrivateKey, publicKey: P256.KeyAgreement.PublicKey) throws -> SymmetricKey {
        let sharedSecret = try privateKey.sharedSecretFromKeyAgreement(with: publicKey)
        return sharedSecret.hkdfDerivedSymmetricKey(
            using: SHA256.self,
            salt: "My Key Agreement Salt".data(using: .utf8)!,
            sharedInfo: Data(),
            outputByteCount: 32
        )
    }

   
    static func encryptMessage(text: String, symmetricKey: SymmetricKey) throws -> String {
        guard let textData = text.data(using: .utf8) else { throw CryptoHandlerError.textCannotBeUtf8Converted }
        let encrypted = try AES.GCM.seal(textData, using: symmetricKey)
        guard let encryptedData = encrypted.combined else { throw CryptoHandlerError.textCannotBeEncrypted}
        return encryptedData.base64EncodedString()
    }

   
    static func decryptMessage(text: String, symmetricKey: SymmetricKey) -> String {
        do {
            guard let data = Data(base64Encoded: text) else {
                return "Could not decode text: \(text)"
            }
            
            let sealedBox = try AES.GCM.SealedBox(combined: data)
            let decryptedData = try AES.GCM.open(sealedBox, using: symmetricKey)
            
            guard let text = String(data: decryptedData, encoding: .utf8) else {
                return "Could not decode data: \(decryptedData)"
            }
            
            return text
        } catch let error {
            return "Error decrypting message: \(error.localizedDescription)"
        }
    }
    
    
    static func resetKeys() {
        UserDefaults.standard.removeObject(forKey: UserDefaultsKey.privateKey.rawValue)
        let _ = fetchPublicKeyString()
    }
}
