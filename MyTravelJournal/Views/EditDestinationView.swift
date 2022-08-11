/// Copyright (c) 2022 Razeware LLC
/// 
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
/// 
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
/// 
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
/// 
/// This project and source code may use libraries or frameworks that are
/// released under various Open-Source licenses. Use of those libraries and
/// frameworks are governed by their own individual licenses.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import SwiftUI

struct EditDestinationView: View {
  let destination: Destination
  private var stack = CoreDataStack.shared
  private var hasInvalidData: Bool {
    return destination.caption.isBlank ||
    destination.details.isBlank ||
    (destination.caption == captionText && destination.details == detailsText)
  }

  @State private var captionText: String = ""
  @State private var detailsText: String = ""
  @Environment(\.presentationMode) var presentationMode
  @Environment(\.managedObjectContext) var managedObjectContext

  init(destination: Destination) {
    self.destination = destination
  }

  var body: some View {
    NavigationView {
      VStack {
        VStack(alignment: .leading) {
          Text("Caption")
            .font(.caption)
            .foregroundColor(.secondary)
          TextField(text: $captionText) {}
            .textFieldStyle(.roundedBorder)
        }
        .padding(.bottom, 8)

        VStack(alignment: .leading) {
          Text("Details")
            .font(.caption)
            .foregroundColor(.secondary)
          TextEditor(text: $detailsText)
        }
      }
      .padding()
      .navigationTitle("Edit Destination")
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button {
            managedObjectContext.performAndWait {
              destination.caption = captionText
              destination.details = detailsText
              stack.save()
              presentationMode.wrappedValue.dismiss()
            }
          } label: {
            Text("Save")
          }
          .disabled(hasInvalidData)
        }
        ToolbarItem(placement: .navigationBarLeading) {
          Button {
            presentationMode.wrappedValue.dismiss()
          } label: {
            Text("Cancel")
          }
        }
      }
    }
    .onAppear {
      captionText = destination.caption
      detailsText = destination.details
    }
  }
}

// MARK: String
extension String {
  var isBlank: Bool {
    self.trimmingCharacters(in: .whitespaces).isEmpty
  }
}
