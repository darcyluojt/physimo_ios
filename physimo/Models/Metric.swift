import Foundation
struct Metric: Identifiable, Decodable {
    let id: UUID
    let uploadId: UUID?
    let archetype: Archetype
    var value: Double
    var accuracy: Double?
    var ignored: Bool = false
    var videoTimestamp: Double? = nil
    
    enum CodingKeys: String, CodingKey {
           case id
           case uploadId = "upload_id"  // ← you must include this
           case accuracy
           case archetype
           case value
       }
}
