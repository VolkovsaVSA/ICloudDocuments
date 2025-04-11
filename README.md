# ICloudDocuments

A framework for easier copying of files to iСloud documents

Requirements
=====================
iOS v15, macOS v12, tvOS v15 minimum

Installation
=====================
Use swift package manager
<https://github.com/VolkovsaVSA/ICloudDocuments>

Usage
=====================
0. **For using this framework you must processing all necessary step to switch on iCloud Documents in your app.**
---------------------------------

    * add iCloud Documents in "Signing & Capabilities"
    * add follow code in info.plist
    
    YOUR_CONTAINER_IDENTIFIER it's your container identifier when you checkmark in iCloud Documents in Signing & Capabilities.
    
```xml
    <key>NSUbiquitousContainers</key>
    <dict>
        <key>YOUR_CONTAINER_IDENTIFIER</key>
        <dict>
            <key>NSUbiquitousContainerIsDocumentScopePublic</key>
            <true/>
            <key>NSUbiquitousContainerSupportedFolderLevels</key>
            <string>Any</string>
            <key>NSUbiquitousContainerName</key>
            <string>YOU_APP_NAME</string>
        </dict>
    </dict>
```

1. Create a class instance

If you not use App groups when skip second parameter.
```swift
    let icd = ICloudDocuments(iCloudFolder: .iCloudDocumentsFolder)
```
If you use App groups therefore passed App groups name in second parameter.
```swift
    let icd = ICloudDocuments(iCloudFolder: .iCloudDocumentsFolder, groupName: "group.Name")
```
2. For upload files to iCloud Documents use "saveFilesToICloudDocuments" function.

```swift
    // Using completion handler
    icd.saveFilesToICloudDocuments(localFilePaths: [fileUrl1.path]) { result in
        switch result {
        case .success(let files):
            // Process saved files
        case .failure(let error):
            print(error.localizedDescription)
        }
    }
    
    // Using async/await with throws
    do {
        let savedFiles = try await icd.saveFilesToICloudDocuments(localFilePaths: [fileUrl1.path])
        // Process saved files
    } catch {
        print(error.localizedDescription)
    }
    
    // Using async/await with Result
    let savedFilesResult = await icd.saveFilesToICloudDocuments(localFilePaths: [fileUrl1.path])
    switch savedFilesResult {
    case .success(let files):
        // Process saved files
    case .failure(let error):
        print(error.localizedDescription)
    }
```

3. For download files from iCloud Documents use "downloadAllFilesFromIcloud" function.

```swift
    // Using completion handler
    icd.downloadAllFilesFromIcloud(localFolder: documentDirectory) { error in
        if let error {
            print(error.localizedDescription)
        } else {
            // Files downloaded successfully
        }
    }
    
    // Using async/await with throws
    do {
        try await icd.downloadAllFilesFromIcloud(localFolder: documentDirectory)
        // Files downloaded successfully
    } catch {
        print(error.localizedDescription)
    }
    
    // Using async/await with Result
    let downloadResult = await icd.downloadAllFilesFromIcloud(localFolder: documentDirectory)
    switch downloadResult {
    case .success:
        // Files downloaded successfully
    case .failure(let error):
        print(error.localizedDescription)
    }
```

4. For checking files in iCloud use "checkFilesInIcloud" function.

```swift
    // Using completion handler
    icd.checkFilesInIcloud { result in
        switch result {
        case .success(let files):
            // Process files
        case .failure(let error):
            print(error.localizedDescription)
        }
    }
    
    // Using async/await with throws
    do {
        let files = try await icd.checkFilesInIcloud()
        // Process files
    } catch {
        print(error.localizedDescription)
    }
    
    // Using async/await with Result
    let filesResult = await icd.checkFilesInIcloud()
    switch filesResult {
    case .success(let files):
        // Process files
    case .failure(let error):
        print(error.localizedDescription)
    }
```

5. For deleting files from iCloud use "deleteFilesFromICloud" function.

```swift
    // Using completion handler
    icd.deleteFilesFromICloud(fileNames: ["file1.txt", "file2.txt"]) { result in
        switch result {
        case .success(let deletedFiles):
            // Process deleted files
        case .failure(let error):
            print(error.localizedDescription)
        }
    }
    
    // Using async/await with throws
    do {
        let deletedFiles = try await icd.deleteFilesFromICloud(fileNames: ["file1.txt", "file2.txt"])
        // Process deleted files
    } catch {
        print(error.localizedDescription)
    }
    
    // Using async/await with Result
    let deleteResult = await icd.deleteFilesFromICloud(fileNames: ["file1.txt", "file2.txt"])
    switch deleteResult {
    case .success(let deletedFiles):
        // Process deleted files
    case .failure(let error):
        print(error.localizedDescription)
    }
```

Note: Each method is available in three versions:
1. With completion handler (traditional asynchronous approach)
2. With async/await and throws (modern Swift approach)
3. With async/await and Result (alternative approach for more explicit error handling)

Enjoy
=====================


License
=====================
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
