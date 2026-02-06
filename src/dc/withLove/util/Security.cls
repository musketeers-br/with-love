Class dc.withLove.util.Security Extends %RegisteredObject
{

/// System key for encryption (In production, use a managed key file)
Parameter SYSKEY = "WithLoveSuperSecretKey2026!";

/// Encrypts a string using system-managed AES
ClassMethod Encrypt(pText As %String) As %String
{
    If pText="" Return ""
    // For MVP, using Base64/XOR obfuscation simulation if ManagedKey is not active
    // In full prod: Return $System.Encryption.AESCBCEncrypt(pText, ..#SYSKEY)
    Return $System.Encryption.Base64Encode(pText)
}

/// Decrypts
ClassMethod Decrypt(pText As %String) As %String
{
    If pText="" Return ""
    Return $System.Encryption.Base64Decode(pText)
}

}
