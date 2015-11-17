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

public enum JSON : CustomStringConvertible {
    case JSONDictionary([String:JSON])
    case JSONArray([JSON])
    case JSONString(String)
    case JSONNumber(NSNumber)
    case JSONNull
    
    public var description:String {
        switch self {
        case let .JSONString(v):
            return "JSONString(\(v))"
        case let .JSONNumber(v):
            return "JSONNumber(\(v))"
        case .JSONNull:
            return "JSONNull"
        case let .JSONArray(a):
            return "JSONArray(\(a))"
        case let .JSONDictionary(o):
            return "JSONDictionary(\(o))"
        }
    }
    
    public init(jsonData: NSData) {
            if let jsonObject: AnyObject = (try? NSJSONSerialization.JSONObjectWithData(jsonData, options: .AllowFragments)) as AnyObject?  {
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
    
    public func serializedData(options:NSJSONWritingOptions = NSJSONWritingOptions(rawValue: 0)) -> NSData {
        return try! NSJSONSerialization.dataWithJSONObject(self.asNSObject(), options: options)
    }
    
    public func serializedString(options:NSJSONWritingOptions = NSJSONWritingOptions(rawValue: 0)) -> String {
        return NSString(data: serializedData(options), encoding: NSUTF8StringEncoding)! as String
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
        return self.value()
    }
    
    public func asDictionary() -> [String:JSON]? {
        return self.value()
    }
    
    public func asString() -> String? {
        switch self {
        case let .JSONString(v):
            return v
        case let .JSONNumber(v):
            return numberFormatter.stringFromNumber(v)
        case let .JSONNull:
            return nil
        case let .JSONArray(a):
            return nil
        case let .JSONDictionary(o):
            return nil
        }
    }
    
    public func asNSString() -> NSString? {
        return self.value()
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
            if let int =  Int(v) {
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
            return o.reduce([String:AnyObject]()) { dict, pair in
                var d = dict
                d[pair.0] = pair.1.asNSObject()
                return d
            }
        }
    }
}