import XCTest
@testable import FloGraph
import FloBox

private let DATE = Struct.type(named:"Date")!
private typealias Err = Parser.Err

final class EvalTests: XCTestCase {
    
    func test_primitives() throws {
        "true" ==>> [ true ]
        "false" ==>> [ false ]
        "true;false" ==>> [ true,false ]
    }
    
    func test_arrays___()throws{
        //"[[true]]" ==>> [ [[true]] ]
    }
    
    func test_arrays()throws{
        "[true]" ==>> [ [true] ]
        "[true,false]" ==>> [ [true,false] ]
        "[1.2]" ==>> [ [Float32(1.2)] ]
        "[1.2,3.4]" ==>> [ [Float32(1.2),Float32(3.4)] ]
        "[\"hello\",\"world\"]" ==>> [ ["hello","world"] ]
        "[\"hello\",\"wicky\",\"world\"]" ==>> [ ["hello","wicky","world"] ]
    }
    
}

fileprivate func ==>>(_ s:String, _ a:[(any Event.Value)?]){
    do{
        if let expr = try Parser.parse(expr:s){
            var vars = [String:(any Event.Value)]()
            let b = expr.evaluate(&vars)
            if a.count == b.count{
                for i in 0..<a.count{
                    if !(a[i]!.equals(b[i]!)){
                        XCTFail("failed at index \(i)")
                    }
                }
            }else{ XCTFail() }
        }else{ XCTFail() }
    }catch let e{
        XCTFail(e.localizedDescription)
    }
}
