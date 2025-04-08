import XCTest
@testable import FloGraph
import FloBox

private let DATE = Struct.type(named:"Date")!
private typealias Err = Parser.Err

private let EMPTY_TEST_STRUCT = T.STRUCT("Empty",[:])

private let X_TEST_STRUCT = T.STRUCT("X",["x":Float32.t])

private let TEST_STRUCT = T.STRUCT("Test",[
    "float":Float32.t,
    "bool":Bool.t,
    "string":String.t,
    "data":.DATA,
    "array":.ARRAY(.BOOL()),
    "struct":XY
])

final class ParserTests: XCTestCase {
    
    override func setUp(){
        EMPTY_TEST_STRUCT.register()
        TEST_STRUCT.register()
    }
    
    func test_multiple_exprs() throws {
        "true;false" ==>> .LIST([.VAL(true),.VAL(false)])
        "1.2 ;3.4" ==>> .LIST([.VAL(Float32(1.2)),.VAL(Float32(3.4))])
        "true; 3.4" ==>> .LIST([.VAL(true),.VAL(Float32(3.4))])
        "true; 3.4; \"hello\"" ==>> .LIST([.VAL(true),.VAL(Float32(3.4)),.VAL("hello")])
    }
    
    // MARK: Boolean
    
    func test_atomic_bool() throws {
        "true" ==>> .VAL(true)
        "false" ==>> .VAL(false)
        // parentheses
        "(true)" ==>> .VAL(true) 
        "((((true))))" ==>> .VAL(true)
        // casts
        "B(true)" ==>> .EVAL(PI("B",[Bool.t],Bool.t),[.VAL(true)])
        "B(false)" ==>> .EVAL(PI("B",[Bool.t],Bool.t),[.VAL(false)])
        "B(x:B)" ==>> .EVAL(PI("B",[Bool.t],Bool.t),[.VAR("x",Bool.t)])
        "B(1.2)" ==>> .EVAL(PI("B",[Float32.t],Bool.t),[.VAL(Float32(1.2))])
        "B(x:F)" ==>> .EVAL(PI("B",[Float32.t],Bool.t),[.VAR("x",Float32.t)])
        "B(x:S)" ==>> .EVAL(PI("B",[String.t],Bool.t),[.VAR("x",String.t)])
        // array element
        var e:Expr = .EVAL(PI("°",[[Bool].t,Float32.t],Bool.t),[
            .EVAL(PI("[]",[],[Bool].t),[.VAL(true)]),.VAL(Float32(0))
        ])
        // ["₀","₁","₂","₃","₄","₅","₆","₇","₈","₉"]
        "[true]°0" ==>> e
        "[true]₀" ==>> e
        e = .EVAL(PI("°",[[Bool].t,Float32.t],Bool.t),[
            .EVAL(PI("[]",[],[Bool].t),[.VAL(true),.VAL(false)]),.VAL(Float32(0))
        ])
        "[true,false]°0" ==>> e
        "[true,false]₀" ==>> e
        e = .EVAL(PI("°",[[Bool].t,Float32.t],Bool.t),[
            .EVAL(PI("[]",[],[Bool].t),[.VAL(true),.VAL(false)]),.VAL(Float32(1))
        ])
        "[true,false]°1" ==>> e
        "[true,false]₁" ==>> e
        // STRUCTS
        e = .EVAL(PI(".",[TEST_STRUCT,String.t],Bool.t),[
            .VAR("x",TEST_STRUCT),.VAL("bool")
        ])
        "(x:Test).bool" ==>> e
    }
    
    func test_unary_bool() throws {
        "!true" ==>> .EVAL(PI("!",[Bool.t],Bool.t),[.VAL(true)])
        "!false" ==>> .EVAL(PI("!",[Bool.t],Bool.t),[.VAL(false)])
        "!x:B" ==>> .EVAL(PI("!",[Bool.t],Bool.t),[.VAR("x",Bool.t)])
        "!B(1.2)" ==>> .EVAL(PI("!",[Bool.t],Bool.t),[
            .EVAL(PI("B",[Float32.t],Bool.t),[.VAL(Float32(1.2))])
        ])
    }
    
