//
//  FileAppenderTests.swift
//  Log4swift
//
//  Created by Jérôme Duquennoy on 16/06/2015.
//  Copyright © 2015 Jérôme Duquennoy. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//


import XCTest
@testable import Log4swift

class FileAppenderTests: XCTestCase {
  
  override func setUp() {
    super.setUp()
  }
  
  override func tearDown() {
    super.tearDown()
  }
  
  func testFileAppenderExpandsTildeWhenInitializing() {
    let filePath = "~/log/logFile.log"
    
    // Execute
    let fileAppender = FileAppender(identifier: "test.appender", filePath: filePath)
    
    // Validate
    XCTAssertEqual(fileAppender.filePath, (filePath as NSString).expandingTildeInPath)
  }

  func testFileAppenderExpandsTildeWhenSettingFilePath() {
    let filePath = "~/log/logFile.log"
    let fileAppender = FileAppender(identifier: "test.appender", filePath: "/dummy/path")
    
    // Execute
    fileAppender.filePath = filePath
    
    // Validate
    XCTAssertEqual(fileAppender.filePath, (filePath as NSString).expandingTildeInPath)
  }
  
  func testFileAppenderCreatesFileIfItDoesNotExist()  {
    do {
      let tempFilePath = try self.createTemporaryFilePath(fileExtension: "log")
      let fileAppender = FileAppender(identifier: "test.appender", filePath: tempFilePath)
      let logContent = "ping"
      defer {
        unlink((tempFilePath as NSString).fileSystemRepresentation)
      }
      
      // Execute
      fileAppender.log(logContent, level: LogLevel.Debug, info: LogInfoDictionary())
      
      // Validate
      let fileContent = try NSString(contentsOfFile: tempFilePath, encoding: String.Encoding.utf8.rawValue)
      XCTAssert(fileContent.length > 0, "Content of log file should not be empty")
    } catch let error {
      XCTAssert(false, "Error in test : \(error)")
    }
    
  }
  
  func testFileAppenderReCreatesFileIfItDeletedAfterFirstLog()  {
    do {
      let tempFilePath = try self.createTemporaryFilePath(fileExtension: "log")
      let fileAppender = FileAppender(identifier: "test.appender", filePath: tempFilePath)
      let logContent = "ping"
      defer {
        unlink((tempFilePath as NSString).fileSystemRepresentation)
      }
      
      fileAppender.log(logContent, level: LogLevel.Debug, info: LogInfoDictionary())
      unlink((tempFilePath as NSString).fileSystemRepresentation)
      
      // Execute
      fileAppender.log(logContent, level: LogLevel.Debug, info: LogInfoDictionary())
      
      // Validate
      let fileContent = try NSString(contentsOfFile: tempFilePath, encoding: String.Encoding.utf8.rawValue)
      XCTAssert(fileContent.length > 0, "Content of log file should not be empty")
    } catch let error {
      XCTAssert(false, "Error in test : \(error)")
    }
  }
  
  func testFileAppenderDoesNotOverwriteTheFileIfAlreadyExisted() {
    do {
      let tempFilePath = try self.createTemporaryFilePath(fileExtension: "log")
      var fileAppender :FileAppender?
      fileAppender = FileAppender(identifier: "test.appender", filePath: tempFilePath)
      let logContent = "ping"
      defer {
        unlink((tempFilePath as NSString).fileSystemRepresentation)
      }
      
			fileAppender!.log(logContent, level: LogLevel.Debug, info: LogInfoDictionary())
      
      fileAppender = nil
      fileAppender = FileAppender(identifier: "test.appender", filePath: tempFilePath)
      
      // Execute
			fileAppender!.log(logContent, level: LogLevel.Debug, info: LogInfoDictionary())
      
      // Validate
      let fileContent = try NSString(contentsOfFile: tempFilePath, encoding: String.Encoding.utf8.rawValue)
      XCTAssert(fileContent.length >= logContent.count * 2, "Content of log file should not be just the first ping")
    } catch let error {
      XCTAssert(false, "Error in test : \(error)")
    }
  }
  
  func testFileAppenderAddsEndOfLineToLogsIfNotPresentAtEndOfMessage()  {
    do {
      let tempFilePath = try self.createTemporaryFilePath(fileExtension: "log")
      let fileAppender = FileAppender(identifier: "test.appender", filePath: tempFilePath)
      let logContent = "ping"
      defer {
        unlink((tempFilePath as NSString).fileSystemRepresentation)
      }
      
      fileAppender.log(logContent, level: LogLevel.Debug, info: LogInfoDictionary())
      unlink((tempFilePath as NSString).fileSystemRepresentation)
      
      // Execute
      fileAppender.log(logContent, level: LogLevel.Debug, info: LogInfoDictionary())
      
      // Validate
      let fileContent = try NSString(contentsOfFile: tempFilePath, encoding: String.Encoding.utf8.rawValue)
      XCTAssertEqual(fileContent as String, logContent + "\n", "Content of log file does not match expectation")
    } catch let error {
      XCTAssert(false, "Error in test : \(error)")
    }
  }
  
