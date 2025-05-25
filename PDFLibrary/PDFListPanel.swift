import SwiftUI

struct PDFListPanel: View {
    var displayedLibrary: [PDFFile]
    @Binding var selectedCollection: PDFCollection?
    @Binding var selectedPDF: PDFFile?
    @Binding var editableMetadata: [String: String]
    @Binding var isFromLibrary: Bool

    var body: some View {
        VStack(alignment: .leading) {
            Text(selectedCollection?.name ?? "Mi biblioteca")
                .font(.headline)
                .padding()

            List(displayedLibrary) { pdf in
                Text(pdf.metadata?["Title"] ?? pdf.fileName)
                    .onTapGesture {
                        selectedPDF = pdf
                        isFromLibrary = true
                        editableMetadata = pdf.metadata ?? [:]
                    }
            }
        }
        .frame(minWidth: 300)
    }
}
