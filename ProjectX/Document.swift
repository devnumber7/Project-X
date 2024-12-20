//
//  Item.swift
//  ProjectX
//
//  Created by Aryan Palit on 12/20/24.
//

import Foundation
import SwiftData

@Model
class Document: Identifiable {
    var id: UUID
    var timestamp: Date
    var pdfURL: URL?

    init(id: UUID = UUID(), timestamp: Date, pdfURL: URL? = nil) {
        self.id = id
        self.timestamp = timestamp
        self.pdfURL = pdfURL
    }

    func getDocumentName() -> String? {
        guard let pdfURL = pdfURL else { return nil }
        let name = pdfURL.lastPathComponent
        if let nameWithoutExtension = name.split(separator: ".").first {
            return String(nameWithoutExtension)
        }
        return name
    }
}

