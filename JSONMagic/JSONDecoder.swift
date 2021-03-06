//
//  JSON.swift
//
//

import Foundation


public protocol JSONDecodable
{
    class func decodeJSON(json:JSON) -> Result<Self>
}

public protocol JSONMutable
{
    mutating func mutateByJSON(json:JSON) -> Result<Self>
}

public protocol JSONMutableDecodable : JSONMutable
{
    init()
}

public let kJSONDecoderErrorDomain = "JSONDecoder"
public let kJSONDecoderErrorPath = "JSONDecoderErrorPath"

public enum JSONDecoderError: Int {
    case UnknownError
    case KeyAbsent
    case InvalidObjectType
}


public struct JSONDecoder
{
    let json: JSONDictionary
    let error: NSError?
    
    public init(_ json:JSON) {
        
        if let jsonDictionary = json.asDictionary() {
            self.json = jsonDictionary
        }
        else {
            self.json = [:]
            self.error = JSONDecoder.castError()
        }
    }
    
    private init(_ json:JSONDictionary, error:NSError) {
        self.json = json
        self.error = error
    }
    
    // result value
    
    public func result<T>(result: @autoclosure() -> T) -> Result<T> {
        return error != nil ? failure(error!) : success(result())
    }
    
    public func result<T>(validate:()->Result<T>) -> Result<T> {
        return error != nil ? failure(error!) : validate()
    }
    
    // Binding with transform processors
    
    public func bind<T>(inout value:T,_ key:String, transform:(JSON)->Result<T>) -> JSONDecoder {
        if self.error != nil {
            return self
        }
        if let jsonValue:JSON = json[key] {
            return bindResult(&value,key, transform(jsonValue))
        }
        else  {
            return JSONDecoder(json,error:JSONDecoder.keyAbsentError(key))
        }
    }
    
    public func bind<T>(inout value:T!,_ key:String, transform:(JSON)->Result<T>) -> JSONDecoder {
        if self.error != nil {
            return self
        }
        if let jsonValue:JSON = json[key] {
            return bindResult(&value,key, transform(jsonValue))
        }
        else  {
            return JSONDecoder(json,error:JSONDecoder.keyAbsentError(key))
        }
    }
    
    public func bind<T>(inout value:T?,_ key:String, transform:(JSON)->Result<T>) -> JSONDecoder {
        if self.error != nil {
            return self
        }
        if let jsonValue:JSON = json[key] {
            return bindResult(&value,key, transform(jsonValue))
        }
        else  {
            return JSONDecoder(json,error:JSONDecoder.keyAbsentError(key))
        }
    }
    
    public func optionalBind<T>(inout value:T,_ key:String, fallback:T, transform:(JSON)->Result<T>) -> JSONDecoder {
        if self.error != nil {
            return self
        }
        if let jsonValue:JSON = json[key] {
            return bindResult(&value,key, transform(jsonValue))
        }
        else  {
            value = fallback
            return self
        }
    }
    
    public func optionalBind<T>(inout value:T!,_ key:String, fallback:T, transform:(JSON)->Result<T>) -> JSONDecoder {
        if self.error != nil {
            return self
        }
        if let jsonValue:JSON = json[key] {
            return bindResult(&value,key, transform(jsonValue))
        }
        else  {
            value = fallback
            return self
        }
    }
    
    public func optionalBind<T>(inout value:T?,_ key:String, fallback:T? = nil, transform:(JSON)->Result<T>) -> JSONDecoder {
        if self.error != nil {
            return self
        }
        if let jsonValue:JSON = json[key] {
            return bindResult(&value,key, transform(jsonValue))
        }
        else  {
            value = fallback
            return self
        }
    }
    
    // Bind Results
    
    private func bindResult<T>(inout value:T, _ key:String, _ result: Result<T>) -> JSONDecoder {
        switch(result) {
        case .Success(let decoded):
            value = decoded.unbox
            return self
        case .Failure(let error):
            return JSONDecoder(json,error:JSONDecoder.addContextToError(error,context:key))
        default:
            return JSONDecoder(json,error:JSONDecoder.unknownError())
        }
    }
    
