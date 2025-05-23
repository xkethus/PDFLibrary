import PDFKit

extension PDFDocument {
    var metadata: [String: String] {
        var data: [String: String] = [:]

        let keys = ["Title", "Author", "Subject", "Keywords", "CreationDate", "Producer"]
        for key in keys {
            if let value = documentAttributes?[PDFDocumentAttribute(rawValue: key)] {
                if let dateValue = value as? Date {
                    let formatter = DateFormatter()
                    formatter.dateStyle = .medium
                    formatter.timeStyle = .none
                    data[key] = formatter.string(from: dateValue)
                } else if let stringValue = value as? String {
                    data[key] = stringValue
                }
            }
        }

        return data
    }
}
