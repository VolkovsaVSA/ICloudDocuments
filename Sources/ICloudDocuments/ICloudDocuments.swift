//  Created by Sergei Volkov on 18.09.2021.
//

import Foundation

public class ICloudDocuments: ObservableObject {
    /// A single class instance initializer. Pass the desired parameters for the container configuration.
    ///
    /// **iCloudFolder** - Choose specific folder where be saved files. If you choose "iCloudDocumentsFolder" then files while be saved in visible folder "Documents". If you choose "mainHiddenFolder" then files while be saved in invisible folder "Backup".
    ///
    /// **groupName** - Specify the "groupName" parameter if you are using App Groups.
    public init(
        iCloudFolder: ICloudFolder = .iCloudDocumentsFolder,
        groupName: String? = nil
    ) {
        self.groupName = groupName
        self.iCloudFolder = iCloudFolder
    }
    private let groupName: String?
    private let iCloudFolder: ICloudFolder

    private var containerUrl: URL? {
        if let groupNameUnwrap = groupName {
            FileManager
                .default
                .containerURL(forSecurityApplicationGroupIdentifier: groupNameUnwrap)?
                .appendingPathComponent(iCloudFolder.rawValue)
        } else {
            FileManager
                .default
                .url(forUbiquityContainerIdentifier: nil)?
                .appendingPathComponent(iCloudFolder.rawValue)
        }
    }
    
    /// **iCloud Folder type**
    ///
    /// **mainHiddenFolder** is a hidden folder in iCloud
    ///
    /// **iCloudDocumentsFolder** is an open folder in the Documents folder in iCloud
    public enum ICloudFolder: String {
        case mainHiddenFolder = "Backup"
        case iCloudDocumentsFolder = "Documents"
    }
    
    /// **iCloud erros**
    ///
    /// **iCloudAccessDenied** - no access to iCloud
    /// 
    /// **noFilesInContainer** - no files
    ///
    /// **fileNotFound** - specified file not found in iCloud
    public enum ICloudError: Error {
        case iCloudAccessDenied
        case noFilesInContainer
        case fileNotFound
    }
    
    //public functions
    /// The function checks for the presence of files in the iCloud container. The closure returns a list of files.
    public func checkFilesInIcloud(completion: @escaping (Result<[String], Error>) -> Void) {
        if let container = containerUrl {
            if let containerFiles = try? FileManager().contentsOfDirectory(
                at: container,
                includingPropertiesForKeys: nil,
                options: .skipsHiddenFiles
            ) {
                if containerFiles.isEmpty {
                    completion(.failure(ICloudError.noFilesInContainer))
                } else {
                    var files = [String]()
                    containerFiles.forEach { containerFileUrl in
                        if let fileName = containerFileUrl.path.components(separatedBy: "/").last {
                            files.append(fileName)
                        }
                    }
                    completion(.success(files))
                }
            } else {
                completion(.failure(ICloudError.iCloudAccessDenied))
            }
        }
    }
    
    /// The function saves files in the iCloud container. The closure returns a list of saved files.
    ///
    /// Pass an array of file paths to save to the **localFilePaths** parameter.
    public func saveFilesToICloudDocuments(
        localFilePaths: [String],
        completion: @escaping (Result<[String], Error>) -> Void
    ) {
        var files = [String]()
        localFilePaths.forEach { filePath in
            if let fileName = filePath.components(separatedBy: "/").last {
                do {
                    try copyFileToICloud(localPath: filePath, fileName: fileName)
                } catch {
                    completion(.failure(error))
                    return
                }
                files.append(fileName)
            }
        }
        if !files.isEmpty {
            completion(.success(files))
        }
        
    }
    
    /// Files in the iCloud container may be in an undownloaded state, so before copying from the container, you must start downloading files to the container.
    private func startDownloadFiles(completion: @escaping(Error?) -> Void) {
        if let container = containerUrl {
            do {
                try FileManager.default.startDownloadingUbiquitousItem(at: container)
            } catch {
                completion(error)
            }
        }
    }
    