    func test_binary_bool() throws {
        var ss = ["|","&","^","==","!="]
        // binary args
        for s in ss{
            try __bool_valued_binary_op__(s,Bool.t)
        }
        // float args
        ss = ["==","!=",">",">=","<","<="]
        for s in ss{
            try __bool_valued_binary_op__(s,Float32.t)
            try __bool_valued_binary_op__(s,String.t)
        }
    }
    
    func __bool_valued_binary_op__(_ op:String,_ args_type:T) throws {
        let _eval_ : ([Expr])->(Expr) = {
            return .EVAL(PI(op,[args_type,args_type],Bool.t),$0)
        }
        let es:[Expr] = [.VAR("a",args_type),.VAR("b",args_type)]
        if ["|","&","^"].contains(op){
            "a\(op)b" ==>> _eval_(es)
            "(a)\(op)b" ==>> _eval_(es)
            "(a)\(op)((b))" ==>> _eval_(es)
            "(a)\(op)b" ==>> _eval_(es)
            "a \(op) b" ==>> _eval_(es)
            "(a) \(op) b" ==>> _eval_(es)
            "(a) \(op) ((b))" ==>> _eval_(es)
            "(a) \(op) b" ==>> _eval_(es)
        }
        let t$ = args_type.s$
        "a:\(t$)\(op)b" ==>> _eval_(es)
        "a:\(t$)\(op)b:\(t$)" ==>> _eval_(es)
        "a\(op)b:\(t$)" ==>> _eval_(es)
        // with values...
        switch args_type{
        case .BOOL:
            "false\(op)b" ==>> _eval_([ .VAL(false),.VAR("b",Bool.t) ])
            "a\(op)true" ==>> _eval_([ .VAR("a",Bool.t),.VAL(true) ])
            "true\(op)false" ==>> _eval_([ .VAL(true),.VAL(false) ])
        case .FLOAT:
            let f = Expr.VAL(Float32(1.23))
            "1.23\(op)b" ==>> _eval_([ f,.VAR("b",Float32.t) ])
            "a\(op)1.23" ==>> _eval_([ .VAR("a",Float32.t),f ])
            "1.23\(op)1.23" ==>> _eval_([ f,f ])
        case .STRING:
            let s = Expr.VAL("hello")
            "\"hello\"\(op)b" ==>> _eval_([ s,.VAR("b",String.t) ])
            "a\(op)\"hello\"" ==>> _eval_([ .VAR("a",String.t),s ])
            "\"hello\"\(op)\"hello\"" ==>> _eval_([ s,s ])
        default: break
        }
    }
    
    // MARK: Data
    
    func test_data() throws{
        // vars
        "x:D" ==>> .VAR("x",Data.t)
        "(x:D)" ==>> .VAR("x",Data.t)
        "(((((((x:D)))))))" ==>> .VAR("x",Data.t)
        // STRUCTS
        let e:Expr = .EVAL(PI(".",[TEST_STRUCT,String.t],Data.t),[
            .VAR("x",TEST_STRUCT),.VAL("data")
        ])
        "(x:Test).data" ==>> e
    }
    
    // MARK: Float
    
