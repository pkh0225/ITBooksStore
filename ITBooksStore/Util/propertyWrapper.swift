//
//  propertyWrapper.swift
//  ITBooksStore
//
//  Created by pkh on 2021/08/03.
//

import Foundation

import Foundation

@propertyWrapper
public struct Atomic<Value> {
    private var value: Value
    private let lock = NSLock()

    public init(wrappedValue value: Value) {
        self.value = value
    }

    public var wrappedValue: Value {
      get { return load() }
      set { store(newValue: newValue) }
    }

    public func load() -> Value {
        lock.lock()
        defer { lock.unlock() }
        return value
    }

    public mutating func store(newValue: Value) {
        lock.lock()
        defer { lock.unlock() }
        value = newValue
    }
}

@propertyWrapper
struct UserDefaultWrapper<Value> {
    let key: String
    let defaultValue: Value
    let groupID: String?

    var wrappedValue: Value {
        get {
            var userDefault: UserDefaults
            if let groupId = self.groupID {
                userDefault = UserDefaults(suiteName: groupId)!
            }
            else {
                userDefault = UserDefaults.standard
            }
            return userDefault.object(forKey: key) as? Value ?? defaultValue
        }
        set {
            var userDefault: UserDefaults
            if let groupId = self.groupID {
                userDefault = UserDefaults(suiteName: groupId)!
            }
            else {
                userDefault = UserDefaults.standard
            }
            userDefault.set(newValue, forKey: key)

        }
    }

    init(wrappedValue: Value, key: String, groupID: String? = nil) {
        self.key = key
        self.defaultValue = wrappedValue
        self.groupID = groupID
    }
}


struct UserDefault {
    @UserDefaultWrapper(key: "showUnitViewData_FontSize") static var showUnitViewData_FontSize: Int = 20
    @UserDefaultWrapper(key: "memo") static var memo: [String: String] = [:]
}