    /// Copying files from the iCloud container to a local folder on the device.
    ///
    /// In the **localFolder** parameter, pass the URL of the local folder to save files.
    public func downloadAllFilesFromIcloud(localFolder: URL, completion: @escaping (Error?) -> Void) {
        if let container = containerUrl {
            
            startDownloadFiles { downloadError in
                completion(downloadError)
                return
            }
            
            if let containerFiles = try? FileManager().contentsOfDirectory(at: container, includingPropertiesForKeys: nil, options: .skipsHiddenFiles) {
                if containerFiles.isEmpty {
                    completion(ICloudError.noFilesInContainer)
                } else {
                    containerFiles.forEach { containerFileUrl in
                        if let fileName = containerFileUrl.path.components(separatedBy: "/").last {
                            if FileManager.default.fileExists(atPath: localFolder.appendingPathComponent(fileName).path) {
                                do {
                                    try removeOldFile(path: localFolder.appendingPathComponent(fileName).path)
                                } catch let removeError {
                                    print(removeError, #function, #line)
                                    completion(removeError)
                                    return
                                }
                            }
                            do {
                                try FileManager.default.copyItem(
                                    atPath: containerFileUrl.path,
                                    toPath: localFolder.appendingPathComponent(fileName).path
                                )
                                print("copy file: \(fileName)")
                            } catch {
                                completion(error)
                                return
                            }
                            
                        }
                        
                    }
                    completion(nil)
                }
            }
            
        } else {
            completion(ICloudError.iCloudAccessDenied)
        }
    }
    
    /// The function deletes files from the iCloud container.
    ///
    /// Pass an array of file names to delete to the **fileNames** parameter.
    public func deleteFilesFromICloud(
        fileNames: [String],
        completion: @escaping (Result<[String], Error>) -> Void
    ) {
        var deletedFiles = [String]()
        
        guard let container = containerUrl else {
            completion(.failure(ICloudError.iCloudAccessDenied))
            return
        }
        
        for fileName in fileNames {
            let fileUrl = container.appendingPathComponent(fileName)
            do {
                if FileManager.default.fileExists(atPath: fileUrl.path) {
                    try FileManager.default.removeItem(at: fileUrl)
                    deletedFiles.append(fileName)
                } else {
                    completion(.failure(ICloudError.fileNotFound))
                    return
                }
            } catch {
                completion(.failure(error))
                return
            }
        }
        
        completion(.success(deletedFiles))
    }
    
    //internal functions
    private func urlFileToCopy(fileName: String) -> URL? {
        containerUrl?.appendingPathComponent(fileName)
    }
    private func createDirectoryInICloud() throws {
        if let url = containerUrl {
            if !FileManager.default.fileExists(atPath: url.path, isDirectory: nil) {
                do {
                    try FileManager
                        .default
                        .createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
                } catch let directoryError {
                    print(directoryError, #function, #line)
                    throw directoryError
                }
            }
        } else {
            throw ICloudError.iCloudAccessDenied
        }
    }
    private func copyFileToICloud(localPath: String, fileName: String) throws {
        do {
            try createDirectoryInICloud()
        } catch let copyError {
            print(copyError, #function, #line)
            throw copyError
        }
        guard let urlFileName = urlFileToCopy(fileName: fileName) else {
            throw ICloudError.iCloudAccessDenied
        }
        
        if FileManager.default.fileExists(atPath: localPath) {
            do {
                try removeOldFile(path: urlFileName.path)
            } catch let removeError {
                print(removeError, #function, #line)
                throw removeError
            }
        }
        do {
            try FileManager.default.copyItem(atPath: localPath, toPath: urlFileName.path)
            print("file \"\(fileName)\" copy to \(urlFileName.path) is ok")
        } catch {
            print("error copy file '\(fileName)' to iCloud - " + error.localizedDescription)
            throw error
        }
        
    }
    private func removeOldFile (path: String) throws {
        var isDir:ObjCBool = false
        if FileManager.default.fileExists(atPath: path, isDirectory: &isDir) {
            do {
                try FileManager.default.removeItem(atPath: path)
            } catch {
               throw error
            }
        }
    }

    // MARK: - Async Methods
    
    /// The function checks for the presence of files in the iCloud container. Returns Result with a list of files or error.
    public func checkFilesInIcloud() async -> Result<[String], Error> {
        return await withCheckedContinuation { (continuation: CheckedContinuation<Result<[String], Error>, Never>) in
            checkFilesInIcloud { result in
                continuation.resume(returning: result)
            }
        }
    }
    
    /// The function saves files in the iCloud container. Returns a list of saved files.
    ///
    /// Pass an array of file paths to save to the **localFilePaths** parameter.
    public func saveFilesToICloudDocuments(localFilePaths: [String]) async throws -> [String] {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[String], Error>) in
            saveFilesToICloudDocuments(localFilePaths: localFilePaths) { result in
                switch result {
                case .success(let files): continuation.resume(returning: files)
                case .failure(let error): continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// The function saves files in the iCloud container. Returns Result with a list of saved files or error.
    ///
    /// Pass an array of file paths to save to the **localFilePaths** parameter.
    public func saveFilesToICloudDocuments(localFilePaths: [String]) async -> Result<[String], Error> {
        return await withCheckedContinuation { (continuation: CheckedContinuation<Result<[String], Error>, Never>) in
            saveFilesToICloudDocuments(localFilePaths: localFilePaths) { result in
                continuation.resume(returning: result)
            }
        }
    }
    
    /// Copying files from the iCloud container to a local folder on the device.
    ///
    /// In the **localFolder** parameter, pass the URL of the local folder to save files.
    public func downloadAllFilesFromIcloud(localFolder: URL) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            downloadAllFilesFromIcloud(localFolder: localFolder) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    /// Copying files from the iCloud container to a local folder on the device.
    /// Returns Result with void or error.
    ///
    /// In the **localFolder** parameter, pass the URL of the local folder to save files.
    public func downloadAllFilesFromIcloud(localFolder: URL) async -> Result<Void, Error> {
        return await withCheckedContinuation { (continuation: CheckedContinuation<Result<Void, Error>, Never>) in
            downloadAllFilesFromIcloud(localFolder: localFolder) { error in
                if let error {
                    continuation.resume(returning: .failure(error))
                } else {
                    continuation.resume(returning: .success(()))
                }
            }
        }
    }
    
    /// The function deletes files from the iCloud container.
    ///
    /// Pass an array of file names to delete to the **fileNames** parameter.
    public func deleteFilesFromICloud(fileNames: [String]) async throws -> [String] {
        return try await withCheckedThrowingContinuation { continuation in
            deleteFilesFromICloud(fileNames: fileNames) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    /// The function deletes files from the iCloud container.
    ///
    /// Pass an array of file names to delete to the **fileNames** parameter.
    public func deleteFilesFromICloud(fileNames: [String]) async -> Result<[String], Error> {
        return await withCheckedContinuation { continuation in
            deleteFilesFromICloud(fileNames: fileNames) { result in
                continuation.resume(returning: result)
            }
        }
    }
}

extension ICloudDocuments.ICloudError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .iCloudAccessDenied:
            NSLocalizedString("Access denied to iCloud. Please sign into your iCloud account in to iPhone. Check internet connection.", comment: "error description")
        case .noFilesInContainer:
            NSLocalizedString("No files in iCloud", comment: "error description")
        case .fileNotFound:
            NSLocalizedString("Specified file not found in iCloud", comment: "error description")
        }
    }
}
