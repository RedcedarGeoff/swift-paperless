//
//  Networking.swift
//  swift-paperless
//
//  Created by Paul Gessinger on 18.02.23.
//

import Foundation

let API_TOKEN = "***REMOVED***"
let API_BASE_URL = "https://***REMOVED***/api/"
let API_HOST = "***REMOVED***"

struct Endpoint {
    let path: String
    let queryItems: [URLQueryItem]
}

extension Endpoint {
    static func documents(page: UInt) -> Endpoint {
        return Endpoint(
            path: "api/documents",
            queryItems: [
                URLQueryItem(name: "page", value: String(page)),
            ]
        )
    }

    var url: URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = API_HOST
        components.path = path
        components.queryItems = queryItems
        return components.url
    }
}

func getDocuments(page: UInt) async -> DocumentResponse? {
//    guard let url = Endpoint.documents(page: page).url else {
    guard let url = URL(string: "\(API_BASE_URL)documents/?page=\(page)") else {
        fatalError("Invalid URL")
    }

    print(url)
//    print("Go getDocuments")

    var request = URLRequest(url: url)
    request.setValue("Token \(API_TOKEN)", forHTTPHeaderField: "Authorization")

    do {
        let (data, _) = try await URLSession.shared.data(for: request)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let decoded = try decoder.decode(DocumentResponse.self, from: data)

        return decoded
    } catch {
        print(error)
        return nil
    }
}

func getPreviewImage(documentID: UInt) async -> URL? {
    guard let url =
        URL(string: "\(API_BASE_URL)documents/\(documentID)/download/")
    else {
        return nil
    }

    print(url)

    let request = authRequest(url: url)

    do {
        let (data, response) = try await URLSession.shared.data(for: request)

        if (response as? HTTPURLResponse)?.statusCode != 200 {
            print("Getting image: Status was not 200")
            return nil
        }

        guard let response = response as? HTTPURLResponse else {
            print("Cannot get http response")
            return nil
        }

        guard let suggestedFilename = response.suggestedFilename else {
            print("Cannot get ")
            return nil
        }
//        print(suggestedFilename)

        let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
//        let temporaryFilename = ProcessInfo().globallyUniqueString
        let temporaryFileURL = temporaryDirectoryURL.appendingPathComponent(suggestedFilename)
//        print(temporaryFileURL)

        try data.write(to: temporaryFileURL, options: .atomic)
        try await Task.sleep(for: .seconds(0.2)) // wait a little bit for the data to be flushed
        return temporaryFileURL

    } catch {
        print(error)
        return nil
    }
}
