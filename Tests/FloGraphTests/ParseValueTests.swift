import XCTest
@testable import FloGraph
import FloBox

private let DATE = Struct.type(named:"Date")!
private typealias Err = Parser.Err

final class ParseValueTests: XCTestCase {
    
    func test_XXXX() throws {
    }
    
    func test_Floats() throws {
        ("12.34",.FLOAT()) ==>> Float32(12.34)
        ("-12.34",.FLOAT()) ==>> -Float32(12.34)
    }
    
}

fileprivate func ==>>(_ y:(String,T), _ v:any Event.Value){
    do{
        let x = try Parser.parse(value:y.0,type:y.1)
        if !x.equals(v){
            XCTFail("found = \(x.s), expected = \(v.s)")
        }else{
            __TLOG__("⬛︎ \(x.s)")
        }
    }catch let e{
        XCTFail("\(e)")
    }
}
