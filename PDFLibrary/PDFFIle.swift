import Foundation
struct PDFFile: Identifiable {
    let id: UUID
    let url: URL
    var metadata: [String: String]?

    var fileName: String {
        metadata?["Title"] ?? url.lastPathComponent
    }

    init(id: UUID = UUID(), url: URL, metadata: [String: String]? = nil) {
        self.id = id
        self.url = url
        self.metadata = metadata
    }
}
