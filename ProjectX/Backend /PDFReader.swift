//
//  PDFReader.swift
//  ProjectX
//
//  Created by Aryan Palit on 12/20/24.
//

import PDFKit
import Foundation

class PDFReader {
    /// Extracts text from a PDF file at the given URL.
    /// - Parameter url: URL of the PDF file.
    /// - Throws: An error if the PDF cannot be loaded or text cannot be extracted.
    /// - Returns: The extracted text as a single string.
    func extractText(from url: URL) throws -> String {
        guard let pdfDocument = PDFDocument(url: url) else {
            throw NSError(domain: "PDFReader", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to load PDF document."])
        }
        
        var extractedText = ""
        
        for pageIndex in 0..<pdfDocument.pageCount {
            guard let page = pdfDocument.page(at: pageIndex) else {
                continue
            }
            if let pageText = page.string {
                extractedText += pageText + "\n"
            }
        }
        
        if extractedText.isEmpty {
            throw NSError(domain: "PDFReader", code: 2, userInfo: [NSLocalizedDescriptionKey: "No text found in PDF."])
        }
        
        return extractedText
    }
}
