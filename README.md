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
    icd.saveFilesToICloudDocuments(localFilePaths: [fileUrl1.path, fileUrl2.path]) { result in
        ... //result processing
    }
    
    // Using async/await
    do {
        let savedFiles = try await icd.saveFilesToICloudDocuments(localFilePaths: [fileUrl1.path, fileUrl2.path])
        // Process saved files
    } catch {
        // Handle error
    }
```

3. For download files from iCloud Documents use "downloadAllFilesFromIcloud" function.

```swift
    // Using completion handler
    icd.downloadAllFilesFromIcloud(localFolder: documentDirectory) { error in
        if let error {
            print(error.localizedDescription)
        } else {
            ... //result processing
        }
    }
    
    // Using async/await
    do {
        try await icd.downloadAllFilesFromIcloud(localFolder: documentDirectory)
        // Files downloaded successfully
    } catch {
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
    
    // Using async/await
    do {
        let files = try await icd.checkFilesInIcloud()
        // Process files
    } catch {
        print(error.localizedDescription)
    }
```

Enjoy
=====================


License
=====================
MIT License
Copyright [2022] [Sergei Volkov]

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
