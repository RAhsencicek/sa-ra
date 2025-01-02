

import Foundation

extension Decodable {
    static func decode(
        data: Data?,
        decoder: JSONDecoder = JSONDecoder()
    ) throws -> Self {
        try decoder.decode(Self.self, from: data ?? Data())
    }
}