    private func bindResult<T>(inout value:T?, _ key:String, _ result: Result<T>) -> JSONDecoder {
        switch(result) {
        case .Success(let decoded):
            value = decoded.unbox
            return self
        case .Failure(let error):
            return JSONDecoder(json,error:JSONDecoder.addContextToError(error,context:key))
        default:
            return JSONDecoder(json,error:JSONDecoder.unknownError())
        }
    }
    
    private func bindResult<T>(inout value:T!, _ key:String, _ result: Result<T>) -> JSONDecoder {
        switch(result) {
        case .Success(let decoded):
            value = decoded.unbox
            return self
        case .Failure(let error):
            return JSONDecoder(json,error:JSONDecoder.addContextToError(error,context:key))
        default:
            return JSONDecoder(json,error:JSONDecoder.unknownError())
        }
    }
    
    // Errors
    
    private static func addContextToError(error:NSError,context:NSString) -> NSError {
        
        var newContext:String
        
        if let keypath = error.userInfo?[kJSONDecoderErrorPath] as? String {
            
            if keypath.hasPrefix("[") {
                newContext = context.stringByAppendingString(keypath)
            }
            else {
                newContext = "\(context).\(keypath)"
            }
        }
        else {
            newContext = context
        }
        
        var userInfo = error.userInfo ?? [NSObject : AnyObject]()
        userInfo[kJSONDecoderErrorPath] = newContext
        userInfo[NSUnderlyingErrorKey] = error
        
        return NSError(domain: error.domain, code: error.code, userInfo: userInfo)
    }
    
    private static func unknownError() -> NSError {
        return NSError(domain: kJSONDecoderErrorDomain, code: JSONDecoderError.UnknownError.rawValue, userInfo: nil)
    }
    
    private static func keyAbsentError(key:String) -> NSError {
        return NSError(domain: kJSONDecoderErrorDomain, code: JSONDecoderError.KeyAbsent.rawValue,
            userInfo: [kJSONDecoderErrorPath:key,])
    }
    
    private static func castError(description:NSString? = nil) -> NSError {
        return NSError(domain: kJSONDecoderErrorDomain, code: JSONDecoderError.InvalidObjectType.rawValue, userInfo: nil)
    }
    
}

// Decoding functions

public func decodeJSON<T:JSONDecodable>(json:JSON) -> Result<T> {
    return T.decodeJSON(json)
}

public func decodeJSON<T:JSONMutableDecodable>(json:JSON) -> Result<T> {
    var value = T()
    return value.mutateByJSON(json)
}

public func decodeJSON<T>(json:JSON, transform: (JSON)->Result<T>) -> Result<Array<T>> {
    
    if let jsonArray = json.asArray() {
        
        var results = [T]()
        results.reserveCapacity(jsonArray.count)
        
        for (index,jsonElement) in enumerate(jsonArray) {
            let result:Result<T> = transform(jsonElement)
            
            switch result {
            case .Failure(let error):
                return failure(JSONDecoder.addContextToError(error,context:"[\(index)]"))
            case .Success(let boxed):
                results.append(boxed.unbox)
            default:
                return failure()
            }
        }
        return success(results)
    }
    else {
        return failure(JSONDecoder.castError())
    }
}

public func decodeJSON<T:JSONDecodable>(json:JSON) -> Result<Array<T>> {
    return decodeJSON(json) { (json:JSON) -> Result<T> in decodeJSON(json) }
}

public func decodeJSON<T:JSONMutableDecodable>(json:JSON) -> Result<Array<T>> {
    return decodeJSON(json) { (json:JSON) -> Result<T> in decodeJSON(json) }
}

public func mutateByJSON<T:JSONMutable>(inout value:T, json:JSON) -> Result<T> {
    return value.mutateByJSON(json)
}

// support decodable objects in decoder

public extension JSONDecoder {
    
    // optional bind mutable
    
    public func optionalBind<T:JSONMutable>(inout value:T,_ key:String, fallback:T) -> JSONDecoder {
        return optionalBind(&value,key,fallback:fallback) { (json:JSON) -> Result<T> in return mutateByJSON(&value,json) }
    }
    
