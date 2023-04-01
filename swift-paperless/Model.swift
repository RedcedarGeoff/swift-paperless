//
//  Model.swift
//  swift-paperless
//
//  Created by Paul Gessinger on 18.02.23.
//

import AsyncAlgorithms
import Combine
import Foundation
import OrderedCollections
import Semaphore
import SwiftUI

struct Document: Identifiable, Equatable, Hashable, Model {
    var id: UInt
    var title: String
    var documentType: UInt?
    var correspondent: UInt?
    var created: Date
    var tags: [UInt]

    private(set) var added: String? = nil
    private(set) var storagePath: String? = nil
}

struct ProtoDocument: Codable {
    var title: String = ""
    var documentType: UInt? = nil
    var correspondent: UInt? = nil
    var tags: [UInt] = []
    var created: Date = .now
}

extension Document: Codable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(added, forKey: .added)
        try container.encode(title, forKey: .title)
        try container.encode(documentType, forKey: .documentType)
        try container.encode(correspondent, forKey: .correspondent)
        try container.encode(created, forKey: .created)
        try container.encode(tags, forKey: .tags)
        try container.encode(storagePath, forKey: .storagePath)
    }
}

struct Correspondent: Codable, Identifiable, Model {
    var id: UInt
    var documentCount: UInt
    var isInsensitive: Bool
    var lastCorrespondence: Date?
    // match?
    var name: String
    var slug: String
}

struct DocumentType: Codable, Identifiable, Model {
    var id: UInt
    var name: String
    var slug: String
}

struct Tag: Codable, Identifiable, Model {
    var id: UInt
    var isInboxTag: Bool
    var name: String
    var slug: String
    @HexColor var color: Color
    @HexColor var textColor: Color

    static func placeholder(_ length: Int) -> Tag {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let name = String((0 ..< length).map { _ in letters.randomElement()! })
        return .init(id: 0, isInboxTag: false, name: name, slug: "", color: Color.systemGroupedBackground, textColor: .white)
    }
}

extension Tag: Equatable, Hashable {
    static func == (lhs: Tag, rhs: Tag) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct FilterState: Equatable, Codable {
    enum Filter: Equatable, Hashable, Codable {
        case any
        case notAssigned
        case only(id: UInt)
    }

    enum Tag: Equatable, Hashable, Codable {
        case any
        case notAssigned
        case only(ids: [UInt])
    }

    var correspondent: Filter = .any
    var documentType: Filter = .any
    var tags: Tag = .any

    init(correspondent: Filter = .any, documentType: Filter = .any, tags: Tag = .any) {
        self.correspondent = correspondent
        self.documentType = documentType
        self.tags = tags
    }

    private var query: String?
    var searchText: String? {
        get { query }
        set(value) {
            query = value == "" ? nil : value
        }
    }

    var filtering: Bool {
        return documentType != .any || correspondent != .any || tags != .any
    }

    var count: Int {
        var result = 0
        if documentType != .any {
            result += 1
        }
        if correspondent != .any {
            result += 1
        }
        if tags != .any {
            result += 1
        }

        return result
    }

    mutating func clear() {
        documentType = .any
        correspondent = .any
        tags = .any
    }
}

class DocumentStore: ObservableObject {
    @Published var documents: [UInt: Document] = [:]
    @Published private(set) var correspondents: [UInt: Correspondent] = [:]
    @Published private(set) var documentTypes: [UInt: DocumentType] = [:]
    @Published private(set) var tags: [UInt: Tag] = [:]

//    @Published var filterState = FilterState()

    private var documentSource: any DocumentSource

    let semaphore = AsyncSemaphore(value: 1)

    private(set) var repository: Repository

    func clearDocuments() {
        documents = [:]
    }

    private var tasks = Set<AnyCancellable>()

    var filterStatePublisher =
        PassthroughSubject<FilterState, Never>()

    var filterState: FilterState {
        get {
//            print("GETTING!")
            guard let data = UserDefaults(suiteName: "group.com.paulgessinger.swift-paperless")!.object(forKey: "GlobalFilterState") as? Data else {
                print("No default")
                return FilterState()
            }
//            print(String(data: data, encoding: .utf8))
            guard let value = try? JSONDecoder().decode(FilterState.self, from: data) else {
                print("No decode")
                return FilterState()
            }
//            print("GOT: \(value)")
            return value
        }

        set {
//            print("SET: \(newValue)")
            guard let s = try? JSONEncoder().encode(newValue) else {
                print("NO ENCODE")
                return
            }
//            print(String(data: s, encoding: .utf8))
            UserDefaults(suiteName: "group.com.paulgessinger.swift-paperless")!.set(s, forKey: "GlobalFilterState")
            filterStatePublisher.send(newValue)
        }
    }

