//
//  Item.swift
//  Sesame
//
//  Created by Greg on 2026-03-12.
//

import Foundation
import SwiftData

@Model
final class AccessCode {
    var id: UUID?
    var label: String?
    var code: String?
    var address: String?
    var latitude: Double?
    var longitude: Double?
    var radiusMeters: Double?
    var isSilenced: Bool?
    var locationDetails: String?
    var comment: String?
    var schemaVersion: Int?

    init(
        label: String,
        code: String? = nil,
        address: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        radiusMeters: Double = 100.0,
        isSilenced: Bool = false,
        locationDetails: String? = nil,
        comment: String? = nil
    ) {
        self.id = UUID()
        self.label = label
        self.code = code
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.radiusMeters = radiusMeters
        self.isSilenced = isSilenced
        self.locationDetails = locationDetails
        self.comment = comment
        self.schemaVersion = 3
    }
}
