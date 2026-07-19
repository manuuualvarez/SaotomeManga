//
//  DomainValidationTests.swift
//  SaotomeMangaTests
//
//  02-T004: errores tipados del dominio y validadores puros (email, password),
//  con tests parametrizados (`arguments:`) y sin dependencias externas.
//

@testable import SaotomeManga
import Testing

struct EmailValidatorTests {
    @Test(arguments: [
        "user@example.com",
        "USER@EXAMPLE.COM",
        "first.last+tag@sub.domain.co",
        "a_b-c%d@my-server.io",
    ])
    func `accepts valid emails`(email: String) {
        #expect(EmailValidator.isValid(email))
    }

    @Test(arguments: [
        "",
        "plainaddress",
        "@missing-local.org",
        "user@",
        "user@domain",
        "user@@example.com",
        "user@.com",
        "user name@example.com",
        "user@example.c",
    ])
    func `rejects invalid emails`(email: String) {
        #expect(!EmailValidator.isValid(email))
    }

    // 02-T004: la variante que lanza produce el error tipado del dominio.
    @Test func `validate throws typed domain error`() {
        #expect(throws: DomainError.invalidEmail) {
            try EmailValidator.validate("not-an-email")
        }
        #expect(throws: Never.self) {
            try EmailValidator.validate("user@example.com")
        }
    }
}

struct PasswordPolicyTests {
    /// Constitución §6: longitud mínima 8 — 7 caracteres falla, 8 pasa.
    @Test(arguments: ["1234567", "", "abc", "siete77"])
    func `rejects passwords shorter than eight`(password: String) {
        #expect(!PasswordPolicy.isValid(password))
    }

    @Test(arguments: ["12345678", "ochoocho", "una frase larga y segura"])
    func `accepts passwords of eight or more`(password: String) {
        #expect(PasswordPolicy.isValid(password))
    }

    @Test func `validate throws typed domain error with minimum`() {
        #expect(throws: DomainError.weakPassword(minimumLength: 8)) {
            try PasswordPolicy.validate("corta")
        }
        #expect(throws: Never.self) {
            try PasswordPolicy.validate("12345678")
        }
    }
}

struct DomainErrorTests {
    // 02-T004: DomainError distingue causas y es Equatable para afirmarlo en tests.
    @Test func `domain error cases are distinguishable`() {
        #expect(DomainError.notFound == DomainError.notFound)
        #expect(DomainError.mapping(field: "mainPicture") == DomainError.mapping(field: "mainPicture"))
        #expect(DomainError.mapping(field: "mainPicture") != DomainError.mapping(field: "url"))
        #expect(DomainError.invalidEmail != DomainError.notFound)
    }
}