    func test_atomic_float() throws {
        "1" ==>> .VAL(Float32(1))
        "12345.67890" ==>> .VAL(Float32(12345.67890))
        // parentheses
        "(12345.67890)" ==>> .VAL(Float32(12345.67890))
        "((((12345.67890))))" ==>> .VAL(Float32(12345.67890))
        // casts
        "F(true)" ==>> .EVAL(PI("F",[Bool.t],Float32.t),[.VAL(true)])
        "F(false)" ==>> .EVAL(PI("F",[Bool.t],Float32.t),[.VAL(false)])
        "F(12345.67890)" ==>> .EVAL(PI("F",[Float32.t],Float32.t),[.VAL(Float32(12345.67890))])
        "F(f:F)" ==>> .EVAL(PI("F",[Float32.t],Float32.t),[.VAR("f",Float32.t)])
        "F(\"123\")" ==>> .EVAL(PI("F",[String.t],Float32.t),[.VAL("123")])
        // array element
        var e:Expr = .EVAL(PI("°",[[Float32].t,Float32.t],Float32.t),[
            .EVAL(PI("[]",[],[Float32].t),[.VAL(Float32(1.2))]),.VAL(Float32(0))
        ])
        // ["₀","₁","₂","₃","₄","₅","₆","₇","₈","₉"]
        "[1.2]°0" ==>> e
        "[1.2]₀" ==>> e
        e = .EVAL(PI("°",[[Float32].t,Float32.t],Float32.t),[
            .EVAL(PI("[]",[],[Float32].t),[.VAL(Float32(1.2)),.VAL(Float32(3.4))]),.VAL(Float32(0))
        ])
        "[1.2,3.4]°0" ==>> e
        "[1.2,3.4]₀" ==>> e
        e = .EVAL(PI("°",[[Float32].t,Float32.t],Float32.t),[
            .EVAL(PI("[]",[],[Float32].t),[.VAL(Float32(1.2)),.VAL(Float32(3.4))]),.VAL(Float32(1))
        ])
        "[1.2,3.4]°1" ==>> e
        "[1.2,3.4]₁" ==>> e
        // STRUCTS
        e = .EVAL(PI(".",[TEST_STRUCT,String.t],Float32.t),[
            .VAR("x",TEST_STRUCT),.VAL("float")
        ])
        "(x:Test).float" ==>> e
    }
    
    func test_unary_float() throws {
        let f:(String,Expr)->(Expr) = {
            return .EVAL(PI($0,[Float32.t],Float32.t),[$1])
        }
        var a:Expr = .VAL(Float32(1.2))
        "-1.2" ==>> f("-",a)
        a = .VAR("f",Float32.t)
        "-f:F" ==>> f("-",a)
        "-f" ==>> f("-",a)
        "-(f)" ==>> f("-",a)
        for s in ["abs","ceil","floor","round",
                  "cos","sin","tan","acos","asin","atan",
                  "ln","exp","sqrt"]{
            "\(s)(f)" ==>> f(s,a)
        }
    }
    
    let _infix_floats_ = ["+","-","*","/"]
    func test_binary_float() throws {
        for s in _infix_floats_+["atan","min","max","pow"]{
            try __float_valued_binary_op__(s)
        }
    }
    
    func __float_valued_binary_op__(_ op:String) throws {
        let _eval_ : ([Expr])->(Expr) = {
            return .EVAL(PI(op,[Float32.t,Float32.t],Float32.t),$0)
        }
        let es:[Expr] = [.VAR("a",Float32.t),.VAR("b",Float32.t)]
        let f$ = "1.23"
        let f = Expr.VAL(Float32(1.23))
        if _infix_floats_.contains(op){ // INFIX
            "a\(op)b" ==>> _eval_(es)
            "(a)\(op)b" ==>> _eval_(es)
            "(a)\(op)((b))" ==>> _eval_(es)
            "(a)\(op)b" ==>> _eval_(es)
            let t$ = Float32.t.s$
            "a:\(t$)\(op)b" ==>> _eval_(es)
            "a:\(t$)\(op)b:\(t$)" ==>> _eval_(es)
            "a\(op)b:\(t$)" ==>> _eval_(es)
            // with values...
            "\(f$)\(op)b" ==>> _eval_([ f,.VAR("b",Float32.t) ])
            "a\(op)\(f$)" ==>> _eval_([ .VAR("a",Float32.t),f ])
            "\(f$)\(op)\(f$)" ==>> _eval_([ f,f ])
        }
        "\(op)(\(f$),\(f$))" ==>> _eval_([ f,f ])
        "\(op)(a,b)" ==>> _eval_(es)
    }
    