    public func optionalBind<T:JSONMutableDecodable>(inout value:T!,_ key:String, fallback:T) -> JSONDecoder {
        return optionalBind(&value,key,fallback:fallback) { (json:JSON) -> Result<T> in return decodeJSON(json) }
    }
    
    public func optionalBind<T:JSONMutableDecodable>(inout value:T?,_ key:String, fallback:T? = nil) -> JSONDecoder {
        return optionalBind(&value,key,fallback:fallback) { (json:JSON) -> Result<T> in return decodeJSON(json) }
    }
    
    // optional bind decodable
    
    public func optionalBind<T:JSONDecodable>(inout value:T,_ key:String, fallback:T) -> JSONDecoder {
        return optionalBind(&value,key,fallback:fallback) { (json:JSON) -> Result<T> in return decodeJSON(json) }
    }
    
    public func optionalBind<T:JSONDecodable>(inout value:T!,_ key:String, fallback:T) -> JSONDecoder {
        return optionalBind(&value,key,fallback:fallback) { (json:JSON) -> Result<T> in return decodeJSON(json) }
    }
    
    public func optionalBind<T:JSONDecodable>(inout value:T?,_ key:String, fallback:T? = nil) -> JSONDecoder {
        return optionalBind(&value,key,fallback:fallback) { (json:JSON) -> Result<T> in return decodeJSON(json) }
    }
    
    // bind decodable array
    
    public func bind<T:JSONDecodable>(inout value:Array<T>,_ key:String) -> JSONDecoder {
        return bind(&value,key) { (json:JSON) -> Result<Array<T>> in return decodeJSON(json) }
    }
    
    public func bind<T:JSONDecodable>(inout value:Array<T>!,_ key:String) -> JSONDecoder {
        return bind(&value,key) { (json:JSON) -> Result<Array<T>> in return decodeJSON(json) }
    }
    
    public func bind<T:JSONDecodable>(inout value:Array<T>?,_ key:String) -> JSONDecoder {
        return bind(&value,key) { (json:JSON) -> Result<Array<T>> in return decodeJSON(json) }
    }
    
    // bind MutableDecodable array
    
    public func bind<T:JSONMutableDecodable>(inout value:Array<T>,_ key:String) -> JSONDecoder {
        return bind(&value,key) { (json:JSON) -> Result<Array<T>> in return decodeJSON(json) }
    }
    
    public func bind<T:JSONMutableDecodable>(inout value:Array<T>!,_ key:String) -> JSONDecoder {
        return bind(&value,key) { (json:JSON) -> Result<Array<T>> in return decodeJSON(json) }
    }
    
    public func bind<T:JSONMutableDecodable>(inout value:Array<T>?,_ key:String) -> JSONDecoder {
        return bind(&value,key) { (json:JSON) -> Result<Array<T>> in return decodeJSON(json) }
    }
    
    // optional bind decodable array
    
    public func optionalBind<T:JSONDecodable>(inout value:Array<T>,_ key:String, fallback: Array<T>) -> JSONDecoder {
        return optionalBind(&value,key,fallback:fallback) { (json:JSON) -> Result<Array<T>> in return decodeJSON(json) }
    }
    
    public func optionalBind<T:JSONDecodable>(inout value:Array<T>!,_ key:String, fallback: Array<T>) -> JSONDecoder {
        return optionalBind(&value,key,fallback:fallback) { (json:JSON) -> Result<Array<T>> in return decodeJSON(json) }
    }
    
    public func optionalBind<T:JSONDecodable>(inout value:Array<T>?,_ key:String, fallback: Array<T>? = nil) -> JSONDecoder {
        return optionalBind(&value,key,fallback:fallback) { (json:JSON) -> Result<Array<T>> in return decodeJSON(json) }
    }
    
    // optional  bind MutableDecodable array
    
    public func optionalBind<T:JSONMutableDecodable>(inout value:Array<T>,_ key:String, fallback: Array<T>) -> JSONDecoder {
        return optionalBind(&value,key,fallback:fallback) { (json:JSON) -> Result<Array<T>> in return decodeJSON(json) }
    }
    
