import XCTest
@testable import FloGraph
import FloBox

private let DATE = Struct.type(named:"Date")!
private typealias Err = Parser.Err
private typealias ƒ = Float32

final class RDPTests: XCTestCase {
    /*
    func test_XXXX() throws {
        "acos(0.5)" ==>> .VAL(acosf(0.5))
        "asin(0.5)" ==>> .VAL(asinf(0.5))
        "atan(0.5)" ==>> .VAL(atanf(0.5))
    }
    
    func test_LISTS() throws {
        "true;false" ==>> .LIST([.VAL(true),.VAL(false)])
        "(true);((((false))))" ==>> .LIST([.VAL(true),.VAL(false)])
        "(12.34);\"hello\";true" ==>> .LIST([
            .VAL(ƒ(12.34)),
            .VAL("hello"),
            .VAL(true)
        ])
    }
    
    func test_STRING() throws {
        // atom
        "\"hello\"" ==>> .VAL("hello")
        "(((((\"hello\")))))" ==>> .VAL("hello")
        // casts
        "S(true)" ==>> .VAL("true")
        "S(false)" ==>> .VAL("false")
        "S(!true)" ==>> .VAL("false")
        "S(12.34)" ==>> .VAL("12.34")
        "S(-12.34)" ==>> .VAL("-12.34")
        "S(inf)" ==>> .VAL("inf")
        "S(nan)" ==>> .VAL("nan")
        "S(\"hello\")" ==>> .VAL("hello")
        // ops
        "lower(\"hello\")" ==>> .VAL("hello")
        "lower(\"HEllo\")" ==>> .VAL("hello")
        "lower(\"HELLO\")" ==>> .VAL("hello")
    }
    
    func test_FLOAT() throws {
        // atoms
        "12.34" ==>> .VAL(ƒ(12.34))
        "(((((((12.34)))))))" ==>> .VAL(ƒ(12.34))
        // negation
        "-12.34" ==>> .VAL(ƒ(-12.34))
        "-(12.34)" ==>> .VAL(ƒ(-12.34))
        "(-12.34)" ==>> .VAL(ƒ(-12.34))
        // casts
        "F(true)" ==>> .VAL(ƒ(1))
        "F(false)" ==>> .VAL(ƒ(0))
        "F(12.34)" ==>> .VAL(ƒ(12.34))
        "F(((-((12.34)))))" ==>> .VAL(ƒ(-12.34))
        "F(\"12.34\")" ==>> .VAL(ƒ(12.34))
        "F(\"-12.34\")" ==>> .VAL(ƒ(-12.34))
        "F(\"0xff\")" ==>> .VAL(ƒ(255))
        "F(\"2837.5e-2\")" ==>> .VAL(ƒ(28.375)) // exponents
        "F(\"0x1c.6\")" ==>> .VAL(ƒ(28.375)) // hexadecimal
        "F(\"inf\")" ==>> .VAL(ƒ.infinity) // infinity
        "F(\"nan\")" ==>> .VAL(ƒ.nan) // NaN
        // ops
        "abs(12.34)" ==>> .VAL(fabsf(12.34))
        "abs(-12.34)" ==>> .VAL(fabsf(-12.34))
        "ceil(12.34)" ==>> .VAL(ceilf(12.34))
        "floor(12.34)" ==>> .VAL(floorf(12.34))
        "round(12.34)" ==>> .VAL(roundf(12.34))
        "acos(0.5)" ==>> .VAL(acosf(0.5))
        "asin(0.5)" ==>> .VAL(asinf(0.5))
        "atan(0.5)" ==>> .VAL(atanf(0.5))
        "acos(12.34)" ==>> .VAL(acosf(12.34))
        "asin(12.34)" ==>> .VAL(asinf(12.34))
        "atan(12.34)" ==>> .VAL(atanf(12.34))
        "ln(12.34)" ==>> .VAL(logf(12.34))
        "exp(12.34)" ==>> .VAL(expf(12.34))
        "sqrt(12.34)" ==>> .VAL(sqrtf(12.34))
    }
    
    func test_BOOL() throws {
        // atoms
        "true" ==>> .VAL(true)
        "false" ==>> .VAL(false)
        "(false)" ==>> .VAL(false)
        // not
        "!false" ==>> .VAL(true)
        "!true" ==>> .VAL(false)
        // casts
        "B(true)" ==>> .VAL(true)
        "B(false)" ==>> .VAL(false)
        "B(-12.34)" ==>> .VAL(false)
        "B(12.34)" ==>> .VAL(true)
        "B(\"true\")" ==>> .VAL(true)
        "B(\"false\")" ==>> .VAL(false)
    }
    
}


fileprivate func ==>>(_ s:String, _ expected_ast:AST){
    do{
        let found_ast = try RDP.parse(s)
        if found_ast != expected_ast{
            XCTFail("found = \(found_ast.s), expected = \(expected_ast.s)")
        }else{
            __TLOG__("⬛︎ \(found_ast.s)")
        }
    }catch let e{
        XCTFail("\(e)")
    }
     */
}
