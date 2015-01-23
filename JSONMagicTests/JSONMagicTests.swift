//
//  JSONMagicTests.swift
//  JSONMagicTests
//
//

import UIKit
import XCTest
import JSONMagic

class JSONMagicTests: XCTestCase {
    
    func jsonFromString(string:String) -> JSON {
        let jsonString = string.stringByReplacingOccurrencesOfString("'", withString: "\"", options: .allZeros, range: nil)
        
        return JSON(jsonData:jsonString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)!)!
    }
    
    func testExample() {
        
        struct Leaf : JSONDecodable {
            var name: String
            var identifier: Int
            var date: NSDate
            
            static func decodeJSON(json: JSON) -> Result<Leaf> {
                var name: String!
                var identifier: Int!
                var date: NSDate!
                
                return JSONDecoder(json)
                    .optionalBind(&name,"name",fallback: "Unnamed")
                    .bind(&identifier,"id")
                    .bind(&date,"timestamp") { NSDate(timeIntervalSince1970: $0) }
                    .result(Leaf(name: name, identifier:identifier, date: date))
            }
        }

        final class Root : NSObject, JSONMutableDecodable {
            var title:String = ""
            var leafs:[Leaf] = []
            var date:NSDate? = nil
            
            func mutateByJSON(json: JSON) -> Result<Root> {
                return JSONDecoder(json)
                    .bind(&title,"title")
                    .optionalBind(&leafs,"leafs",fallback: [])
                    .optionalBind(&date,"timestamp") { NSDate(timeIntervalSince1970: $0) }
                    .result(self)
            }
        }

        let json:JSON = jsonFromString("{'title':'s','leafs':[]}")

        var root = Root()
        let result = root.mutateByJSON(json)

        XCTAssert(result.isSuccess())
    }
    
    func testMutable() {
        
        struct Root : JSONMutable {
            var title:String = ""
            var date:NSDate? = nil
            
            static func decodeJSON(json: JSON) -> Result<Root> {
                var root = Root()
                return root.mutateByJSON(json)
            }
            
            init() {
                self = Root(title:"")
            }
            
            init(title:String) {
                self.title = title
            }

            mutating func mutateByJSON(json: JSON) -> Result<Root> {
                return JSONDecoder(json)
                    .bind(&title,"title")
                    .optionalBind(&date,"timestamp") { NSDate(timeIntervalSince1970: $0) }
                    .result(self)
            }
        }
        
        let json:JSON = jsonFromString("{'s':{'title':'s','leafs':[]}}")
        
        var root:Root = Root()
        var oRoot:Root?
        var iuoRoot:Root!
        
        let result = JSONDecoder(json)
            .bind(&root,"s")
            .result(true)
        
        XCTAssert(result.isSuccess())
    }
    
    func testArray() {
        
        let json:JSON = jsonFromString("{'strArray':['a','b']}")
        
        var array: [String] = []
        var oArray: [String]?
        var euoArray: [String]!
        
        let result = JSONDecoder(json)
            .bind(&array,"strArray")
            .bind(&oArray,"strArray")
            .bind(&euoArray,"strArray")
            .result(true)
        
        XCTAssert(result.value() ?? false)
        
        XCTAssertEqual(array,["a","b"])
        XCTAssertEqual(euoArray,["a","b"])
        XCTAssertEqual(oArray!,["a","b"])
    }
    
    func testOptionalArray() {
        
        let json:JSON = jsonFromString("{'strArray':['a','b']}")
        
        var array: [String] = []
        var oArray: [String]?
        var iuoArray: [String]!
        
        let result = JSONDecoder(json)
            .optionalBind(&array,"strArray",fallback:[])
            .optionalBind(&oArray,"strArray")
            .optionalBind(&iuoArray,"strArray",fallback:[])
            .result(true)
        
        XCTAssert(result.value() ?? false)
        
        XCTAssertEqual(array,["a","b"])
        XCTAssertEqual(iuoArray,["a","b"])
        XCTAssertEqual(oArray!,["a","b"])
    }
    
    
    func testOptionalDecodable() {
        
        let json:JSON = jsonFromString("{}")
        
        var value: String = ""
        var oValue: String?
        var oValueFallback: String?
        var euoValue: String!
        
        let result = JSONDecoder(json)
            .optionalBind(&value,"v",fallback:"z")
            .optionalBind(&oValue,"v")
            .optionalBind(&oValueFallback,"v",fallback:"z")
            .optionalBind(&euoValue,"v",fallback:"z")
            .result(true)
        
        XCTAssert(result.value() ?? false)
        
        XCTAssertEqual(value,"z")
        XCTAssertNil(oValue)
        XCTAssertEqual(oValueFallback!,"z")
        XCTAssertEqual(euoValue,"z")
    }
    
    
    func testDecodable() {
        
        let json:JSON = jsonFromString("{'v':'v'}")
        
        var value: String = ""
        var oValue: String?
        var euoValue: String!
        
        let result = JSONDecoder(json)
            .bind(&value,"v")
            .bind(&oValue,"v")
            .bind(&euoValue,"v")
            .result(true)
        
        XCTAssert(result.value() ?? false)
        
        XCTAssertEqual(value,"v")
        XCTAssertEqual(oValue!,"v")
        XCTAssertEqual(euoValue,"v")
    }
    
    func testBaseTypes() {
        
        let json:JSON = jsonFromString("{'str':'str','num':1,'float':1.1,'bool':true}")
        
        var string: String!
        var int: Int!
        var double: Double!
        var float: Float!
        var bool: Bool!
        
        let result = JSONDecoder(json)
            .bind(&string,"str")
            .bind(&int,"num")
            .bind(&double,"float")
            .bind(&float,"float")
            .bind(&bool,"bool")
            .result(true)
        
        XCTAssert(result.value() ?? false)
        
        XCTAssertEqual(string,"str")
        XCTAssertEqual(int,1)
        XCTAssertEqual(float,Float(1.1))
        XCTAssertEqual(double,1.1)
        XCTAssertEqual(bool,true)
    }
    
    struct TestDecodable: JSONDecodable {
        
        var string: String
        var optional: String? = nil
        var bool: Bool
        
        static func decodeJSON(json: JSON) -> Result<TestDecodable> {
            
            var string: String!
            var optional: String?
            var bool: Bool = false
            
            return JSONDecoder(json)
                .bind(&string,"v")
                .optionalBind(&optional,"optional")
                .optionalBind(&bool,"ok",fallback:false)
                .result(TestDecodable(string: string, optional: optional, bool: bool))
        }
    }
    
    func testDecodableStruct() {
        
        let json:JSON = jsonFromString("{'s':{'v':'v','ok':true}}")
        
        var decodable: TestDecodable = TestDecodable(string: "", optional: nil, bool: false)
        var oDecodable: TestDecodable?
        var iuoDecodable: TestDecodable!
        
        let result = JSONDecoder(json)
            .bind(&decodable,"s")
            .bind(&oDecodable,"s")
            .bind(&iuoDecodable,"s")
            .result(true)
        
        XCTAssert(result.value() ?? false)
        
        XCTAssertEqual(decodable.string,"v")
        XCTAssertEqual(decodable.bool,true)
        XCTAssertNil(decodable.optional)
    }
    
    struct TestMutableDecodable: JSONMutableDecodable {
        
        var string: String = ""
        var optional: String? = nil
        var bool: Bool = false
        
        mutating func mutateByJSON(json: JSON) -> Result<TestMutableDecodable> {
            return JSONDecoder(json)
                .bind(&string,"v")
                .optionalBind(&optional,"optional")
                .optionalBind(&bool,"ok",fallback:false)
                .result(self)
        }
    }
    
    func testMutableDecodableStruct() {
        
        let json:JSON = jsonFromString("{'s':{'v':'v','ok':true}}")
        
        var decodable: TestMutableDecodable = TestMutableDecodable()
        var oDecodable: TestMutableDecodable?
        var iuoDecodable: TestMutableDecodable!
        
        let result = JSONDecoder(json)
            .bind(&decodable,"s")
            .bind(&oDecodable,"s")
            .bind(&iuoDecodable,"s")
            .result(true)
        
        XCTAssert(result.value() ?? false)
        
        XCTAssertEqual(decodable.string,"v")
        XCTAssertEqual(decodable.bool,true)
        XCTAssertNil(decodable.optional)
    }
    
    func testMutableDecodable() {
        
        let json:JSON = jsonFromString("{'v':'v','ok':true}")
        
        let result:Result<TestDecodable> = decodeJSON(json)
        
        XCTAssertNil(result.error())
        
        let testDecodable = result.value()!
        
        XCTAssertEqual(testDecodable.string,"v")
        XCTAssertEqual(testDecodable.bool,true)
        XCTAssertNil(testDecodable.optional)
    }
    
    func testComponoundStructs() {
        
        let json:JSON = jsonFromString("{'a':{'v':'1'},'b':{'v':'2'}}")
        
        
        var a: TestMutableDecodable!
        var b: TestDecodable!
        
        let result = JSONDecoder(json)
            .bind(&a,"a")
            .bind(&b,"b")
            .result(true)
        
        XCTAssert(result.value() ?? false)
        
        let testDecodable = result.value()!
        
        XCTAssertEqual(a.string,"1")
        XCTAssertEqual(b.string,"2")
    }
    
    func testStructArrays() {
        
        let json:JSON = jsonFromString("{'a':[{'v':'1'},{'v':'2'}]}")
        
        var a: [TestMutableDecodable]!
        var b: [TestDecodable]!
        
        let result = JSONDecoder(json)
            .bind(&a,"a")
            .bind(&b,"a")
            .result(true)
        
        XCTAssert(result.value() ?? false)
        
        XCTAssertEqual(a[0].string,"1")
        XCTAssertEqual(a[1].string,"2")
        
        XCTAssertEqual(b[0].string,"1")
        XCTAssertEqual(b[1].string,"2")
    }
    
    func testValueTransformation() {
        
        let json:JSON = jsonFromString("{'a':{'v':'1'},'b':{'v':'2'}}")
        
        var a: TestMutableDecodable!
        var b: TestDecodable!
        
        let result = JSONDecoder(json)
            .bind(&a,"a")
            .bind(&b,"b")
            .result(true)
        
        XCTAssert(result.value() ?? false)
        
        let testDecodable = result.value()!
        
        XCTAssertEqual(a.string,"1")
        XCTAssertEqual(b.string,"2")
    }
    
    func testOptionalError() {
        
        let json:JSON = jsonFromString("{'a':[{'v':'1'},{}]}")
        
        var a: [TestDecodable]!
        
        let result = JSONDecoder(json)
            .bind(&a,"a")
            .result(true)
        
        XCTAssertNotNil(result.error())
        
        let error = result.error()!
        
        XCTAssertEqual(error.code,JSONDecoderError.KeyAbsent.rawValue)
        XCTAssertEqual(error.userInfo![kJSONDecoderErrorPath] as String,"a[1].v")
        
    }
    
    func testDataTypeError() {
        
        let json:JSON = jsonFromString(
            "{'strArray':['a','b']}"
        )
        
        NSLog("\(json)")
        var decodable: TestMutableDecodable!
        
        let result = JSONDecoder(json)
            .bind(&decodable,"strArray")
            .result(true)
        
        XCTAssertNotNil(result.error())
        
        let error = result.error()!
        
        XCTAssertEqual(error.code,JSONDecoderError.InvalidObjectType.rawValue)
        XCTAssertEqual(error.userInfo![kJSONDecoderErrorPath] as String,"strArray")
    }
    
    func testMapDecode() {
        
        let formatter = NSDateFormatter()
        formatter.dateFormat = "YYYY-M-d"
        
        let json:JSON = jsonFromString(
            "{'date':'2015-01-01','i':1}"
        )
        
        NSLog("\(json)")
        
        var date: NSDate = NSDate()
        var iuoDate: NSDate!
        var oDate: NSDate?
        
        var int:Int = 0
        var iuoInt:Int!
        var oInt:Int?
        
        var date2: NSDate!
        
        let result = JSONDecoder(json)
            .bind(&date,"date") { formatter.dateFromString($0) }
            .bind(&iuoDate,"date") { (s:String)->NSDate? in  formatter.dateFromString(s) }
            .bind(&oDate,"date") { formatter.dateFromString($0) }
            .bind(&int,"i") { $0 + 1 }
            .bind(&iuoInt,"i") { $0 + 1 }
            .bind(&oInt,"i") { $0 + 1 }
            
            .bind(&date2,"i") { NSDate(timeIntervalSince1970:$0) }
            
            .result(true)
        
        XCTAssert(result.value() ?? false)
        
        let resultDate = formatter.dateFromString("2015-01-01")!
        
        XCTAssertEqual(date,resultDate)
        XCTAssertEqual(iuoDate,resultDate)
        XCTAssertEqual(oDate!,resultDate)
        
        XCTAssertEqual(int,2)
        XCTAssertEqual(iuoInt,2)
        XCTAssertEqual(oInt!,2)
        
    }
    
    
    func testOptionalMapDecode() {
        
        let formatter = NSDateFormatter()
        formatter.dateFormat = "YYYY-M-d"
        
        let json:JSON = jsonFromString(
            "{'date':'2015-01-01', 'i':1}"
        )
        
        NSLog("\(json)")
        
        var date: NSDate = NSDate()
        var iuoDate: NSDate!
        var oDate: NSDate?
        
        var int = 0.0
        var iuoInt:Int!
        var oInt:Int?
        
        let result = JSONDecoder(json)
            .optionalBind(&date,"date",fallback: NSDate()) { formatter.dateFromString($0) }
            .optionalBind(&iuoDate,"date",fallback: NSDate()) { formatter.dateFromString($0) }
            .optionalBind(&oDate,"date") { formatter.dateFromString($0) }
            
            .optionalBind(&int,"i",fallback: 0) { $0 + 1 }
            .optionalBind(&iuoInt,"i",fallback: 0) { $0 + 1 }
            .optionalBind(&oInt,"i") { $0 + 1 }
            .result(true)
        
        XCTAssert(result.value() ?? false)
        
        let resultDate = formatter.dateFromString("2015-01-01")!
        
        XCTAssertEqual(date,resultDate)
        XCTAssertEqual(iuoDate,resultDate)
        XCTAssertEqual(oDate!,resultDate)
        
        XCTAssertEqual(int,2)
        XCTAssertEqual(iuoInt,2)
        XCTAssertEqual(oInt!,2)
    }
    
    func testSimpleDecode() {
        
        let json:JSON = jsonFromString(
            "{'a':'a','b':1,'c':1.1,'e':1.2," +
                "'strArray':['a','b']," +
            "'end':'end'}"
        )
        
        NSLog("\(json)")
        
        var a: String!
        var b: Int!
        var c: Double = 0
        var d: Double!
        var e: Float = -1
        var strArray: [String]!
        
        let result = JSONDecoder(json)
            .bind(&a,"a")
            .bind(&b,"b")
            .optionalBind(&c,"c", fallback: 2)
            .optionalBind(&d,"d", fallback: 3)
            .bind(&e,"e")
            .bind(&strArray,"strArray")
            .result(true)
        
        XCTAssert(result.value() ?? false)
        
        XCTAssertEqual(a,"a")
        XCTAssertEqual(b,1)
        XCTAssertEqual(c,1.1)
        XCTAssertEqual(d,3)
        XCTAssertEqual(e,Float(1.2))
        XCTAssertEqual(strArray,["a","b"])
    }

    
}
