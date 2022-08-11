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

import CoreData
import CloudKit

final class CoreDataStack: ObservableObject {
  static let shared = CoreDataStack()
  
  var ckContainer: CKContainer {
    let storeDescription = persistentContainer.persistentStoreDescriptions.first
    guard let identifier = storeDescription?
      .cloudKitContainerOptions?.containerIdentifier else {
      fatalError("Unable to get container identifier")
    }
    return CKContainer(identifier: identifier)
  }

  var context: NSManagedObjectContext {
    persistentContainer.viewContext
  }

  var privatePersistentStore: NSPersistentStore {
    guard let privateStore = _privatePersistentStore else {
      fatalError("Private store is not set")
    }
    return privateStore
  }

  var sharedPersistentStore: NSPersistentStore {
    guard let sharedStore = _sharedPersistentStore else {
      fatalError("Shared store is not set")
    }
    return sharedStore
  }

  lazy var persistentContainer: NSPersistentCloudKitContainer = {
    let container = NSPersistentCloudKitContainer(name: "MyTravelJournal")

    guard let privateStoreDescription = container.persistentStoreDescriptions.first else {
      fatalError("Unable to get persistentStoreDescription")
    }
    let storesURL = privateStoreDescription.url?.deletingLastPathComponent()
    privateStoreDescription.url = storesURL?.appendingPathComponent("private.sqlite")

    // TODO: 1
    let sharedStoreURL = storesURL?.appendingPathComponent("shared.sqlite")
    guard let sharedStoreDescription = privateStoreDescription
      .copy() as? NSPersistentStoreDescription else {
      fatalError(
        "Copying the private store description returned an unexpected value."
      )
    }
    sharedStoreDescription.url = sharedStoreURL
    
    // TODO: 2
    guard let containerIdentifier = privateStoreDescription
      .cloudKitContainerOptions?.containerIdentifier else {
      fatalError("Unable to get containerIdentifier")
    }
    let sharedStoreOptions = NSPersistentCloudKitContainerOptions(
      containerIdentifier: containerIdentifier
    )
    sharedStoreOptions.databaseScope = .shared
    sharedStoreDescription.cloudKitContainerOptions = sharedStoreOptions

    // TODO: 3
    container.persistentStoreDescriptions.append(sharedStoreDescription)

    // TODO: 4
//    container.loadPersistentStores { _, error in
//      if let error = error as NSError? {
//        fatalError("Failed to load persistent stores: \(error)")
//      }
//    }

    container.loadPersistentStores { loadedStoreDescription, error in
      if let error = error as NSError? {
        fatalError("Failed to load persistent stores: \(error)")
      } else if let cloudKitContainerOptions = loadedStoreDescription
        .cloudKitContainerOptions {
        guard let loadedStoreDescritionURL = loadedStoreDescription.url else {
          return
        }
        if cloudKitContainerOptions.databaseScope == .private {
          let privateStore = container.persistentStoreCoordinator
            .persistentStore(for: loadedStoreDescritionURL)
          self._privatePersistentStore = privateStore
        } else if cloudKitContainerOptions.databaseScope == .shared {
          let sharedStore = container.persistentStoreCoordinator
            .persistentStore(for: loadedStoreDescritionURL)
          self._sharedPersistentStore = sharedStore
        }
      }
    }

    //
    
    container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    container.viewContext.automaticallyMergesChangesFromParent = true
    return container
  }()

  private var _privatePersistentStore: NSPersistentStore?
  private var _sharedPersistentStore: NSPersistentStore?
  private init() {}
}

// MARK: Save or delete from Core Data
extension CoreDataStack {
  func save() {
    if context.hasChanges {
      do {
        try context.save()
      } catch {
        print("ViewContext save error: \(error)")
      }
    }
  }

  func delete(_ destination: Destination) {
    context.perform {
      self.context.delete(destination)
      self.save()
    }
  }
  
  private func isShared(objectID: NSManagedObjectID) -> Bool {
    var isShared = false
    if let persistentStore = objectID.persistentStore {
      if persistentStore == sharedPersistentStore {
        isShared = true
      } else {
        let container = persistentContainer
        do {
          let shares = try container.fetchShares(matching: [objectID])
          if shares.first != nil {
            isShared = true
          }
        } catch {
          print("Failed to fetch share for \(objectID): \(error)")
        }
      }
    }
    return isShared
  }
  
  func isShared(object: NSManagedObject) -> Bool {
    isShared(objectID: object.objectID)
  }
}
