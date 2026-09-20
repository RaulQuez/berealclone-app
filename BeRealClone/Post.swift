//
//  Post.swift
//  BeRealClone
//
//  Created by Raul Henriquez on 9/20/26.
//

import Foundation
import ParseSwift

// Maps to a "Post" class on the server: one photo a user shares to the feed.
struct Post: ParseObject {
    // Required by ParseObject
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?

    var user: User?
    var imageFile: ParseFile?
    var caption: String?

    // Pulled from the original photo's metadata at upload time so the feed
    // can show where/when it was actually taken, not just when it was posted.
    var photoTakenAt: Date?
    var latitude: Double?
    var longitude: Double?
    var locationName: String?
}
