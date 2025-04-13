import XCTest
@testable import ICloudDocuments

final class ICloudDocumentsTests: XCTestCase {
    var icd: ICloudDocuments!
    var mockFileManager: MockFileManager!
    
    // MARK: - Test Constants
    private let testContainerUrl = URL(string: "test://container")!
    private let testLocalFolderUrl = URL(string: "test://local")!
    private let testFile1Name = "file1.txt"
    private let testFile2Name = "file2.txt"
    private var testFile1Url: URL { testContainerUrl.appendingPathComponent(testFile1Name) }
    private var testFile2Url: URL { testContainerUrl.appendingPathComponent(testFile2Name) }
    private var testFile1Path: String { "test/path/\(testFile1Name)" }
    private var testFile2Path: String { "test/path/\(testFile2Name)" }
    
    override func setUp() {
        super.setUp()
        mockFileManager = MockFileManager()
        icd = ICloudDocuments(
            iCloudFolder: .iCloudDocumentsFolder,
            groupName: nil,
            fileManager: mockFileManager
        )
    }
    
    override func tearDown() {
        icd = nil
        mockFileManager = nil
        super.tearDown()
    }
    
    // MARK: - checkFilesInIcloud Tests
    
    func testCheckFilesInIcloud_WhenNoAccess_ShouldReturnICloudAccessDenied() {
        // Given
        mockFileManager.containerUrl = nil
        
        // When
        let expectation = XCTestExpectation(description: "Check files completion")
        icd.checkFilesInIcloud { result in
            // Then
            switch result {
            case .failure(let error as ICloudDocuments.ICloudError):
                XCTAssertEqual(error, .iCloudAccessDenied)
            default:
                XCTFail("Expected ICloudAccessDenied error")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testCheckFilesInIcloud_WhenNoFiles_ShouldReturnNoFilesInContainer() {
        // Given
        mockFileManager.containerUrl = testContainerUrl
        mockFileManager.contentsOfDirectoryResult = []
        
        // When
        let expectation = XCTestExpectation(description: "Check files completion")
        icd.checkFilesInIcloud { result in
            // Then
            switch result {
            case .failure(let error as ICloudDocuments.ICloudError):
                XCTAssertEqual(error, .noFilesInContainer)
            default:
                XCTFail("Expected NoFilesInContainer error")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testCheckFilesInIcloud_WhenFilesExist_ShouldReturnFileList() {
        // Given
        mockFileManager.containerUrl = testContainerUrl
        let testFiles = [testFile1Url, testFile2Url]
        mockFileManager.contentsOfDirectoryResult = testFiles
        
        // When
        let expectation = XCTestExpectation(description: "Check files completion")
        icd.checkFilesInIcloud { result in
            // Then
            switch result {
            case .success(let files):
                XCTAssertEqual(files, [self.testFile1Name, self.testFile2Name])
            case .failure:
                XCTFail("Expected success with file list")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - saveFilesToICloudDocuments Tests
    
    func testSaveFilesToICloudDocuments_WhenNoAccess_ShouldReturnICloudAccessDenied() {
        // Given
        mockFileManager.containerUrl = nil
        
        // When
        let expectation = XCTestExpectation(description: "Save files completion")
        icd.saveFilesToICloudDocuments(localFilePaths: ["test/path/file.txt"]) { result in
            // Then
            switch result {
            case .failure(let error as ICloudDocuments.ICloudError):
                XCTAssertEqual(error, .iCloudAccessDenied)
            default:
                XCTFail("Expected ICloudAccessDenied error")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testSaveFilesToICloudDocuments_WhenCopyFails_ShouldReturnError() {
        // Given
        mockFileManager.containerUrl = testContainerUrl
        mockFileManager.copyItemShouldThrow = true
        
        // When
        let expectation = XCTestExpectation(description: "Save files completion")
        icd.saveFilesToICloudDocuments(localFilePaths: ["test/path/file.txt"]) { result in
            // Then
            switch result {
            case .failure(let error as ICloudDocuments.ICloudError):
                XCTAssertEqual(error, .fileCopyFailed)
            default:
                XCTFail("Expected fileCopyFailed error")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testSaveFilesToICloudDocuments_WhenSuccess_ShouldReturnSavedFiles() {
        // Given
        mockFileManager.containerUrl = testContainerUrl
        let testFiles = [testFile1Path, testFile2Path]
        
        // When
        let expectation = XCTestExpectation(description: "Save files completion")
        icd.saveFilesToICloudDocuments(localFilePaths: testFiles) { result in
            // Then
            switch result {
            case .success(let files):
                XCTAssertEqual(files, [self.testFile1Name, self.testFile2Name])
            case .failure:
                XCTFail("Expected success with saved files")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testSaveFilesToICloudDocuments_WhenCreateDirectoryFails_ShouldReturnError() {
        // Given
        mockFileManager.containerUrl = testContainerUrl
        mockFileManager.createDirectoryShouldThrow = true
        
        // When
        let expectation = XCTestExpectation(description: "Save files completion")
        icd.saveFilesToICloudDocuments(localFilePaths: ["test/path/file.txt"]) { result in
            // Then
            switch result {
            case .failure(let error as ICloudDocuments.ICloudError):
                XCTAssertEqual(error, .directoryCreationFailed)
            default:
                XCTFail("Expected directoryCreationFailed error")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - downloadAllFilesFromIcloud Tests
    
    func testDownloadAllFilesFromIcloud_WhenNoAccess_ShouldReturnICloudAccessDenied() {
        // Given
        mockFileManager.containerUrl = nil
        let localFolder = testLocalFolderUrl
        
        // When
        let expectation = XCTestExpectation(description: "Download files completion")
        icd.downloadAllFilesFromIcloud(localFolder: localFolder) { error in
            // Then
            XCTAssertEqual(error as? ICloudDocuments.ICloudError, .iCloudAccessDenied)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testDownloadAllFilesFromIcloud_WhenNoFiles_ShouldReturnNoFilesInContainer() {
        // Given
        mockFileManager.containerUrl = testContainerUrl
        mockFileManager.contentsOfDirectoryResult = []
        let localFolder = testLocalFolderUrl
        
        // When
        let expectation = XCTestExpectation(description: "Download files completion")
        icd.downloadAllFilesFromIcloud(localFolder: localFolder) { error in
            // Then
            XCTAssertEqual(error as? ICloudDocuments.ICloudError, .noFilesInContainer)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testDownloadAllFilesFromIcloud_WhenSuccess_ShouldCompleteWithoutError() {
        // Given
        mockFileManager.containerUrl = testContainerUrl
        let testFiles = [testFile1Url, testFile2Url]
        mockFileManager.contentsOfDirectoryResult = testFiles
        let localFolder = testLocalFolderUrl
        
        // When
        let expectation = XCTestExpectation(description: "Download files completion")
        icd.downloadAllFilesFromIcloud(localFolder: localFolder) { error in
            // Then
            XCTAssertNil(error)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - deleteFilesFromICloud Tests
    
    func testDeleteFilesFromICloud_WhenNoAccess_ShouldReturnICloudAccessDenied() {
        // Given
        mockFileManager.containerUrl = nil
        
        // When
        let expectation = XCTestExpectation(description: "Delete files completion")
        icd.deleteFilesFromICloud(fileNames: ["file.txt"]) { result in
            // Then
            switch result {
            case .failure(let error as ICloudDocuments.ICloudError):
                XCTAssertEqual(error, .iCloudAccessDenied)
            default:
                XCTFail("Expected ICloudAccessDenied error")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testDeleteFilesFromICloud_WhenFileNotFound_ShouldReturnFileNotFound() {
        // Given
        mockFileManager.containerUrl = testContainerUrl
        mockFileManager.fileExistsResult = false
        
        // When
        let expectation = XCTestExpectation(description: "Delete files completion")
        icd.deleteFilesFromICloud(fileNames: ["file.txt"]) { result in
            // Then
            switch result {
            case .failure(let error as ICloudDocuments.ICloudError):
                XCTAssertEqual(error, .fileNotFound)
            default:
                XCTFail("Expected FileNotFound error")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testDeleteFilesFromICloud_WhenSuccess_ShouldReturnDeletedFiles() {
        // Given
        mockFileManager.containerUrl = testContainerUrl
        let testFiles = [testFile1Name, testFile2Name]
        
        // When
        let expectation = XCTestExpectation(description: "Delete files completion")
        icd.deleteFilesFromICloud(fileNames: testFiles) { result in
            // Then
            switch result {
            case .success(let deletedFiles):
                XCTAssertEqual(deletedFiles, testFiles)
            case .failure:
                XCTFail("Expected success with deleted files")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testDeleteFilesFromICloud_WhenRemoveFails_ShouldReturnError() {
        // Given
        mockFileManager.containerUrl = testContainerUrl
        mockFileManager.fileExistsResult = true
        mockFileManager.removeItemShouldThrow = true
        
        // When
        let expectation = XCTestExpectation(description: "Delete files completion")
        icd.deleteFilesFromICloud(fileNames: ["file.txt"]) { result in
            // Then
            switch result {
            case .failure(let error as ICloudDocuments.ICloudError):
                XCTAssertEqual(error, .fileDeletionFailed)
            default:
                XCTFail("Expected fileDeletionFailed error")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Async Methods Tests
    
    func testCheckFilesInIcloudAsync_WhenNoAccess_ShouldThrowICloudAccessDenied() async {
        // Given
        mockFileManager.containerUrl = nil
        
        // When/Then
        do {
            _ = try await icd.checkFilesInIcloud()
            XCTFail("Expected to throw ICloudAccessDenied")
        } catch let error as ICloudDocuments.ICloudError {
            XCTAssertEqual(error, .iCloudAccessDenied)
        } catch {
            XCTFail("Expected ICloudAccessDenied error")
        }
    }
    
    func testSaveFilesToICloudDocumentsAsync_WhenSuccess_ShouldReturnSavedFiles() async throws {
        // Given
        mockFileManager.containerUrl = testContainerUrl
        let testFiles = [testFile1Path, testFile2Path]
        
        // When
        let savedFiles = try await icd.saveFilesToICloudDocuments(localFilePaths: testFiles)
        
        // Then
        XCTAssertEqual(savedFiles, [testFile1Name, testFile2Name])
    }
    
    func testSaveFilesToICloudDocumentsAsync_WhenCopyFails_ShouldThrowError() async {
        // Given
        mockFileManager.containerUrl = testContainerUrl
        mockFileManager.copyItemShouldThrow = true
        
        // When/Then
        do {
            _ = try await icd.saveFilesToICloudDocuments(localFilePaths: ["test/path/file.txt"])
            XCTFail("Expected to throw fileCopyFailed error")
        } catch let error as ICloudDocuments.ICloudError {
            XCTAssertEqual(error, .fileCopyFailed)
        } catch {
            XCTFail("Expected fileCopyFailed error")
        }
    }
    
    func testDownloadAllFilesFromIcloudAsync_WhenSuccess_ShouldCompleteWithoutError() async throws {
        // Given
        mockFileManager.containerUrl = testContainerUrl
        let testFiles = [testFile1Url, testFile2Url]
        mockFileManager.contentsOfDirectoryResult = testFiles
        let localFolder = testLocalFolderUrl
        
        // When/Then
        try await icd.downloadAllFilesFromIcloud(localFolder: localFolder)
    }
    
    func testDownloadAllFilesFromIcloudAsync_WhenNoFiles_ShouldThrowError() async {
        // Given
        mockFileManager.containerUrl = testContainerUrl
        mockFileManager.contentsOfDirectoryResult = []
        let localFolder = testLocalFolderUrl
        
        // When/Then
        do {
            try await icd.downloadAllFilesFromIcloud(localFolder: localFolder)
            XCTFail("Expected to throw noFilesInContainer error")
        } catch let error as ICloudDocuments.ICloudError {
            XCTAssertEqual(error, .noFilesInContainer)
        } catch {
            XCTFail("Expected noFilesInContainer error")
        }
    }
    
    func testDeleteFilesFromICloudAsync_WhenSuccess_ShouldReturnDeletedFiles() async throws {
        // Given
        mockFileManager.containerUrl = testContainerUrl
        let testFiles = [testFile1Name, testFile2Name]
        
        // When
        let deletedFiles = try await icd.deleteFilesFromICloud(fileNames: testFiles)
        
        // Then
        XCTAssertEqual(deletedFiles, testFiles)
    }
    
    func testDeleteFilesFromICloudAsync_WhenFileNotFound_ShouldThrowError() async {
        // Given
        mockFileManager.containerUrl = testContainerUrl
        mockFileManager.fileExistsResult = false
        
        // When/Then
        do {
            _ = try await icd.deleteFilesFromICloud(fileNames: ["file.txt"])
            XCTFail("Expected to throw fileNotFound error")
        } catch let error as ICloudDocuments.ICloudError {
            XCTAssertEqual(error, .fileNotFound)
        } catch {
            XCTFail("Expected fileNotFound error")
        }
    }
}

// MARK: - MockFileManager

class MockFileManager: FileManager {
    var containerUrl: URL?
    var contentsOfDirectoryResult: [URL] = []
    var fileExistsResult: Bool = true
    var copyItemShouldThrow: Bool = false
    var createDirectoryShouldThrow: Bool = false
    var removeItemShouldThrow: Bool = false
    var startDownloadingShouldThrow: Bool = false
    
    override func containerURL(forSecurityApplicationGroupIdentifier groupIdentifier: String) -> URL? {
        return containerUrl
    }
    
    override func url(forUbiquityContainerIdentifier containerIdentifier: String?) -> URL? {
        return containerUrl
    }
    
    override func contentsOfDirectory(at url: URL, includingPropertiesForKeys keys: [URLResourceKey]?, options mask: FileManager.DirectoryEnumerationOptions) throws -> [URL] {
        return contentsOfDirectoryResult
    }
    
    override func fileExists(atPath path: String) -> Bool {
        return fileExistsResult
    }
    
    override func copyItem(atPath srcPath: String, toPath dstPath: String) throws {
        if copyItemShouldThrow {
            throw NSError(domain: "Test", code: 0, userInfo: nil)
        }
    }
    
    override func removeItem(at URL: URL) throws {
        if removeItemShouldThrow {
            throw NSError(domain: "Test", code: 0, userInfo: nil)
        }
    }
    
    override func createDirectory(at url: URL, withIntermediateDirectories createIntermediates: Bool, attributes: [FileAttributeKey : Any]? = nil) throws {
        if createDirectoryShouldThrow {
            throw NSError(domain: "Test", code: 0, userInfo: nil)
        }
    }
    
    override func startDownloadingUbiquitousItem(at url: URL) throws {
        if startDownloadingShouldThrow {
            throw NSError(domain: "Test", code: 0, userInfo: nil)
        }
    }
}

