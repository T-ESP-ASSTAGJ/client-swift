//
//  ValidationResult.swift
//  jamly
//
//  Created by REVERSS on 07/12/2025.
//


import Foundation

// MARK: - Validation Result
enum ValidationResult {
    case success
    case failure(String)
    
    var isValid: Bool {
        if case .success = self {
            return true
        }
        return false
    }
    
    var errorMessage: String? {
        if case .failure(let message) = self {
            return message
        }
        return nil
    }
}

// MARK: - Base Validator Protocol
protocol Validator {
    associatedtype T
    func validate(_ value: T) -> ValidationResult
}

// MARK: - Email Validator
struct EmailValidator: Validator {
    func validate(_ value: String) -> ValidationResult {
        guard !value.isEmpty else {
            return .failure("Email is required")
        }
        
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let predicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        
        guard predicate.evaluate(with: value) else {
            return .failure("Email format invalid")
        }
        
        return .success
    }
}

// MARK: - Username Validator
struct UsernameValidator: Validator {
    let minLength: Int
    let maxLength: Int
    
    init(minLength: Int = 4, maxLength: Int = 15) {
        self.minLength = minLength
        self.maxLength = maxLength
    }
    
    func validate(_ value: String) -> ValidationResult {
        guard !value.isEmpty else {
            return .failure("Username is required")
        }
        
        guard value.count >= minLength else {
            return .failure("Username must be at least \(minLength) characters")
        }
        
        guard value.count <= maxLength else {
            return .failure("Username cannot exceed \(maxLength) characters")
        }
        
        // Alphanumeric + underscore uniquement
        let usernameRegex = "^[a-zA-Z0-9_-]+$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", usernameRegex)
        
        guard predicate.evaluate(with: value) else {
            return .failure("Username must be contains only letters, digits, underscores or hyphens")
        }
        
        return .success
    }
}

// MARK: - Phone Validator
struct PhoneValidator: Validator {
    func validate(_ value: String) -> ValidationResult {
        guard !value.isEmpty else {
            return .failure("Phone number is required")
        }
        
        // Format français : 06/07 suivi de 8 chiffres ou +33
        let phoneRegex = "^(?:(?:\\+|00)33[\\s.-]{0,3}(?:\\(0\\)[\\s.-]{0,3})?|0)[6-7](?:(?:[\\s.-]?\\d{2}){4}|\\d{2}(?:[\\s.-]?\\d{3}){2})$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        
        guard predicate.evaluate(with: value) else {
            return .failure("Phone number format invalid")
        }
        
        return .success
    }
}

// MARK: - OTP Validator
struct OTPValidator: Validator {
    let length: Int
    
    init(length: Int = 6) {
        self.length = length
    }
    
    func validate(_ value: String) -> ValidationResult {
        guard !value.isEmpty else {
            return .failure("OTP Code is required")
        }
        
        guard value.count == length else {
            return .failure("OTP Code must be contains \(length) numbers")
        }
        
        let numberRegex = "^[0-9]+$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", numberRegex)
        
        guard predicate.evaluate(with: value) else {
            return .failure("OTP Code must be contains only numbers")
        }
        
        return .success
    }
}

// MARK: - Required Field Validator
struct RequiredValidator: Validator {
    let fieldName: String
    
    init(fieldName: String = "This field") {
        self.fieldName = fieldName
    }
    
    func validate(_ value: String) -> ValidationResult {
        guard !value.trimmingCharacters(in: .whitespaces).isEmpty else {
            return .failure("\(fieldName) is required")
        }
        return .success
    }
}

// MARK: - Schemas (comme Zod)
struct AuthSchemas {
    // Login Schema
    struct Login {
        static func validate(email: String) -> ValidationResult {
            return EmailValidator().validate(email)
        }
    }
    
    // OTP Schema
    struct OTP {
        static func validate(code: String) -> ValidationResult {
            return OTPValidator(length: 6).validate(code)
        }
    }
    
    // Registration Schema
    struct Registration {
        static func validate(
            email: String,
            username: String,
            phoneNumber: String
        ) -> [String: ValidationResult] {
            return [
                "email": EmailValidator().validate(email),
                "username": UsernameValidator().validate(username),
                "phoneNumber": PhoneValidator().validate(phoneNumber)
            ]
        }
        
        static func isValid(
            email: String,
            username: String,
            phoneNumber: String
        ) -> Bool {
            let results = validate(email: email, username: username, phoneNumber: phoneNumber)
            return results.values.allSatisfy { $0.isValid }
        }
    }
    
    // Profile Schema
    struct Profile {
        static func validate(
            username: String,
            bio: String?
        ) -> [String: ValidationResult] {
            var results: [String: ValidationResult] = [
                "username": UsernameValidator().validate(username)
            ]
            
            if let bio = bio, !bio.isEmpty {
                if bio.count > 200 {
                    results["bio"] = .failure("La bio ne peut pas dépasser 200 caractères")
                } else {
                    results["bio"] = .success
                }
            }
            
            return results
        }
    }
}

// MARK: - Extension String pour faciliter l'usage
extension String {
    var isValidEmail: Bool {
        EmailValidator().validate(self).isValid
    }
    
    var isValidUsername: Bool {
        UsernameValidator().validate(self).isValid
    }
    
    var isValidPhoneNumber: Bool {
        PhoneValidator().validate(self).isValid
    }
    
    var isValidOTP: Bool {
        OTPValidator().validate(self).isValid
    }
}
