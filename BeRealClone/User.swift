//
//  User.swift
//  BeRealClone
//
//  Created by Raul Henriquez on 9/20/26.
//

import Foundation
import ParseSwift

// Mirrors the Parse "_User" class. Conforming to ParseUser gives us
// signup/login/logout plus automatic session persistence for free.
struct User: ParseUser {
    // Required by ParseObject
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?

    // Required by ParseUser
    var username: String?
    var email: String?
    var emailVerified: Bool?
    var password: String?
    var authData: [String: [String: String]?]?

    // Custom columns we added on top of the default _User class.
    var profileImage: ParseFile?
    var bio: String?
}