    public func optionalBind<T:JSONMutableDecodable>(inout value:Array<T>!,_ key:String, fallback: Array<T>) -> JSONDecoder {
        return optionalBind(&value,key,fallback:fallback) { (json:JSON) -> Result<Array<T>> in return decodeJSON(json) }
    }
    
    public func optionalBind<T:JSONMutableDecodable>(inout value:Array<T>?,_ key:String, fallback: Array<T>? = nil) -> JSONDecoder {
        return optionalBind(&value,key,fallback:fallback) { (json:JSON) -> Result<Array<T>> in return decodeJSON(json) }
    }
    
    // bind mutable
    
    public func bind<T:JSONMutable>(inout value:T,_ key:String) -> JSONDecoder {
        return bind(&value,key) { (json:JSON) -> Result<T> in return mutateByJSON(&value,json) }
    }
    
    public func bind<T:JSONMutableDecodable>(inout value:T!,_ key:String) -> JSONDecoder {
        return bind(&value,key) { (json:JSON) -> Result<T> in return decodeJSON(json) }
    }
    
    public func bind<T:JSONMutableDecodable>(inout value:T?,_ key:String) -> JSONDecoder {
        return bind(&value,key) { (json:JSON) -> Result<T> in return decodeJSON(json) }
    }
    
    // bind decodable
    
    public func bind<T:JSONDecodable>(inout value:T,_ key:String) -> JSONDecoder {
        return bind(&value,key) { (json:JSON) -> Result<T> in return decodeJSON(json) }
    }
    
    public func bind<T:JSONDecodable>(inout value:T?,_ key:String) -> JSONDecoder {
        return bind(&value,key) { (json:JSON) -> Result<T> in return decodeJSON(json) }
    }
    
    public func bind<T:JSONDecodable>(inout value:T!,_ key:String) -> JSONDecoder {
        return bind(&value,key) { (json:JSON) -> Result<T> in return decodeJSON(json) }
    }
}


// More magic!

func mapJSON<V:JSONDecodable,T>(json:JSON, transform: (V)->Result<T>) -> Result<T> {
    return decodeJSON(json).flatMap { transform($0) }
}

func mapJSON<V:JSONMutableDecodable,T>(json:JSON, transform: (V)->Result<T>) -> Result<T> {
    return decodeJSON(json).flatMap { transform($0) }
}

func mapJSON<V:JSONDecodable,T>(json:JSON, transform: (V)->T?) -> Result<T> {
    return decodeJSON(json).flatMap { optionalSuccess(transform($0),error: JSONDecoder.castError()) }
}

func mapJSON<V:JSONMutableDecodable,T>(json:JSON, transform: (V)->T?) -> Result<T> {
    return decodeJSON(json).flatMap { optionalSuccess(transform($0),error: JSONDecoder.castError()) }
}

func mapJSON<V:JSONDecodable,T>(json:JSON, transform: (V)->T) -> Result<T> {
    return decodeJSON(json).flatMap { success(transform($0)) }
}

func mapJSON<V:JSONMutableDecodable,T>(json:JSON, transform: (V)->T) -> Result<T> {
    return decodeJSON(json).flatMap { success(transform($0)) }
}

extension JSONDecoder {
    
    public func bind<T,V:JSONDecodable>(inout value:T,_ key:String, transform:(V)->Result<T>) -> JSONDecoder {
        return bind(&value,key) { mapJSON($0,transform) }
    }
    
    public func bind<T,V:JSONDecodable>(inout value:T,_ key:String, transform:(V)->T) -> JSONDecoder {
        return bind(&value,key) { mapJSON($0,transform) }
    }
    
    public func bind<T,V:JSONDecodable>(inout value:T,_ key:String, transform:(V)->T?) -> JSONDecoder {
        return bind(&value,key) { mapJSON($0,transform) }
    }
    
    public func bind<T,V:JSONDecodable>(inout value:T!,_ key:String, transform:(V)->Result<T>) -> JSONDecoder {
        return bind(&value,key) { mapJSON($0,transform) }
    }
    
    public func bind<T,V:JSONDecodable>(inout value:T!,_ key:String, transform:(V)->T) -> JSONDecoder {
        return bind(&value,key) { mapJSON($0,transform) }
    }
    
