//
//  JSON.swift
//
//

import Foundation

public typealias JSONDictionary = [String:JSON]
public typealias JSONArray = [JSON]

private let numberFormatter:NSNumberFormatter = {
    let formatter = NSNumberFormatter()
    formatter.locale = NSLocale.systemLocale()
    return formatter
    }()

public enum JSON {
    case JSONDictionary([String:JSON])
    case JSONArray([JSON])
    case JSONString(String)
    case JSONNumber(NSNumber)
    case JSONNull
    
    public init(jsonData: NSData) {
        var error:NSErrorPointer = nil
        if let jsonObject: AnyObject = NSJSONSerialization.JSONObjectWithData(jsonData, options: .AllowFragments, error: error) as AnyObject?  {
            self = JSON(jsonObject:jsonObject)
        }
        else {
            self = .JSONNull
        }
    }
    
    public init(jsonString: String) {
        if let data = jsonString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true) {
            self = JSON(jsonData:data)
        }
        else {
            self = .JSONNull
        }
    }
    
    public init(jsonObject: AnyObject) {
        
        switch jsonObject {
        case let v as [AnyObject]:
            self = .JSONArray(v.map{JSON(jsonObject:$0)})
        case let v as [String:AnyObject]:
            var object: [String:JSON] = [:]
            for key in v.keys {
                if let value: AnyObject = v[key] {
                    object[key] = JSON(jsonObject:value)
                } else {
                    object[key] = .JSONNull
                }
            }
            self = .JSONDictionary(object)
            
        case let v as String:
            self = .JSONString(v)
        case let v as NSNumber:
            self = .JSONNumber(v)
        default:
            self = .JSONNull
        }
    }
    
    public func serializedData(options:NSJSONWritingOptions = NSJSONWritingOptions(0)) -> NSData {
        return NSJSONSerialization.dataWithJSONObject(self.asNSObject(), options: options, error: nil)!
    }
    
    public func serializedString(options:NSJSONWritingOptions = NSJSONWritingOptions(0)) -> String {
        return NSString(data: serializedData(options: options), encoding: NSUTF8StringEncoding)!
    }
    
    public func jsonValue() -> JSON? {
        switch self {
        case let .JSONNull:
            return .None
        default:
            return self
        }
    }
    
    public func value<T>() -> T? {
        switch self {
        case let .JSONString(v):
            return v as? T
        case let .JSONNumber(v):
            return v as? T
        case let .JSONNull:
            return .None
        case let .JSONArray(a):
            return a as? T
        case let .JSONDictionary(o):
            return o as? T
        }
    }
    
    public func asArray() -> [JSON]? {
        return self.value() as [JSON]?
    }
    
    public func asDictionary() -> [String:JSON]? {
        return self.value() as [String:JSON]?
    }
    
    public func asString() -> String? {
        return self.value() as String?
    }
    
    public func asNumber() -> NSNumber? {
        switch self {
        case let .JSONString(v):
            return numberFormatter.numberFromString(v)
        case let .JSONNumber(v):
            return v
        default:
            return nil
        }
    }
    
    public func asDouble() -> Double? {
        return asNumber()?.doubleValue
    }
    
    public func asFloat() -> Float? {
        return asNumber()?.floatValue
}
    
    public func asBool() -> Bool? {
        switch self {
        case let .JSONString(v):
            if let int =  v.toInt() {
                return int != 0
            }
            else {
                return nil
            }
        case let .JSONNumber(v):
            return v.boolValue
        default:
            return nil
        }
    }
    
    
    public func asInt() -> Int? {
        return asNumber()?.integerValue
    }
    
    public func asUInt() -> UInt? {
        if let int = asNumber()?.unsignedIntegerValue {
            return UInt(int)
        }
        return nil
    }
    
    public subscript(key: String) -> JSON {
        switch self {
        case let .JSONDictionary(o):
            return o[key] ?? .JSONNull
        default:
            return .JSONNull
        }
    }
    
    public var count:Int {
        switch self {
        case let .JSONDictionary(o):
            return o.count
        case let .JSONArray(a):
            return a.count
        case let .JSONNull:
            return 0
        default:
            return 1
        }
    }
    
    public subscript(index: Int) -> JSON {
        switch self {
        case let .JSONArray(a):
            return a[index]
        default:
            return .JSONNull
        }
    }
    
    public func asNSObject()->AnyObject {
        switch self {
        case let .JSONString(v):
            return v
        case let .JSONNumber(v):
            return v
        case let .JSONNull:
            return NSNull()
        case let .JSONArray(a):
            return a.map{ $0.asNSObject() }
        case let .JSONDictionary(o):
            return reduce(o, [String:AnyObject]()) { dict, pair in
                var d = dict
                d[pair.0] = pair.1.asNSObject()
                return d
            }
        }
    }
}