    func test_ternary_float() throws {
        for s in ["clamp"]{
            try __float_valued_ternary_op__(s,Float32.t)
        }
    }
    
    func __float_valued_ternary_op__(_ op:String,_ args_type:T) throws {
        let _eval_ : ([Expr])->(Expr) = {
            return .EVAL(PI(op,[args_type,args_type,args_type],Float32.t),$0)
        }
        let es:[Expr] = [.VAR("a",args_type),.VAR("b",args_type),.VAR("c",args_type)]
        let f$ = "1.23"
        let f = Expr.VAL(Float32(1.23))
        "\(op)(\(f$),\(f$),\(f$))" ==>> _eval_([f,f,f])
        "\(op)(a,b,c)" ==>> _eval_(es)
    }
    
    // MARK: String
    
    func test_atomic_string() throws {
        "\"hello\"" ==>> .VAL("hello")
        // parentheses
        "(\"hello\")" ==>> .VAL("hello")
        // casts
        "S(true)" ==>> .EVAL(PI("S",[Bool.t],String.t),[.VAL(true)])
        "S(false)" ==>> .EVAL(PI("S",[Bool.t],String.t),[.VAL(false)])
        "S(12345.67890)" ==>> .EVAL(PI("S",[Float32.t],String.t),[.VAL(Float32(12345.67890))])
        "S(f:F)" ==>> .EVAL(PI("S",[Float32.t],String.t),[.VAR("f",Float32.t)])
        "S(\"123\")" ==>> .EVAL(PI("S",[String.t],String.t),[.VAL("123")])
        // array element
        var e:Expr = .EVAL(PI("°",[[String].t,Float32.t],String.t),[
            .EVAL(PI("[]",[],[String].t),[.VAL("a")]),.VAL(Float32(0))
        ])
        // ["₀","₁","₂","₃","₄","₅","₆","₇","₈","₉"]
        "[\"a\"]°0" ==>> e
        "[\"a\"]₀" ==>> e
        e = .EVAL(PI("°",[[String].t,Float32.t],String.t),[
            .EVAL(PI("[]",[],[String].t),[.VAL("a"),.VAL("b")]),.VAL(Float32(0))
        ])
        "[\"a\",\"b\"]°0" ==>> e
        "[\"a\",\"b\"]₀" ==>> e
        e = .EVAL(PI("°",[[String].t,Float32.t],String.t),[
            .EVAL(PI("[]",[],[String].t),[.VAL("a"),.VAL("b")]),.VAL(Float32(1))
        ])
        "[\"a\",\"b\"]°1" ==>> e
        "[\"a\",\"b\"]₁" ==>> e
        // STRUCTS
        e = .EVAL(PI(".",[TEST_STRUCT,String.t],String.t),[
            .VAR("x",TEST_STRUCT),.VAL("string")
        ])
        "(x:Test).string" ==>> e
    }
    
    func test_unary_string() throws {
        let f:(String,Expr)->(Expr) = {
            return .EVAL(PI($0,[String.t],String.t),[$1])
        }
        let a:Expr = .VAR("s",String.t)
        for s in ["lower","upper"]{
            "\(s)(s)" ==>> f(s,a)
        }
    }
    
    let _infix_strings_ = ["#"] // = infix version of concat
    func test_binary_string() throws {
        for s in _infix_strings_+["concat","split"]{
            try __string_valued_binary_op__(s)
        }
    }
    
