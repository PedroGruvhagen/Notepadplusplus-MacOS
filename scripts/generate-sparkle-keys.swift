// One-time generator for the Sparkle EdDSA signing keypair, file-based (no Keychain).
// The Keychain-based generate_keys flow was denied interactively; sign_update reads
// this file via --ed-key-file instead. See lore/pages/auto-update-sparkle.md.
import CryptoKit
import Foundation

let keyPath = "scripts/sparkle_eddsa_private.key"
guard !FileManager.default.fileExists(atPath: keyPath) else {
    FileHandle.standardError.write(Data("ERROR: \(keyPath) already exists. Installed apps only accept updates signed by this exact key; never regenerate it.\n".utf8))
    exit(1)
}
let key = Curve25519.Signing.PrivateKey()
try key.rawRepresentation.base64EncodedString().write(toFile: keyPath, atomically: true, encoding: .utf8)
try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: keyPath)
print("Private key written to \(keyPath)")
print("SUPublicEDKey=\(key.publicKey.rawRepresentation.base64EncodedString())")
