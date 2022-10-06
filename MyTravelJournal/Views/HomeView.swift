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

struct HomeView: View {
  @State private var showAddDestinationSheet = false
  @Environment(\.managedObjectContext) var managedObjectContext
  @FetchRequest(sortDescriptors: [SortDescriptor(\.createdAt, order: .reverse)])
  var destinations: FetchedResults<Destination>
  private let stack = CoreDataStack.shared

  var body: some View {
    NavigationView {
      // swiftlint:disable trailing_closure
      VStack {
        List {
          ForEach(destinations, id: \.objectID) { destination in
            NavigationLink(destination: DestinationDetailView(destination: destination)) {
              VStack(alignment: .leading) {
                Image(uiImage: UIImage(data: destination.image ?? Data()) ?? UIImage())
                  .resizable()
                  .scaledToFill()

                Text(destination.caption)
                  .font(.title3)
                  .foregroundColor(.primary)

                Text(destination.details)
                  .font(.callout)
                  .foregroundColor(.secondary)
                  .multilineTextAlignment(.leading)

                if stack.isShared(object: destination) {
                  Image(systemName: "person.3.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30)
                }
              }
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
              Button(role: .destructive) {
                stack.delete(destination)
              } label: {
                Label("Delete", systemImage: "trash")
              }
              .disabled(!stack.canDelete(object: destination))
            }
          }
        }
        Spacer()
        Button {
          showAddDestinationSheet.toggle()
        } label: {
          Text("Add Destination")
        }
        .buttonStyle(.borderedProminent)
        .padding(.bottom, 8)
      }
      .emptyState(destinations.isEmpty, emptyContent: {
        VStack {
          Text("No destinations quite yet")
            .font(.headline)
          Button {
            showAddDestinationSheet.toggle()
          } label: {
            Text("Add Destination")
          }
          .buttonStyle(.borderedProminent)
        }
      })
      .sheet(isPresented: $showAddDestinationSheet, content: {
        AddDestinationView()
      })
      .navigationTitle("My Travel Journal")
      .navigationViewStyle(.stack)
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    HomeView()
  }
}

// MARK: Custom view modifier
extension View {
  func emptyState<EmptyContent>(_ isEmpty: Bool, emptyContent: @escaping () -> EmptyContent) -> some View where EmptyContent: View {
    modifier(EmptyStateViewModifier(isEmpty: isEmpty, emptyContent: emptyContent))
  }
}

struct EmptyStateViewModifier<EmptyContent>: ViewModifier where EmptyContent: View {
  var isEmpty: Bool
  let emptyContent: () -> EmptyContent

  func body(content: Content) -> some View {
    if isEmpty {
      emptyContent()
    } else {
      content
    }
  }
}