    func __string_valued_binary_op__(_ op:String) throws {
        let res_type : T = op == "split" ? [String].t : String.t
        let _eval_ : ([Expr])->(Expr) = {
            return .EVAL(PI(op,[String.t,String.t],res_type),$0)
        }
        let es:[Expr] = [.VAR("a",String.t),.VAR("b",String.t)]
        let s$ = "\"hello\""
        let s = Expr.VAL("hello")
        if _infix_strings_.contains(op){ // INFIX
            "a\(op)b" ==>> _eval_(es)
            "(a)\(op)b" ==>> _eval_(es)
            "(a)\(op)((b))" ==>> _eval_(es)
            "(a)\(op)b" ==>> _eval_(es)
            let t$ = String.t.s$
            "a:\(t$)\(op)b" ==>> _eval_(es)
            "a:\(t$)\(op)b:\(t$)" ==>> _eval_(es)
            "a\(op)b:\(t$)" ==>> _eval_(es)
            // with values...
            "\(s$)\(op)b" ==>> _eval_([ s,.VAR("b",String.t) ])
            "a\(op)\(s$)" ==>> _eval_([ .VAR("a",String.t),s ])
            "\(s$)\(op)\(s$)" ==>> _eval_([s,s])
        }
        "\(op)(\(s$),\(s$))" ==>> _eval_([s,s])
        "\(op)(a,b)" ==>> _eval_(es)
    }
    
    // MARK: typed variables
    
    func test_typed_vars() throws {
        "x:B" ==>> .VAR("x",Bool.t)
        "x:[B]" ==>> .VAR("x",.ARRAY(Bool.t))
        "x:F" ==>> .VAR("x",Float32.t)
        "x:[F]" ==>> .VAR("x",.ARRAY(Float32.t))
        "x:S" ==>> .VAR("x",String.t)
        "x:[S]" ==>> .VAR("x",.ARRAY(String.t))
        "x:D" ==>> .VAR("x",Data.t)
        "x:[D]" ==>> .VAR("x",.ARRAY(Data.t)) // not allowed , but it parses :)
        "x:Date" ==>> .VAR("x",DATE)
        "(x:Date)" ==>> .VAR("x",DATE)
        "x:[Date]" ==>> .VAR("x",.ARRAY(DATE))
    }
    
    // MARK: OP precedence
    func test_op_precence()throws{
        try  ____op_prec____("-1","-(1.0)")
        try  ____op_prec____("-1.234","-(1.234)")
        try  ____op_prec____("!a","!(a:B)")
        try  ____op_prec____("1 + 2","+(1.0,2.0)")
        try  ____op_prec____("2 - 2","-(2.0,2.0)")
        try  ____op_prec____("1 + 2 * 3","+(1.0,*(2.0,3.0))")
        try  ____op_prec____("(1 + 2) * 3","*(+(1.0,2.0),3.0)")
        try  ____op_prec____("-(1 + 2) * 3","*(-(+(1.0,2.0)),3.0)")
    }
    
    func ____op_prec____(_ sin:String,_ sout:String)throws{
        if let t = try Parser.parse(expr:sin){
            XCTAssert(t.s == sout,"t.s = \(t.s), sout = \(sout)")
        }else{
            __TLOG__(">> nil")
            __TLOG__("expected = \(sout)")
            XCTFail()
        }
    }
    
    // MARK: Arrays
    
    func test_arrays()throws{
        try ____arrays____("[true]","[true]")
        try ____arrays____("[true,false]","[true,false]")
        try ____arrays____("[1]","[1.0]")
        try ____arrays____("[1,2,3,4]","[1.0,2.0,3.0,4.0]")
        try ____arrays____("[\"hello\"]","[\"hello\"]")
        try ____arrays____("[\"a\",\"b\",\"c\",\"d\",\"e\"]","[\"a\",\"b\",\"c\",\"d\",\"e\"]")
        try ____arrays____("[x:B]","[x:B]")
        try ____arrays____("[x:B,y]","[x:B,y:B]")
        try ____arrays____("[x:B,y,z,a,b,c]","[x:B,y:B,z:B,a:B,b:B,c:B]")
        // parentheses
        try ____arrays____("([true])","[true]")
        try ____arrays____("((((([true])))))","[true]")
        try ____arrays____("((((([1,2,3,4])))))","[1.0,2.0,3.0,4.0]")
        // struct ivar
        let e:Expr = .EVAL(PI(".",[TEST_STRUCT,String.t],[Bool].t),[
            .VAR("x",TEST_STRUCT),.VAL("array")
        ])
        "(x:Test).array" ==>> e
    }
    
