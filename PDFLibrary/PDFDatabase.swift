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

    // Nuevas tablas para colecciones
    let collections = Table("collections")
    let collectionLinks = Table("collection_links")
    let collectionId = Expression<String>("id")
    let collectionName = Expression<String>("name")
    let collectionsTable = Table("collections")
    let pdfId = Expression<String>("pdf_id")
    let linkCollectionId = Expression<String>("collection_id")
    

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
            // Tabla de colecciones
            try db?.run(collectionsTable.create(ifNotExists: true) { t in
                t.column(collectionId, primaryKey: true)
                t.column(collectionName)
            })

            try db?.run(collectionLinks.create(ifNotExists: true) { t in
                t.column(pdfId)
                t.column(linkCollectionId)
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

    // MARK: - Colecciones

    func insertCollection(name: String) {
        guard let db = db else { return }
        let newId = UUID().uuidString
        do {
            try db.run(collections.insert(collectionId <- newId, collectionName <- name))
        } catch {
            print("Error al insertar colección: \(error)")
        }
    }
    

    func fetchCollections() -> [PDFCollection] {
        guard let db = db else { return [] }
        var result: [PDFCollection] = []
        do {
            for row in try db.prepare(collections) {
                let collection = PDFCollection(
                    id: UUID(uuidString: row[collectionId]) ?? UUID(),
                    name: row[collectionName]
                )
                result.append(collection)
            }
        } catch {
            print("Error al leer colecciones: \(error)")
        }
        return result
    }

    func addPDF(_ pdf: PDFFile, toCollection collection: PDFCollection) {
        guard let db = db else { return }
        do {
            try db.run(collectionLinks.insert(pdfId <- pdf.id.uuidString, linkCollectionId <- collection.id.uuidString))
        } catch {
            print("Error al vincular PDF a colección: \(error)")
        }
    }

    func getPDFs(forCollection collection: PDFCollection) -> [PDFFile] {
        guard let db = db else { return [] }
        var results: [PDFFile] = []

        do {
            let query = collectionLinks
                .filter(linkCollectionId == collection.id.uuidString)
                .select(pdfId)
            
            for row in try db.prepare(query) {
                let fileID = row[pdfId]
                // Consulta directa por ID
                let entry = pdfCatalog.filter(id == fileID)
                if let pdfRow = try db.pluck(entry) {
                    let url = URL(fileURLWithPath: pdfRow[filePath])
                    let meta: [String: String] = [
                        "Title": pdfRow[title],
                        "Author": pdfRow[author],
                        "Subject": pdfRow[subject],
                        "Keywords": pdfRow[keywords],
                        "CreationDate": pdfRow[creationDate],
                        "Producer": pdfRow[producer]
                    ]
                    let pdf = PDFFile(
                        id: UUID(uuidString: pdfRow[id]) ?? UUID(),
                        url: url,
                        metadata: meta
                    )
                    results.append(pdf)
                }
            }
        } catch {
            print("❌ Error al cargar PDFs de colección: \(error)")
        }

        return results
    }

    func removePDFfromAllCollections(pdfID: UUID) {
        guard let db = db else { return }
        let linksToRemove = collectionLinks.filter(self.pdfId == pdfID.uuidString)
        do {
            try db.run(linksToRemove.delete())
            print("🗑️ Colecciones desvinculadas del PDF")
        } catch {
            print("❌ Error al eliminar vínculos: \(error)")
        }
    }
    func unlinkPDF(from collection: PDFCollection, pdf: PDFFile) {
        guard let db = db else { return }
        let entry = collectionLinks
            .filter(linkCollectionId == collection.id.uuidString && pdfId == pdf.id.uuidString)
        do {
            try db.run(entry.delete())
            print("❌ PDF desvinculado de colección: \(collection.name)")
        } catch {
            print("Error al desvincular PDF: \(error)")
        }
    }
    
    func getCollections(forPDF file: PDFFile) -> [PDFCollection] {
        guard let db = db else { return [] }
        var collections: [PDFCollection] = []

        let query = collectionLinks
            .join(collectionsTable, on: collectionsTable[collectionId] == collectionLinks[linkCollectionId])
            .filter(collectionLinks[pdfId] == file.id.uuidString)

        do {
            for row in try db.prepare(query) {
                let idStr = row[collectionsTable[collectionId]]
                if let uuid = UUID(uuidString: idStr) {
                    let name = row[collectionsTable[collectionName]]
                    collections.append(PDFCollection(id: uuid, name: name))
                }
            }
        } catch {
            print("❌ Error al obtener colecciones del PDF: \(error)")
        }

        return collections
    }
    func linkPDFToCollection(pdfID: UUID, collectionID: UUID) {
        guard let db = db else { return }

        let insert = collectionLinks.insert(
            self.pdfId <- pdfID.uuidString,
            self.linkCollectionId <- collectionID.uuidString
        )

        do {
            try db.run(insert)
            print("✅ PDF vinculado a colección")
            print("↪️ Vinculando PDF \(pdfID) a colección \(collectionID)")
        } catch {
            print("❌ Error al vincular PDF a colección: \(error)")
        }
    }

}