  func testFileAppenderDoesNotAddEndOfLineToLogsIfAlreadyPresent()  {
    do {
      let tempFilePath = try self.createTemporaryFilePath(fileExtension: "log")
      let fileAppender = FileAppender(identifier: "test.appender", filePath: tempFilePath)
      let logContent = "ping\n"
      defer {
        unlink((tempFilePath as NSString).fileSystemRepresentation)
      }
      
      fileAppender.log(logContent, level: LogLevel.Debug, info: LogInfoDictionary())
      unlink((tempFilePath as NSString).fileSystemRepresentation)
      
      // Execute
      fileAppender.log(logContent, level: LogLevel.Debug, info: LogInfoDictionary())
      
      // Validate
      let fileContent = try NSString(contentsOfFile: tempFilePath, encoding: String.Encoding.utf8.rawValue)
      XCTAssertEqual(fileContent as String, logContent, "Content of log file does not match expectation")
    } catch let error {
      XCTAssert(false, "Error in test : \(error)")
    }
  }
  
  func testLogsAreRedirectedToNewLogFileIfPathIsChanged()  {
    do {
      let tempFilePath = try self.createTemporaryFilePath(fileExtension: "log")
      let tempFilePath2 = try self.createTemporaryFilePath(fileExtension: "log")
      let fileAppender = FileAppender(identifier: "test.appender", filePath: tempFilePath)
      let logContent1 = "ping1"
      let logContent2 = "ping2"
      defer {
        unlink((tempFilePath as NSString).fileSystemRepresentation)
        unlink((tempFilePath2 as NSString).fileSystemRepresentation)
      }
      
			fileAppender.log(logContent1, level: LogLevel.Debug, info: LogInfoDictionary())
      
      // Execute
      fileAppender.filePath = tempFilePath2
      fileAppender.log(logContent2, level: LogLevel.Debug, info: LogInfoDictionary())
      
      
      // Validate
      let fileContent2 = try NSString(contentsOfFile: tempFilePath2, encoding: String.Encoding.utf8.rawValue)
      XCTAssertEqual(fileContent2 as String, logContent2 + "\n", "Content of second log file does not match expectation")
    } catch let error {
      XCTAssert(false, "Error in test : \(error)")
    }
  }
  
  func testUpdatingAppenderFromDictionaryWithNoIdentifierThrowsError() {
    let dictionary = Dictionary<String, Any>()
    let appender = FileAppender("testAppender")
    
		XCTAssertThrows { try appender.update(withDictionary: dictionary, availableFormatters:[]) }
  }
  
  func testUpdatingAppenderFromDictionaryWithNoFilePathThrowsError() {
    let dictionary = Dictionary<String, Any>()
    let appender = FileAppender("testAppender")
    
    // Execute & Analyze
    XCTAssertThrows { try appender.update(withDictionary: dictionary, availableFormatters:[]) }
  }
  
	func testUpdatingAppenderFromDictionaryWithFilePathUsesProvidedValue() {
		let dictionary = [FileAppender.DictionaryKey.FilePath.rawValue: "/log/file/path.log"]
		let appender = FileAppender("testAppender")
		
		// Execute
		try! appender.update(withDictionary: dictionary, availableFormatters:[])
		
		// Analyze
		XCTAssertEqual(appender.filePath,  "/log/file/path.log")
	}
	
  func testUpdatingAppenderFomDictionaryWithNonExistingFormatterIdThrowsError() {
    let dictionary = [FileAppender.DictionaryKey.FilePath.rawValue: "/log/file/path.log",
      Appender.DictionaryKey.FormatterId.rawValue: "not existing id"]
    let appender = FileAppender("testAppender")
    
    XCTAssertThrows { try appender.update(withDictionary: dictionary, availableFormatters: []) }
  }
  
  func testUpdatingAppenderFomDictionaryWithExistingFormatterIdUsesIt() {
    let formatter = try! PatternFormatter(identifier: "formatterId", pattern: "test pattern")
    let dictionary = [FileAppender.DictionaryKey.FilePath.rawValue: "/log/file/path.log",
      Appender.DictionaryKey.FormatterId.rawValue: "formatterId"]
    let appender = FileAppender("testAppender")
    
    // Execute
    try! appender.update(withDictionary: dictionary, availableFormatters: [formatter])
    
    // Validate
    XCTAssertEqual((appender.formatter?.identifier)!, formatter.identifier)
  }
  
  func testFileAppenderPerformanceWhenFileIsNotDeleted() {
    do {
      let tempFilePath = try self.createTemporaryFilePath(fileExtension: "log")
      let fileAppender = FileAppender(identifier: "test.appender", filePath: tempFilePath)
      defer {
        unlink((tempFilePath as NSString).fileSystemRepresentation)
      }
      
      measure { () -> Void in
        for _ in 1...1000 {
					fileAppender.log("This is a test log", level: LogLevel.Debug, info: LogInfoDictionary())
        }
      }
    } catch let error {
      XCTAssert(false, "Error in test : \(error)")
    }
  }

	func testLoggingToImpossiblePathDoesNotCreateTheFileAndDoesNotRaiseError() {
		let filePath = "/proc/impossibleLogFile.log"
		let fileAppender = FileAppender(identifier: "test.appender", filePath: filePath)
		
		// Execute
		fileAppender.performLog("log", level: .Error, info: [:])
		
		// Analyze
		XCTAssertFalse(FileManager.default.fileExists(atPath: filePath))
	}
	
}
