//
//  User.swift
//  BeRealClone
//
//  Created by Chris on 5/3/23.
//

import Foundation
import ParseSwift

struct User: ParseUser {
    
    
    // These are required by `ParseObject`.
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?
    var originalData: Data?

    // These are required by `ParseUser`.
    var username: String?
    var email: String?
    var emailVerified: Bool?
    var password: String?
    var authData: [String: [String: String]?]?

    // Your custom properties.
    // var customKey: String?
    var dateLastPostedAt: Date?
}
