//
//  ParsedReader.swift
//  Project X
//
//  Created by Aryan Palit on 12/20/24.
//
import SwiftUI

struct ParsedTextView: View {
    let text: String
    let title: String
    
    var body: some View {
        VStack {
            Text("Extracted Text")
                .font(.headline)
                .padding()
            
            Divider()
            
            ScrollView {
                Text(text)
                    .padding()
                    .font(.body)
            }
        }
        .frame(minWidth: 400, minHeight: 300)
    }
}

struct ParsedTextView_Previews: PreviewProvider {
    static var previews: some View {
        ParsedTextView(text: "Sample extracted text from PDF.", title: "Sample PDF")
    }
}


