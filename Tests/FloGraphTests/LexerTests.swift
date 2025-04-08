import XCTest
@testable import FloGraph
import FloBox

func __TLOG__(_ s:String){ Swift.print(s)}

private let DATE = Struct.type(named:"Date")!
private typealias Err = Parser.Err

final class LexerTests: XCTestCase {
    
    // MARK: ■ ==>>
    
    let __types__:[T] = [ Bool.t, Data.t, Float32.t, String.t, DATE ]
    func testVars() throws {
        "a" ==>> [.VAR("a")]
        "(b)" ==>> [.PUNC(.ROUND_L),.VAR("b"),.PUNC(.ROUND_R)]
        for t in __types__{
            "c:\(t.s$)" ==>> [.VAR("c",t)]
            "(d:\(t.s$))" ==>> [.PUNC(.ROUND_L),.VAR("d",t),.PUNC(.ROUND_R)]
            "e:[\(t.s$)]" ==>> [.VAR("e",.ARRAY(t))]
            "(f:[\(t.s$)])" ==>> [.PUNC(.ROUND_L),.VAR("f",.ARRAY(t)),.PUNC(.ROUND_R)]
        }
    }
    
    func testBool() throws {
        "true" ==>> [.VAL(true)]
        "!true" ==>> [.ID("!"),.VAL(true)]
        "false" ==>> [.VAL(false)]
        "true|false" ==>> [.VAL(true),.ID("|"),.VAL(false)]
        "!a" ==>> [.ID("!"),.VAR("a")]
        "a|b" ==>> [.VAR("a"),.ID("|"),.VAR("b")]
        "a&b" ==>> [.VAR("a"),.ID("&"),.VAR("b")]
        "a^b" ==>> [.VAR("a"),.ID("^"),.VAR("b")]
        "a==b" ==>> [.VAR("a"),.ID("=="),.VAR("b")]
        "a!=b" ==>> [.VAR("a"),.ID("!="),.VAR("b")]
        "1.2==3.4" ==>> [.VAL(Float32(1.2)),.ID("=="),.VAL(Float32(3.4))]
        "1.2!=3.4" ==>> [.VAL(Float32(1.2)),.ID("!="),.VAL(Float32(3.4))]
        "1.2>3.4" ==>> [.VAL(Float32(1.2)),.ID(">"),.VAL(Float32(3.4))]
        "1.2>=3.4" ==>> [.VAL(Float32(1.2)),.ID(">="),.VAL(Float32(3.4))]
        "1.2<3.4" ==>> [.VAL(Float32(1.2)),.ID("<"),.VAL(Float32(3.4))]
        "1.2<=3.4" ==>> [.VAL(Float32(1.2)),.ID("<="),.VAL(Float32(3.4))]
        "\"hello\"==\"world\"" ==>> [.VAL(String("hello")),.ID("=="),.VAL(String("world"))]
        "\"hello\"!=\"world\"" ==>> [.VAL(String("hello")),.ID("!="),.VAL(String("world"))]
        "\"hello\">\"world\"" ==>> [.VAL(String("hello")),.ID(">"),.VAL(String("world"))]
        "\"hello\">=\"world\"" ==>> [.VAL(String("hello")),.ID(">="),.VAL(String("world"))]
        "\"hello\"<\"world\"" ==>> [.VAL(String("hello")),.ID("<"),.VAL(String("world"))]
        "\"hello\"<=\"world\"" ==>> [.VAL(String("hello")),.ID("<="),.VAL(String("world"))]
    }
    
    func testFloats() throws {
        "1.2" ==>> [.VAL(Float32(1.2))]
        "abs" ==>> [.ID("abs")]
        "abs(1.2)" ==>> [.ID("abs"),.PUNC(.ROUND_L),.VAL(Float32(1.2)),.PUNC(.ROUND_R)]
        "ceil" ==>> [.ID("ceil")]
        "floor" ==>> [.ID("floor")]
        "round" ==>> [.ID("round")]
        "trunc" ==>> [.ID("trunc")]
        "clamp" ==>> [.ID("clamp")]
        "cos" ==>> [.ID("cos")]
        "sin" ==>> [.ID("sin")]
        "tan" ==>> [.ID("tan")]
        "acos" ==>> [.ID("acos")]
        "asin" ==>> [.ID("asin")]
        "atan" ==>> [.ID("atan")]
        "log" ==>> [.ID("log")]
        "exp" ==>> [.ID("exp")]
        "min" ==>> [.ID("min")]
        "max" ==>> [.ID("max")]
        "pow" ==>> [.ID("pow")]
        "sqrt" ==>> [.ID("sqrt")]
        "+" ==>> [.ID("+")]
        "-" ==>> [.ID("-")]
        "*" ==>> [.ID("*")]
        "/" ==>> [.ID("/")]
    }
    
