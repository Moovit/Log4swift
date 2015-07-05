//
//  Logger.swift
//  log4swift
//
//  Created by Jérôme Duquennoy on 14/06/2015.
//  Copyright © 2015 Jérôme Duquennoy. All rights reserved.
//
// Log4swift is free software: you can redistribute it and/or modify
// it under the terms of the GNU Lesser General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Log4swift is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public License
// along with Foobar. If not, see <http://www.gnu.org/licenses/>.
//

/**
A logger is identified by a UTI identifier, it defines a threshold level and a destination appender
*/
public class Logger {
  public enum DictionaryKey: String {
    case Level = "Level"
    case AppenderIds = "AppenderIds"
  }
  
  
  /// The UTI string that identifies the logger.  
  /// Exemple : product.module.feature
  public let identifier: String;
  
  /// The threshold under which log messages will be ignored.  
  /// For exemple, if the threshold is Warning:
  /// * logs issued with a Debug or Info will be ignored
  /// * logs issued wiht a Warning, Error or Fatal level will be processed
  public var thresholdLevel: LogLevel;
  
  /// The list of destination appenders for the log messages.
  public var appenders: [Appender];
  
  convenience init() {
    self.init(identifier: "", appenders: Logger.createDefaultAppenders());
  }
  
  convenience init(loggerToCopy: Logger, newIdentifier: String) {
    self.init(identifier: newIdentifier, level: loggerToCopy.thresholdLevel, appenders: [Appender]() + loggerToCopy.appenders);
  }
  
  /// Creates a new logger with the given identifier, log level and appenders.
  /// The identifier will not be modifiable, and should not be an empty string.
  public init(identifier: String, level: LogLevel = LogLevel.Debug, appenders: [Appender] = []) {
    self.identifier = identifier;
    self.thresholdLevel = level;
    self.appenders = appenders;
  }
  
  /// Updates the logger with the content of the configuration dictionary.
  internal func updateWithDictionary(dictionary: Dictionary<String, AnyObject>, availableAppenders: Array<Appender>) throws {
    
    if let safeLevelString = dictionary[DictionaryKey.Level.rawValue] as? String {
      if let safeLevel = LogLevel(safeLevelString) {
        self.thresholdLevel = safeLevel;
      } else {
        throw Error.InvalidOrMissingParameterException(parameterName: DictionaryKey.Level.rawValue);
      }
    }
    
    self.appenders.removeAll();
    if let appenderIds = dictionary[DictionaryKey.AppenderIds.rawValue] as? Array<String> {
      appenders.removeAll();
      for currentAppenderId in appenderIds {
        if let foundAppender = availableAppenders.find({$0.identifier ==  currentAppenderId}) {
          appenders.append(foundAppender);
        } else {
          throw Error.InvalidOrMissingParameterException(parameterName: DictionaryKey.AppenderIds.rawValue);
        }
      }
    }
  }
  
  // MARK: Logging methods
  
  /// Logs the provided message with a debug level
  public func debug(message: String) {
    self.log(message, level: LogLevel.Debug);
  }
  /// Logs the provided message with an info level
  public func info(message: String) {
    self.log(message, level: LogLevel.Info);
  }
  /// Logs the provided message with a warning level
  public func warn(message: String) {
    self.log(message, level: LogLevel.Warning);
  }
  /// Logs the provided message with an error level
  public func error(message: String) {
    self.log(message, level: LogLevel.Error);
  }
  /// Logs the provided message with a fatal level
  public func fatal(message: String) {
    self.log(message, level: LogLevel.Fatal);
  }
  
  /// Logs a the message returned by the closer with a debug level
  /// If the logger's or appender's configuration prevents the message to be issued, the closure will not be called.
  public func debug(closure: () -> String) {
    self.log(closure, level: LogLevel.Debug);
  }
  /// Logs a the message returned by the closer with an info level
  /// If the logger's or appender's configuration prevents the message to be issued, the closure will not be called.
  public func info(closure: () -> String) {
    self.log(closure, level: LogLevel.Info);
  }
  /// Logs a the message returned by the closer with a warning level
  /// If the logger's or appender's configuration prevents the message to be issued, the closure will not be called.
  public func warn(closure: () -> String) {
    self.log(closure, level: LogLevel.Warning);
  }
  /// Logs a the message returned by the closer with an error level
  /// If the logger's or appender's configuration prevents the message to be issued, the closure will not be called.
  public func error(closure: () -> String) {
    self.log(closure, level: LogLevel.Error);
  }
  /// Logs a the message returned by the closer with a fatal level
  /// If the logger's or appender's configuration prevents the message to be issued, the closure will not be called.
  public func fatal(closure: () -> String) {
    self.log(closure, level: LogLevel.Fatal);
  }
  
  private func willIssueLogForLevel(level: LogLevel) -> Bool {
    return level.rawValue >= self.thresholdLevel.rawValue && self.appenders.reduce(false) { (shouldLog, currentAppender) in
      shouldLog || level.rawValue >= currentAppender.thresholdLevel.rawValue
    }
  }
  
  private func log(message: String, level: LogLevel) {
    if(self.willIssueLogForLevel(level)) {
      let info: FormatterInfoDictionary = [
        FormatterInfoKeys.LoggerName: self.identifier,
        FormatterInfoKeys.LogLevel: level,
      ];
      for currentAppender in self.appenders {
        currentAppender.log(message, level:level, info: info);
      }
    }
  }
  
  private func log(closure: () -> (String), level: LogLevel) {
    if(self.willIssueLogForLevel(level)) {
      let logMessage = closure();
      let info: FormatterInfoDictionary = [
        FormatterInfoKeys.LoggerName: self.identifier,
        FormatterInfoKeys.LogLevel: level,
      ];
      for currentAppender in self.appenders {
        currentAppender.log(logMessage, level:level, info: info);
      }
    }
  }
  
  private final class func createDefaultAppenders() -> [Appender] {
    return [ConsoleAppender("defaultAppender")];
  }
  
}