    func ____arrays____(_ sin:String,_ sout:String)throws{
        if let t = try Parser.parse(expr:sin){
            XCTAssert(t.s == sout,"t.s = \(t.s), sout = \(sout)")
        }else{
            __TLOG__(">> nil")
            __TLOG__("expected = \(sout)")
            XCTFail()
        }
    }
    
    func test_array_element_access()throws{
        "[1]" ==>> Expr.EVAL(PI("[]",[],[Float32].t),[.VAL(Float32(1.0))])
        "[1]°0" ==>> Expr.EVAL(PI("°",[[Float32].t,Float32.t],Float32.t),[
            Expr.EVAL(PI("[]",[],[Float32].t),[.VAL(Float32(1.0))]),
            .VAL(Float32(0.0))
        ])
        "[1,2,3]°0" ==>> Expr.EVAL(PI("°",[[Float32].t,Float32.t],Float32.t),[
            Expr.EVAL(PI("[]",[],[Float32].t),[
                .VAL(Float32(1.0)),
                .VAL(Float32(2.0)),
                .VAL(Float32(3.0))
            ]),
            .VAL(Float32(0.0))
        ])
        let e = Expr.EVAL(PI("°",[[Float32].t,Float32.t],Float32.t),[
            Expr.EVAL(PI("[]",[],[Float32].t),[
                .VAL(Float32(1.0)),
                .VAL(Float32(2.0)),
                .VAL(Float32(3.0))
            ]),
            .VAL(Float32(1.0))
        ])
        "[1.0,2.0,3.0]°1" ==>> e
        // check the result ...
        var vs = [String:any Event.Value]()
        let v = e.evaluate(&vs)
        if let v = e.evaluate(&vs).first as? (any Event.Value){
            XCTAssert(v.equals(Float32(2.0)))
        }else{ XCTFail() }
    }
    
    func test_arrays_of_struct()throws{
        "[X{x=1.2}]°0" ==>> Expr.EVAL(PI("°",[.ARRAY(X_TEST_STRUCT),Float32.t],X_TEST_STRUCT),[
            Expr.EVAL(PI("[]",[],.ARRAY(X_TEST_STRUCT)),[
                .VAL(Struct("X",["x":Float32(1.2)]))
            ]),
            .VAL(Float32(0.0))
        ])
        let e = Expr.EVAL(PI("°",[.ARRAY(X_TEST_STRUCT),Float32.t],X_TEST_STRUCT),[
            Expr.EVAL(PI("[]",[],.ARRAY(X_TEST_STRUCT)),[
                .VAL(Struct("X",["x":Float32(1.2)])),
                .VAL(Struct("X",["x":Float32(2.4)]))
            ]),
            .VAL(Float32(1.0))
        ])
        "[X{x=1.2},X{x=2.4}]°1" ==>> e
        var vs = [String:any Event.Value]()
        if let v = e.evaluate(&vs).first as? (any Event.Value){
            __TLOG__("v.t = \(v.t)")
            XCTAssert(v.t == X_TEST_STRUCT)
            if let v = v as? Struct{
                if let v = v["x"] as? Float32{
                    XCTAssert(v == Float32(2.4))
                }else{ XCTFail() }
            }else{ XCTFail() }
        }else{ XCTFail() }
    }
    
    // MARK: struct instances
    