    func test_ID()throws{
        "a" ==>> [.VAR("a")]
        "_" ==>> [.ID("_")]
        "_b" ==>> [.ID("_b")]
        "abcdefghijklmnopqrstuvwxyz" ==>> [.ID("abcdefghijklmnopqrstuvwxyz")]
        "_1234567890" ==>> [.ID("_1234567890")]
        "ABCDEFGHIJKLMNOPQRSTUVWXYZ" ==>> [.ID("ABCDEFGHIJKLMNOPQRSTUVWXYZ")]
    }
    
    func test_PUNC()throws{
        ":" ==>> [.PUNC(.COLON)]
        "," ==>> [.PUNC(.COMMA)]
        "[" ==>> [.PUNC(.SQUARE_L)]
        "]" ==>> [.PUNC(.SQUARE_R)]
        "(" ==>> [.PUNC(.ROUND_L)]
        ")" ==>> [.PUNC(.ROUND_R)]
        "{" ==>> [.PUNC(.CURLY_L)]
        "}" ==>> [.PUNC(.CURLY_R)]
    }
    
    func test_OP()throws{
        // arithmetic
        for s in ["+","-","*","/","%"]{ s ==>> [.ID(s)] }
        // boolean
        for s in ["!","&&","||"]{ s ==>> [.ID(s)] }
        // bitwise
        for s in ["&","|","^","<<",">>"]{ s ==>> [.ID(s)] }
        // comparison
        for s in ["==","!=",">",">=","<","<="]{ s ==>> [.ID(s)] }
    }
    
    func test_VALUE()throws{
        // boolean
        "false" ==>> [.VAL(false)]
        for s in ["true","false"]{ s ==>> [.VAL(Bool(s)!)] }
        // floats
        for s in ["1.2","3.45","6.7","0.890"]{ s ==>> [.VAL(Float32(s)!)] }
        // strings
        "\"hello\"" ==>> [.VAL("hello")]
        "\"he\\\"llo\"" ==>> [.VAL("he\\\"llo")]
        "\"he\\\"ll'(blah):+o\"" ==>> [.VAL("he\\\"ll'(blah):+o")]
    }
    
    func testOddities() throws {
        "x:B:B:B:B" ==>> [ .VAR("x",Bool.t) ] // equivalent to just "x:B"
    }
    
    func testStructs() throws {
        "X{x=4.5}" ==>> [.ID("X"),.PUNC(.CURLY_L),.ID("x"),.ID("="),.VAL(Float32(4.5)),.PUNC(.CURLY_R)]
        "foo.goo" ==>> [ .ID("foo"), .PUNC(.DOT), .ID("goo") ]
        "(q:XY).x" ==>> [
            .PUNC(.ROUND_L),
            .VAR("q",XY),
            .PUNC(.ROUND_R),
            .PUNC(.DOT),
            .ID("x")
        ]
    }
    
    // MARK: ERRORS
    
    func test_ERRORS()throws{
        // these are all the errors thrown by the lexer ...
        "x:X" ==>> Err.EXPECTED(.TYPE)
        "x:[B]:F" ==>> Err.CONFLICT(.TYPE) 
        "\"hello" ==>> Err.EXPECTED(.QUOTES)
        "∂" ==>> Err.EXPECTED(.CHARACTER)
    }
    
}


infix operator ==>>
fileprivate func ==>>(_ s:String, _ e:Err){
    do{
        _ = try Lexer(s).toks()
        XCTFail("expected \(e.localizedDescription)")
    }catch let _e{
        __TLOG__("expected: " + e.localizedDescription)
        __TLOG__("   found: " + _e.localizedDescription)
        XCTAssert(e == (_e as? Parser.Err))
    }
}
fileprivate func ==>>(_ s:String, _ t:[Tok]){
    do{
        let tokens = try Lexer(s).toks()
        __TLOG__(tokens.description)
        if !tokens.tokens.matches(t){
            __TLOG__("FAIL---")
            __TLOG__(tokens.description)
            XCTFail()
        }
    }catch let e{
        XCTFail(e.localizedDescription)
    }
}
