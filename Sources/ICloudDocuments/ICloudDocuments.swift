//  Created by Sergei Volkov on 18.09.2021.
//

import Foundation

public class ICloudDocuments: ObservableObject {
    /// A single class instance initializer. Pass the desired parameters for the container configuration.
    ///
    /// **iCloudFolder** - Choose specific folder where be saved files. If you choose "iCloudDocumentsFolder" then files while be saved in visible folder "Documents". If you choose "mainHiddenFolder" then files while be saved in invisible folder "Backup".
    ///
    /// **groupName** - Specify the "groupName" parameter if you are using App Groups.
    ///
    /// **fileManager** - FileManager instance to use for file operations. Default is FileManager.default.
    public init(
        iCloudFolder: ICloudFolder = .iCloudDocumentsFolder,
        groupName: String? = nil,
        fileManager: FileManager = .default
    ) {
        self.groupName = groupName
        self.iCloudFolder = iCloudFolder
        self.fileManager = fileManager
    }
    private let groupName: String?
    private let iCloudFolder: ICloudFolder
    private let fileManager: FileManager

    private var containerUrl: URL? {
        if let groupNameUnwrap = groupName {
            fileManager
                .containerURL(forSecurityApplicationGroupIdentifier: groupNameUnwrap)?
                .appendingPathComponent(iCloudFolder.rawValue)
        } else {
            fileManager
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
            if let containerFiles = try? fileManager.contentsOfDirectory(
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
                try fileManager.startDownloadingUbiquitousItem(at: container)
            } catch {
                completion(error)
            }
        }
    }
    
    /// Copying files from the iCloud container to a local folder on the device.
    ///
    /// In the **localFolder** parameter, pass the URL of the local folder to save files.
    public func downloadAllFilesFromIcloud(localFolder: URL, completion: @escaping (Error?) -> Void) {
        guard let container = containerUrl else {
            completion(ICloudError.iCloudAccessDenied)
            return
        }
        
        startDownloadFiles { [self] downloadError in
            guard downloadError == nil else {
                completion(downloadError)
                return
            }
            
            guard let containerFiles = try? fileManager.contentsOfDirectory(at: container, includingPropertiesForKeys: nil, options: .skipsHiddenFiles) else {
                completion(ICloudError.iCloudAccessDenied)
                return
            }
            
            if containerFiles.isEmpty {
                completion(ICloudError.noFilesInContainer)
                return
            }
            
            var errors: [Error] = []
            for containerFileUrl in containerFiles {
                guard let fileName = containerFileUrl.path.components(separatedBy: "/").last else { continue }
                
                if fileManager.fileExists(atPath: localFolder.appendingPathComponent(fileName).path) {
                    do {
                        try self.removeOldFile(path: localFolder.appendingPathComponent(fileName).path)
                    } catch let removeError {
                        print(removeError, #function, #line)
                        errors.append(removeError)
                        continue
                    }
                }
                do {
                    try fileManager.copyItem(
                        atPath: containerFileUrl.path,
                        toPath: localFolder.appendingPathComponent(fileName).path
                    )
                    print("copy file: \(fileName)")
                } catch {
                    print("Error copying file \(fileName): \(error)")
                    errors.append(error)
                }
            }
            
            if !errors.isEmpty {
                completion(errors.first)
            } else {
                completion(nil)
            }
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
                if fileManager.fileExists(atPath: fileUrl.path) {
                    try fileManager.removeItem(at: fileUrl)
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
            if !fileManager.fileExists(atPath: url.path, isDirectory: nil) {
                do {
                    try fileManager
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
        
        if fileManager.fileExists(atPath: localPath) {
            do {
                try removeOldFile(path: urlFileName.path)
            } catch let removeError {
                print(removeError, #function, #line)
                throw removeError
            }
        }
        do {
            try fileManager.copyItem(atPath: localPath, toPath: urlFileName.path)
            print("file \"\(fileName)\" copy to \(urlFileName.path) is ok")
        } catch {
            print("error copy file '\(fileName)' to iCloud - " + error.localizedDescription)
            throw error
        }
        
    }
    private func removeOldFile (path: String) throws {
        var isDir:ObjCBool = false
        if fileManager.fileExists(atPath: path, isDirectory: &isDir) {
            do {
                try fileManager.removeItem(atPath: path)
            } catch {
               throw error
            }
        }
    }

    // MARK: - Async Methods
    
    /// The function checks for the presence of files in the iCloud container. Returns a list of files or throws an error.
    public func checkFilesInIcloud() async throws -> [String] {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[String], Error>) in
            checkFilesInIcloud { result in
                switch result {
                case .success(let files):
                    continuation.resume(returning: files)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
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
