//
// ImageListResponse.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

public struct ImageListResponse: Codable, JSONEncodable, Hashable {

    public var apiImages: [ApiImage]

    public init(apiImages: [ApiImage]) {
        self.apiImages = apiImages
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case apiImages
    }

    // Encodable protocol methods

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(apiImages, forKey: .apiImages)
    }
}
