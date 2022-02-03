# ICloudDocuments

A framework for easier copying of files to iСloud documents

Requirements
=====================
iOS v13, macOS v10, tvOS v13 minimum

Installation
=====================
Use swift package manager
<https://github.com/VolkovsaVSA/ICloudDocuments>

Usage
=====================
1. Create a class instance
If you not use App groups when skip second parameter.
```swift
    let ICD = ICloudDocuments(iCloudFolder: .iCloudDocumentsFolder)
```
If you use App groups therefore passed App groups name in second parameter.
```swift
    let ICD = ICloudDocuments(iCloudFolder: .iCloudDocumentsFolder, groupName: "group.Name")
```
2. For upload files to iCloud Documents use "saveFilesToICloudDocuments" function.

```swift
    ICD.saveFilesToICloudDocuments(localFilePaths: [fileUrl1.path, fileUrl2.path]) { result in
        ... //result processing
    }
```

3. For download files from iCloud Documents use "downloadAllFilesFromIcloud" function.

```swift
    ICD.downloadAllFilesFromIcloud(localFolder: documentDirectory) { error in
        if let downloadError = error {
            print(downloadError.localizedDescription)
        } else {
            ... //result processing
        }
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
