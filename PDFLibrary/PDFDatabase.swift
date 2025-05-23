import Foundation
import SQLite

class PDFDatabase {
    static let shared = PDFDatabase()
    private var db: Connection?

    // Tabla y columnas
    let pdfCatalog = Table("pdf_catalog")

    let id = Expression<String>("id")
    let filePath = Expression<String>("file_path")
    let title = Expression<String>("title")
    let author = Expression<String>("author")
    let subject = Expression<String>("subject")
    let keywords = Expression<String>("keywords")
    let creationDate = Expression<String>("creation_date")
    let producer = Expression<String>("producer")

    private init() {
        connect()
    }

    func connect() {
        do {
            let path = FileManager.default
                .urls(for: .applicationSupportDirectory, in: .userDomainMask)
                .first!
                .appendingPathComponent("PDFLibrary.sqlite")
            
            db = try Connection(path.path)

            try db?.run(pdfCatalog.create(ifNotExists: true) { t in
                t.column(id, primaryKey: true)
                t.column(filePath)
                t.column(title)
                t.column(author)
                t.column(subject)
                t.column(keywords)
                t.column(creationDate)
                t.column(producer)
            })

            print("✅ Base de datos creada en: \(path.path)")
        } catch {
            print("🔴 Error al conectar o crear tabla: \(error)")
        }
    }

    func insertPDF(file: PDFFile, meta: [String: String]) {
        guard let db = db else { return }
        do {
            try db.run(pdfCatalog.insert(
                id <- file.id.uuidString,
                filePath <- file.url.path,
                title <- meta["Title"] ?? "",
                author <- meta["Author"] ?? "",
                subject <- meta["Subject"] ?? "",
                keywords <- meta["Keywords"] ?? "",
                creationDate <- meta["CreationDate"] ?? "",
                producer <- meta["Producer"] ?? ""
            ))
            print("📥 PDF insertado: \(file.fileName)")
        } catch {
            print("🔴 Error al insertar PDF: \(error)")
        }
    }
    func updatePDF(file: PDFFile, meta: [String: String]) {
        guard let db = db else { return }

        let entry = pdfCatalog.filter(id == file.id.uuidString)

        do {
            try db.run(entry.update(
                filePath <- file.url.path,
                title <- meta["Title"] ?? "",
                author <- meta["Author"] ?? "",
                subject <- meta["Subject"] ?? "",
                keywords <- meta["Keywords"] ?? "",
                creationDate <- meta["CreationDate"] ?? "",
                producer <- meta["Producer"] ?? ""
            ))
            print("✏️ PDF actualizado en base de datos: \(file.fileName)")
        } catch {
            print("🔴 Error al actualizar PDF: \(error)")
        }
    }
    func fetchAllPDFs() -> [PDFFile] {
        guard let db = db else { return [] }
        var results: [PDFFile] = []

        do {
            for row in try db.prepare(pdfCatalog) {
                let url = URL(fileURLWithPath: row[filePath])
                let meta: [String: String] = [
                    "Title": row[title],
                    "Author": row[author],
                    "Subject": row[subject],
                    "Keywords": row[keywords],
                    "CreationDate": row[creationDate],
                    "Producer": row[producer]
                ]
                let pdf = PDFFile(
                    id: UUID(uuidString: row[id]) ?? UUID(),
                    url: url,
                    metadata: meta
                )
                results.append(pdf)
            }
        } catch {
            print("Error al leer de la base: \(error)")
        }

        return results
    }

    func deletePDF(file: PDFFile) {
        guard let db = db else { return }
        let entry = pdfCatalog.filter(id == file.id.uuidString)
        do {
            try db.run(entry.delete())
            print("🗑 Registro eliminado: \(file.fileName)")
        } catch {
            print("❌ Error al eliminar: \(error)")
        }
    }





}
