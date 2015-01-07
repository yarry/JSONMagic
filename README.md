JSONMagic
=========

Highly experimental JSON parsing library for Swift

## Usage

```swift
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

let Result<Leaf> = decodeJSON(JSON(data: jsonData))
```

You can mutate your model instead of constructing new:
```swift
final class Root : NSObject, JSONMutableDecodable {
    var title: String = ""
    var leafs: [Leaf] = []
    var date: NSDate? = nil
    
    func mutateByJSON(json: JSON) -> Result<Root> {
        return JSONDecoder(json)
            .bind(&title,"title")
            .optionalBind(&leafs,"leafs",fallback: [])
            .optionalBind(&date,"timestamp") { NSDate(timeIntervalSince1970: $0) }
            .result(self)
    }
}

var root: Root = createRoot()
let result = mutateByJSON(&root, json)
```