    public func bind<T,V:JSONDecodable>(inout value:T!,_ key:String, transform:(V)->T?) -> JSONDecoder {
        return bind(&value,key) { mapJSON($0,transform) }
    }
    
    public func bind<T,V:JSONDecodable>(inout value:T?,_ key:String, transform:(V)->Result<T>) -> JSONDecoder {
        return bind(&value,key) { mapJSON($0,transform) }
    }
    
    public func bind<T,V:JSONDecodable>(inout value:T?,_ key:String, transform:(V)->T) -> JSONDecoder {
        return bind(&value,key) { mapJSON($0,transform) }
    }
    
    public func bind<T,V:JSONDecodable>(inout value:T?,_ key:String, transform:(V)->T?) -> JSONDecoder {
        return bind(&value,key) { mapJSON($0,transform) }
    }
    
    public func optionalBind<T,V:JSONDecodable>(inout value:T,_ key:String, fallback:T, transform:(V)->Result<T>) -> JSONDecoder {
        return optionalBind(&value,key,fallback:fallback) { mapJSON($0,transform) }
    }
    
    public func optionalBind<T,V:JSONDecodable>(inout value:T,_ key:String, fallback:T, transform:(V)->T) -> JSONDecoder {
        return optionalBind(&value,key,fallback:fallback) { mapJSON($0,transform) }
    }
    
    public func optionalBind<T,V:JSONDecodable>(inout value:T,_ key:String, fallback:T, transform:(V)->T?) -> JSONDecoder {
        return optionalBind(&value,key,fallback:fallback) { mapJSON($0,transform) }
    }
    
    public func optionalBind<T,V:JSONDecodable>(inout value:T!,_ key:String, fallback:T, transform:(V)->Result<T>) -> JSONDecoder {
        return optionalBind(&value,key,fallback:fallback) { mapJSON($0,transform) }
    }
    
    public func optionalBind<T,V:JSONDecodable>(inout value:T!,_ key:String, fallback:T, transform:(V)->T) -> JSONDecoder {
        return optionalBind(&value,key,fallback:fallback) { mapJSON($0,transform) }
    }
    
    public func optionalBind<T,V:JSONDecodable>(inout value:T!,_ key:String, fallback:T, transform:(V)->T?) -> JSONDecoder {
        return optionalBind(&value,key,fallback:fallback) { mapJSON($0,transform) }
    }
    
    public func optionalBind<T,V:JSONDecodable>(inout value:T?,_ key:String, fallback:T? = nil, transform:(V)->Result<T>) -> JSONDecoder {
        return optionalBind(&value,key,fallback:fallback) { mapJSON($0,transform) }
    }
    
    public func optionalBind<T,V:JSONDecodable>(inout value:T?,_ key:String, fallback:T? = nil, transform:(V)->T) -> JSONDecoder {
        return optionalBind(&value,key,fallback:fallback) { mapJSON($0,transform) }
    }
    
    public func optionalBind<T,V:JSONDecodable>(inout value:T?,_ key:String, fallback:T? = nil, transform:(V)->T?) -> JSONDecoder {
        return optionalBind(&value,key,fallback:fallback) { mapJSON($0,transform) }
    }
}


// Base types support

 extension String: JSONDecodable {
    public static func decodeJSON(json:JSON) -> Result<String> {
        return optionalSuccess(json.asString(),error: JSONDecoder.castError())
    }
}

extension Double: JSONDecodable {
    public static func decodeJSON(json:JSON) -> Result<Double> {
        return optionalSuccess(json.asDouble(),error: JSONDecoder.castError())
    }
}

extension Float: JSONDecodable {
    public static func decodeJSON(json:JSON) -> Result<Float> {
        return optionalSuccess(json.asFloat(),error: JSONDecoder.castError())
    }
}

extension Bool: JSONDecodable {
    public static func decodeJSON(json:JSON) -> Result<Bool> {
        return optionalSuccess(json.asBool(),error: JSONDecoder.castError())
    }
}

extension Int: JSONDecodable {
    public static func decodeJSON(json:JSON) -> Result<Int> {
        return optionalSuccess(json.asInt(),error: JSONDecoder.castError())
    }
}