    func test_struct_instances() throws {
        var e:Expr = .EVAL(
            PI(".",[DATE,String.t],Float32.t),
            [.VAR("x",DATE),.VAL("hour")]
            )
        "(x:Date).hour" ==>> e
        "( (x:Date).hour )" ==>> e
        // same but with variable name for ivar_name -> is this valid??
        e = .EVAL(
            PI(".",[DATE,String.t],.UNKNOWN),
            [.VAR("x",DATE),.VAL("y")]
            )
        "(x:Date).y" ==>> e
        "x:Date;x.sec" ==>> .LIST([
            .VAR("x",DATE),
            .EVAL(
                PI(".",[DATE,String.t],Float32.t),
                [.VAR("x",DATE),.VAL("sec")]
                )
            ])
        "x:Date;x.sec;x.hour" ==>> .LIST([
            .VAR("x",DATE),
            .EVAL(
                PI(".",[DATE,String.t],Float32.t),
                [.VAR("x",DATE),.VAL("sec")]
                ),
            .EVAL(
                PI(".",[DATE,String.t],Float32.t),
                [.VAR("x",DATE),.VAL("hour")]
                )
        ])
        // struct ivar
        e = .EVAL(PI(".",[TEST_STRUCT,String.t],XY),[
            .VAR("x",TEST_STRUCT),.VAL("struct")
        ])
        "(x:Test).struct" ==>> e
        "(((( (x:Test).struct ))))" ==>> e
        "(((((((((x:Test).struct))))))))" ==>> e
    }
    
    func test_struct_instance____() throws {
        "X{ x=1.2 }" ==>> .VAL(Struct("X",["x":Float32(1.2)]))
    }
    
    func test_struct_instance2() throws {
        "Empty{}" ==>> .VAL(Struct("Empty"))
        "X{ x=1.2 }" ==>> .VAL(Struct("X",["x":Float32(1.2)]))
        "XY{ x=1.2, y=3.4 }" ==>> .VAL(
            Struct("XY",[
                "x":Float32(1.2),
                "y":Float32(3.4)
            ])
        )
        "(q:XY).x" ==>> .EVAL(PI(".",[XY,String.t],Float32.t),[
            .VAR("q",XY),.VAL("x")
        ])
    }
    
    func test_struct_round_trip() throws {
        let s = "(XY{ x=1.2, y=3.4 }).x"
        do{
            if let expr = try Parser.parse(expr:s){
                __TLOG__(expr.description)
                var vs = [String : any Event.Value]()
                let res = expr.evaluate(&vs)
                XCTAssert(res.count == 1)
                if let v = res[0] as? Float32{
                    XCTAssert(v == 1.2)
                }else{ XCTFail() }
            }
        }catch{ XCTFail() }
    }
    
    // MARK: Errors
    
    func test_Error() throws {
        //"wacky)" ==>> Err.UNKNOWN_IDENTIFIER()
        //"abs)" ==>> Err.EXPECTED(.PUNC(.ROUND_L),nil)
    }
    
    func test_Errors() throws {
        //")" ==>> Err.UNEXPECTED_PUNCTUATION()
    }
    
}

fileprivate func ==>>(_ s:String, _ e:Err){
    do{
        _ = try Parser.parse(expr:s)
        XCTFail("expected \(e.localizedDescription)")
    }catch let _e{
        __TLOG__("expected Error: \(e.localizedDescription)")
        __TLOG__("found \(_e.localizedDescription)")
        XCTAssert(e == (_e as? Err))
    }
}
fileprivate func ==>>(_ s:String, _ e:Expr){
    do{
        if let x = try Parser.parse(expr:s){
            if x != e{
                XCTFail("found = \(x.description), expected = \(e.description)")
            }else{
                __TLOG__("⬛︎ \(x.description)")
            }
        }else{
            XCTFail("parser returned nil")
        }
    }catch let e{
        XCTFail("\(e)")
    }
}