    init(repository: Repository) {
        self.repository = repository
        documentSource = repository.documents(filter: FilterState())

        Task {
            async let _ = await fetchAllTags()
            async let _ = await fetchAllCorrespondents()
            async let _ = await fetchAllDocumentTypes()
        }

//        Task { await MainActor.run { self.filterState = persistentFilterState }}

//        $filterState.sink(receiveValue: { value in
//            self.persistentFilterState = value
//        })
//        .store(in: &tasks)
    }

    func set(repository: Repository) {
        self.repository = repository
    }

    @MainActor
    func updateDocument(_ document: Document) async throws {
        documents[document.id] = document
        try await repository.updateDocument(document)
    }

    @MainActor
    func deleteDocument(_ document: Document) async throws {
        try await repository.deleteDocument(document)
        documents.removeValue(forKey: document.id)
    }

    @MainActor
    func documentBinding(id: UInt) -> Binding<Document> {
        let binding: Binding<Document> = .init(get: { self.documents[id]! }, set: { self.documents[id] = $0 })
        return binding
    }

    @MainActor
    func fetchDocuments(clear: Bool, pageSize: UInt = 30) async -> [Document] {
        await semaphore.wait()
        defer { semaphore.signal() }

        if clear {
            documentSource = repository.documents(filter: filterState)
        }

        let result = await documentSource.fetch(limit: pageSize)
        var copy = documents
        for document in result {
            copy[document.id] = document
        }
        documents = copy

        return result
    }

    func hasMoreDocuments() async -> Bool {
        return await documentSource.hasMore()
    }

    @MainActor
    func fetchAllCorrespondents() async {
        await fetchAll(elements: await repository.correspondents(),
                       collection: \.correspondents)
    }

    @MainActor
    func fetchAllDocumentTypes() async {
        await fetchAll(elements: await repository.documentTypes(),
                       collection: \.documentTypes)
    }

    @MainActor
    func fetchAllTags() async {
        await fetchAll(elements: await repository.tags(),
                       collection: \.tags)
    }

    @MainActor
    func fetchAll() async {
        async let c: () = fetchAllCorrespondents()
        async let d: () = fetchAllDocumentTypes()
        async let t: () = fetchAllTags()
        _ = await (c, d, t)
    }

    @MainActor
    private func fetchAll<T>(elements: [T],
                             collection: ReferenceWritableKeyPath<DocumentStore, [UInt: T]>) async
        where T: Decodable, T: Identifiable, T.ID == UInt, T: Model
    {
        var copy = self[keyPath: collection]

        for element in elements {
            copy[element.id] = element
        }

        self[keyPath: collection] = copy
    }

    @MainActor
    private func getSingleCached<T>(
        //        _ type: T.Type,
        get: (UInt) async -> T?, id: UInt, cache: ReferenceWritableKeyPath<DocumentStore, [UInt: T]>
    ) async -> (Bool, T)? where T: Decodable, T: Model {
        if let element = self[keyPath: cache][id] {
            return (true, element)
        }

        guard let element = await get(id) else {
            return nil
        }

        self[keyPath: cache][id] = element
        return (false, element)
    }

    @MainActor
    func getCorrespondent(id: UInt) async -> (Bool, Correspondent)? {
        return await getSingleCached(get: { await repository.correspondent(id: $0) }, id: id,
                                     cache: \.correspondents)
    }

    @MainActor
    func getDocumentType(id: UInt) async -> (Bool, DocumentType)? {
        return await getSingleCached(get: { await repository.documentType(id: $0) }, id: id,
                                     cache: \.documentTypes)
    }

    @MainActor
    func document(id: UInt) async -> Document? {
        return await repository.document(id: id)
    }

    @MainActor
    func getTag(id: UInt) async -> (Bool, Tag)? {
        return await getSingleCached(get: { await repository.tag(id: $0) }, id: id,
                                     cache: \.tags)
    }

    @MainActor
    func getTags(_ ids: [UInt]) async -> (Bool, [Tag]) {
        var tags: [Tag] = []
        var allCached = true
        for id in ids {
            if let (cached, tag) = await getTag(id: id) {
                tags.append(tag)
                allCached = allCached && cached
            }
        }
        return (allCached, tags)
    }
}
