/*
 𝗙𝗟𝗢 : 𝗗𝗶𝘀𝘁𝗿𝗶𝗯𝘂𝘁𝗲𝗱 𝗛𝗶𝗲𝗿𝗮𝗿𝗰𝗵𝗶𝗰𝗮𝗹 𝗗𝗮𝘁𝗮𝗳𝗹𝗼𝘄
 MIT License

 Copyright (c) 2025 kk-0129

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 */
import Foundation
import FloBox


// MARK: ► Exe
public typealias Exe = ([(any Event.Value)?])->((any Event.Value)?)

// MARK: ► PI = Predicate Indicator
public struct PI:IO™,Hashable{
    
    public let name:String
    public let ins:[T]
    public let out:T
    
    // MARK: init
    public init(_ n:String,_ i:[T],_ o:T){ name = n; ins = i; out = o }
    
    public var signature:String{
        return "\"\(name)\"(\(ins.map{$0.s$}.joined(separator:",")))->\(out.s$)"
    }
    
    // MARK: IO™
    public func ™(_ Ω:IO){
        name.™(Ω)
        ins.™(Ω)
        out.™(Ω)
    }
    public static func ™(_ Ω:IO)throws->PI{
        return PI( try String.™(Ω),try [T].™(Ω), try T.™(Ω) )
    }
    
    // MARK: matches
    // a = PI.ins types, b = supplied arguments
    public static func matches(_ a:[T],_ b:inout [Expr])->Bool{
        let n = a.count
        if b.count == n{
            for i in 0..<n{
                let t = b[i].t
                if a[i] != t && t != T.UNKNOWN{ return false }
            }
        }
        return true
    }
    
    public func hash(into h: inout Hasher){
        h.combine(name)
        h.combine(ins)
        h.combine(out)
    }
    public static func ==(a:PI,b:PI)->Bool{
        return a.out == b.out
        && a.ins == b.ins
        && a.name == b.name
    }
    
    // MARK: resolve
    
    // USED BY Term.__MAKE_EVALUATOR__
    static func resolve(_ pi_name:String,_ exprs:inout [Expr],_ tk:Any?,_ err:(T,Int,T)->())->(Expr,[PI])?{
        let n = pi_name == ARRAY_OP ? 0 : exprs.count
        if let candidates:[PI] = pi_exes(named:pi_name,arity:n){
            let m = candidates.count
            //__log__.debug("found \(m) candidate\(m == 1 ? "" : "s") for \(pi_name)/\(exprs.count)...")
            let expr_types = exprs.map{$0.t}
            var exprs = exprs
            switch m{
            case 0:
                break//fatalError()
            case 1:
                var pi = candidates.first!
                if n > 0{
                    if let (a,i,b) = expr_types.first(mismatch:pi.ins){
                        //__log__.debug("mismatch @ \(i), t = \(a.s$), q = \(b.s$) ")
                        err(a,i,b)
                        return nil
                    }
                    pi = __resolve_var_types__(&exprs,pi)
                }
                return (.EVAL(pi,exprs),candidates) // THE IDEAL CASE :)
            default:
                if n == 0{
                    switch pi_name{
                    case ARRAY_OP:
                        if expr_types.isEmpty{ fatalError() }
                        //let array_type = ts.isEmpty ? T.NONE : T.ARRAY(ts[0])
                        let e_type = expr_types[0]
                        let array_type = T.ARRAY(e_type)
                        if case .STRUCT(_,_) = e_type{
                            if candidates.first(where:{ $0.out == .ARRAY(.UNKNOWN) }) != nil{
                                let pi = PI(ARRAY_OP,[],.ARRAY(e_type))
                                return (.EVAL(pi,exprs),[pi])
                            }
                        }else if let pi = candidates.first(where:{ $0.out ==  array_type }){
                            return (.EVAL(pi,exprs),[pi])
                        }
                    default: fatalError() // any others with no args?
                    }
                }else if pi_name == "°",exprs.count == 2,
                         case .ARRAY(let t) = exprs[0].t{
                    // special case for .ARRAY(.STRUCT))
                    var pi = PI("°",[.ARRAY(t),ᵀF],t)
                    __log__.debug("special :: \(pi.signature)")
                    pi = __resolve_var_types__(&exprs,pi)
                    return (.EVAL(pi,exprs),[pi])
                }else{
                    var matched_candidates = [PI]()
                    for pi in candidates{
                        if PI.matches(pi.ins,&exprs){
                            matched_candidates.append(pi)
                        }
                    }
                    if !matched_candidates.isEmpty{
                        if matched_candidates.count == 1{
                            var pi = matched_candidates.first!
                            pi = __resolve_var_types__(&exprs,pi)
                            return (.EVAL(pi,exprs),matched_candidates)
                        }
                        return (.EVAL(PI(pi_name,expr_types,T.UNKNOWN),exprs),matched_candidates)
                    }else{
                        __log__.debug("----- no matches")
                    }
                }
            }
        }
        return nil
    }
    
    private static func __resolve_var_types__(_ es:inout[Expr],_ pi:PI)->PI{
        var ins = pi.ins
        var out = pi.out
        for i in 0..<es.count{
            switch es[i]{
            case .VAR(let s,let t):
                if t == .UNKNOWN{ es[i] = .VAR(s,ins[i]) }
                else if ins[i] == .UNKNOWN{ ins[i] = t }
                else if t != ins[i]{ fatalError() }
            case .VAL(let v):
                if ins[i] == .UNKNOWN{ ins[i] = v.t }
                else if v.t != ins[i]{ fatalError() }
            default: break
            }
        }
        if out == .UNKNOWN,
           pi.name == ".",
           pi.ins.count == 2,
           case .VAR(_,let t1) = es[0],   // 1st arg is a variable
           case .STRUCT(_,let ivars) = t1,// .. with a STRUCT type
           case .VAL(let ivar) = es[1],   // 2nd arg is name of a struct ivar
           let v = ivar as? String,       // check it's a string
           let t = ivars[v]{              // get it's type ...
            out = t
        }
        return PI(pi.name,ins,out)
    }
    
    public var exe:Exe?{
        // special cases ..
        switch name{
        case IVAR_ACCESS: if ins.count == 2{ return struct_ivar_accessor }
        //case MAKE_STRUCT_OP: if ins.count == 2{ return struct_constructor }
        case ARRAY_INDEX: if ins.count == 2, case .STRUCT = out{
            return array_element_accessor
        }
        case ARRAY_OP: if case .ARRAY(let t) = out,case .STRUCT = t{
            return array_constructor
        }
        default: break
        }
        return ____builtin_pis____[name]?[ins.count]?[self]
    }
    
}

func pi_exes(named:String,arity:Int)->[PI]?{
    if let x = ____builtin_pis____[named]?[arity]{return [PI](x.keys) }
    return [PI]()
}

//MARK: special exes ..
func struct_ivar_accessor(_ args:[(any Event.Value)?])->(any Event.Value)?{
    if args.count == 2{
        if let key = args[1] as? String{
            if let array = args[0] as? [Struct]{
                var fs = [Float32]()
                for s in array{
                    if let f = s[key] as? Float32{ fs.append(f) }
                }
                return fs
            }else if let s = args[0] as? Struct{
                //if case .STRUCT(let name,_) = s.t {
                //    __log__.info("ivar \(name).\(v) -> \(s[v])")
                //}
                return s[key]
            }
        }
    }
    return nil
}

func struct_constructor(_ s:String,_ vs:inout[String:any Event.Value],_ es:inout[Expr])->Struct?{
    if let t = Struct.type(named:s), case .STRUCT(_,let types) = t{
        var known_values = [String:any Event.Value]()
        for e in es{
            switch e{
            case .LIST(let xs):
                if xs.count == 2, 
                    case .VAL(let v) = xs[0],
                    let v$ = v as? String,
                    let vt = types[v$]{
                    let res = xs[1].evaluate(&vs)
                    if res.count == 1, let v = res[0], v.t == vt{
                        known_values[v$] = v
                    }else{ fallthrough }
                }else{ fallthrough }
            default: return nil
            }
        }
        return t.instance(known_values)
    }
    return nil
}

func array_element_accessor(_ args:[(any Event.Value)?])->(any Event.Value)?{
    if args.count == 2,
       let array = args[0] as? [(any Event.Value)],
        let idx = args[1] as? Float32{
        let i = Int(idx)
        if i >= 0 && i < array.count{
            return array[i]
        }
    }
    return nil
}

func array_constructor(_ vs:[(any Event.Value)?])->(any Event.Value)?{
    var res = [any Event.Value]()
    var t:T?
    for v in vs{
        if let v = v{
            if t == nil{ t = v.t }
            if v.t == t{ res.append(v); continue }
        }
        return nil
    }
    switch (t ?? Bool.t){
    case .UNKNOWN: fatalError()
    case .BOOL: return res as! [Bool]
    case .DATA: fatalError()
    case .FLOAT: return res as! [Float32]
    case .STRING: return res as! [String]
    case .ARRAY: fatalError()
    case .STRUCT: return res as! [Struct]
    }
}

func xy_extractor(_ vs:[(any Event.Value)?])->(any Event.Value)?{
    var res = [any Event.Value]()
    var t:T?
    for v in vs{
        if let v = v{
            if t == nil{ t = v.t }
            if v.t == t{ res.append(v); continue }
        }
        return nil
    }
    switch (t ?? Bool.t){
    case .UNKNOWN: fatalError()
    case .BOOL: return res as! [Bool]
    case .DATA: fatalError()
    case .FLOAT: return res as! [Float32]
    case .STRING: return res as! [String]
    case .ARRAY: fatalError()
    case .STRUCT: return res as! [Struct]
    }
}

let ᵀB = Bool.t
let ᵀF = Float32.t
let ᵀS = String.t
let ᵀD = Data.t

//MARK: built-ins ..
let ____builtin_pis____ : [String:[Int:[PI:Exe]]] = [
    
    // Struct
    // ivar access
    IVAR_ACCESS : [ 2 :[
        //              (struct)(ivar name)->(ivar value)
        PI(IVAR_ACCESS,[.UNKNOWN,ᵀS],.UNKNOWN) : struct_ivar_accessor
    ] ],
    // constructor
    //MAKE_STRUCT_OP : [ 2 :[
    //    //              (struct_name)(known_ivar_values)->(struct)
    //    PI(MAKE_STRUCT_OP,[ᵀS,.UNKNOWN],.UNKNOWN) : struct_constructor
    //] ],
    
    // Arrays
    ARRAY_OP : [ 0 :[
        PI(ARRAY_OP,[],.ARRAY(ᵀB)) : { array_constructor($0) },
        PI(ARRAY_OP,[],.ARRAY(ᵀF)) : { array_constructor($0) },
        PI(ARRAY_OP,[],.ARRAY(ᵀS)) : { array_constructor($0) },
        PI(ARRAY_OP,[],.ARRAY(.UNKNOWN)) : { array_constructor($0) }
    ] ],
    
    // Array indices
    ARRAY_INDEX : [ 2 :[
        PI(ARRAY_INDEX,[.ARRAY(ᵀB),ᵀF],ᵀB) : __ƒBsF__{ item(in:$0,at:$1) },
        PI(ARRAY_INDEX,[.ARRAY(ᵀF),ᵀF],ᵀF) : __ƒFsF__{ item(in:$0,at:$1) },
        PI(ARRAY_INDEX,[.ARRAY(ᵀS),ᵀF],ᵀS) : __ƒSsF__{ item(in:$0,at:$1) },
        PI(ARRAY_INDEX,[.ARRAY(.UNKNOWN),ᵀF],.UNKNOWN) : array_element_accessor
    ] ],
    
    // casts
    "B" : [ 1 : [
        PI("B",[ᵀB],ᵀB) : __ƒB__{ $0 },
        PI("B",[ᵀF],ᵀB) : __ƒF__{ $0 > 0 },
        PI("B",[ᵀS],ᵀB) : __ƒS__{ $0 == "true" }
    ] ],
    "F" : [ 1 : [
        PI("F",[ᵀB],ᵀF) : __ƒB__{ $0 ? Float32(1) : Float32(0) },
        PI("F",[ᵀF],ᵀF) : __ƒF__{ $0 },
        PI("F",[ᵀS],ᵀF) : __ƒS__{ Float32($0) }
    ] ],
    "S" : [ 1 : [
        PI("S",[ᵀB],ᵀS) : __ƒB__{ "\($0)" },
        PI("S",[ᵀF],ᵀS) : __ƒF__{ "\($0)" },
        PI("S",[ᵀS],ᵀS) : __ƒS__{ $0 },
        PI("S",[.ARRAY(ᵀB)],ᵀS) : __ƒBs__{ $0.s },
        PI("S",[.ARRAY(ᵀF)],ᵀS) : __ƒFs__{ $0.s },
        PI("S",[.ARRAY(ᵀS)],ᵀS) : __ƒSs__{ $0.s },
        PI("S",[XY],ᵀS) : __ƒXY__{ "(\($0["x"]!.s),\($0["y"]!.s))" }
    ] ],
    
    // logical_op
    "!" : [ 1 : [ PI("!",[ᵀB],ᵀB) : __ƒB__{ !$0 } ] ],
    "|" : [ 2 : [ PI("|",[ᵀB,ᵀB],ᵀB) : __ƒBB__{ $0 || $1 } ] ],
    "&" : [ 2 : [ PI("&",[ᵀB,ᵀB],ᵀB) : __ƒBB__{ $0 && $1 } ] ],
    "^" : [ 2 : [ PI("^",[ᵀB,ᵀB],ᵀB) : __ƒBB__{ ($0 || $1) && !($0 && $1) } ] ],
    
    // equals_op
    "==" : [ 2 : [
        PI("==",[ᵀB,ᵀB],ᵀB) : __ƒBB__{ $0 == $1 },
        PI("==",[ᵀF,ᵀF],ᵀB) : __ƒFF__{ $0 == $1 },
        PI("==",[ᵀS,ᵀS],ᵀB) : __ƒSS__{ $0 == $1 }
    ] ],
    "!=" : [ 2 : [
        PI("!=",[ᵀB,ᵀB],ᵀB) : __ƒBB__{ $0 != $1 },
        PI("!=",[ᵀF,ᵀF],ᵀB) : __ƒFF__{ $0 != $1 },
        PI("!=",[ᵀS,ᵀS],ᵀB) : __ƒSS__{ $0 != $1 }
    ] ],
    
    // comp_op
    ">" : [ 2 : [
        PI(">",[ᵀF,ᵀF],ᵀB) : __ƒFF__{ $0 > $1 },
        PI(">",[ᵀS,ᵀS],ᵀB) : __ƒSS__{ $0 > $1 }
    ] ],
    ">=" : [ 2 : [
        PI(">=",[ᵀF,ᵀF],ᵀB) : __ƒFF__{ $0 >= $1 },
        PI(">=",[ᵀS,ᵀS],ᵀB) : __ƒSS__{ $0 >= $1 }
    ] ],
    "<" : [ 2 : [
        PI("<",[ᵀF,ᵀF],ᵀB) : __ƒFF__{ $0 < $1 },
        PI("<",[ᵀS,ᵀS],ᵀB) : __ƒSS__{ $0 < $1 }
    ] ],
    "<=" : [ 2 : [
        PI("<=",[ᵀF,ᵀF],ᵀB) : __ƒFF__{ $0 <= $1 },
        PI("<=",[ᵀS,ᵀS],ᵀB) : __ƒSS__{ $0 <= $1 }
    ] ],
    
    // float_op_1
    "nil" : [ 1 : [ PI("nil",[ᵀF],ᵀB) : { return $0.__1 == nil } ] ],
    "abs" : [ 1 : [ PI("abs",[ᵀF],ᵀF) : __ƒF__{ fabsf($0) } ] ],
    "ceil" : [ 1 : [ PI("ceil",[ᵀF],ᵀF) : __ƒF__{ ceilf($0) } ] ],
    "floor" : [ 1 : [ PI("floor",[ᵀF],ᵀF) : __ƒF__{ floorf($0) } ] ],
    "round" : [ 1 : [ PI("round",[ᵀF],ᵀF) : __ƒF__{ roundf($0) } ] ],
    "cos" : [ 1 : [ PI("cos",[ᵀF],ᵀF) : __ƒF__{ cosf($0) } ] ],
    "sin" : [ 1 : [ PI("sin",[ᵀF],ᵀF) : __ƒF__{ sinf($0) } ] ],
    "tan" : [ 1 : [ PI("tan",[ᵀF],ᵀF) : __ƒF__{ tanf($0) } ] ],
    "acos" : [ 1 : [ PI("acos",[ᵀF],ᵀF) : __ƒF__{ acosf($0) } ] ],
    "asin" : [ 1 : [ PI("asin",[ᵀF],ᵀF) : __ƒF__{ asinf($0) } ] ],
    "atan" : [
        1 : [ PI("atan",[ᵀF],ᵀF) : __ƒF__{ atanf($0) } ],
        2 : [ PI("atan",[ᵀF,ᵀF],ᵀF) : __ƒFF__{ atan2f($0,$1) } ]
    ],
    "ln" : [ 1 : [ PI("ln",[ᵀF],ᵀF) : __ƒF__{ logf($0) } ] ],
    "exp" : [ 1 : [ PI("exp",[ᵀF],ᵀF) : __ƒF__{ expf($0) } ] ], // eᴷ
    "sqrt" : [ 1 : [ PI("sqrt",[ᵀF],ᵀF) : __ƒF__{ sqrtf($0) } ] ],
    
    // float_infix
    "+" : [ 2 : [ PI("+",[ᵀF,ᵀF],ᵀF) : __ƒFF__{ $0 + $1 } ] ],
    "-" : [
        1 : [ PI("-",[ᵀF],ᵀF) : __ƒF__{ -$0 } ],
        2 : [ PI("-",[ᵀF,ᵀF],ᵀF) : __ƒFF__{ $0 - $1 } ]
    ],
    "*" : [ 2 : [ PI("*",[ᵀF,ᵀF],ᵀF) : __ƒFF__{ $0 * $1 } ] ],
    "/" : [ 2 : [ PI("/",[ᵀF,ᵀF],ᵀF) : __ƒFF__{ $0 / $1 } ] ],
    
    // float_op_2
    "min" : [ 2 : [ PI("min",[ᵀF,ᵀF],ᵀF) : __ƒFF__{ fmin($0,$1) } ] ],
    "max" : [ 2 : [ PI("max",[ᵀF,ᵀF],ᵀF) : __ƒFF__{ fmax($0,$1) } ] ],
    "pow" : [ 2 : [ PI("pow",[ᵀF,ᵀF],ᵀF) : __ƒFF__{ powf($0,$1) } ] ],
    
    // float_op_3
    "clamp" : [ 3 : [ PI("clamp",[ᵀF,ᵀF,ᵀF],ᵀF) : __ƒFFF__{ $0.clip($1,$2) } ] ],
    
    // string_op_1
    "lower" : [ 1 : [ PI("lower",[ᵀS],ᵀS) : __ƒS__{ $0.lowercased() } ] ],
    "upper" : [ 1 : [ PI("upper",[ᵀS],ᵀS) : __ƒS__{ $0.uppercased() } ] ],
    
    // string_op_2
    "#" : [ 2 : [ PI("#",[ᵀS,ᵀS],ᵀS) : __ƒSS__{ $0 + $1 } ] ],
    "concat" : [ 2 : [ PI("concat",[ᵀS,ᵀS],ᵀS) : __ƒSS__{ $0 + $1 } ] ],
    "split" : [ 2 : [ PI("split",[ᵀS,ᵀS],.ARRAY(ᵀS)) : __ƒSS__{ $0.components(separatedBy:$1) } ] ],
    
    // data_op_1
    "xxx" : [ 1 : [ PI("xxx",[ᵀD],ᵀS) : __ƒD__{ "\($0.count) bytes" } ] ],
]
private func __ƒB__(_ cb:@escaping(Bool)->((any Event.Value)?))->Exe{
    return { if let a = $0.__1 as? (Bool){ return cb(a) }; return nil }
}
private func __ƒBs__(_ cb:@escaping([Bool])->((any Event.Value)?))->Exe{
    return { if let a = $0.__1 as? ([Bool]){ return cb(a) }; return nil }
}
private func __ƒBsF__(_ cb:@escaping([Bool],Float32)->((any Event.Value)?))->Exe{
    return { if let (a,b) = $0.__2 as? ([Bool],Float32){ return cb(a,b) }; return nil }
} 
private func __ƒBB__(_ cb:@escaping(Bool,Bool)->((any Event.Value)?))->Exe{
    return { if let (a,b) = $0.__2 as? (Bool,Bool){ return cb(a,b) }; return nil }
}
private func __ƒF__(_ cb:@escaping(Float32)->((any Event.Value)?))->Exe{
    return { if let a = $0.__1 as? Float32{ return cb(a) }; return nil }
}
private func __ƒFs__(_ cb:@escaping([Float32])->((any Event.Value)?))->Exe{
    return { if let a = $0.__1 as? [Float32]{ return cb(a) }; return nil }
}
private func __ƒFsF__(_ cb:@escaping([Float32],Float32)->((any Event.Value)?))->Exe{
    return { if let (a,b) = $0.__2 as? ([Float32],Float32){ return cb(a,b) }; return nil }
}
private func __ƒFF__(_ cb:@escaping(Float32,Float32)->((any Event.Value)?))->Exe{
    return { if let (a,b) = $0.__2 as? (Float32,Float32){ return cb(a,b) }; return nil }
}
private func __ƒFFF__(_ cb:@escaping(Float32,Float32,Float32)->((any Event.Value)?))->Exe{
    return { if let (a,b,c) = $0.__3 as? (Float32,Float32,Float32){ return cb(a,b,c) }; return nil }
}
private func __ƒS__(_ cb:@escaping(String)->((any Event.Value)?))->Exe{
    return { if let a = $0.__1 as? (String){ return cb(a) }; return nil }
}
private func __ƒSs__(_ cb:@escaping([String])->((any Event.Value)?))->Exe{
    return { if let a = $0.__1 as? ([String]){ return cb(a) }; return nil }
}
private func __ƒSsF__(_ cb:@escaping([String],Float32)->((any Event.Value)?))->Exe{
    return { if let (a,b) = $0.__2 as? ([String],Float32){ return cb(a,b) }; return nil }
}
private func __ƒSS__(_ cb:@escaping(String,String)->((any Event.Value)?))->Exe{
    return { if let (a,b) = $0.__2 as? (String,String){ return cb(a,b) }; return nil }
}
private func __ƒD__(_ cb:@escaping(Data)->((any Event.Value)?))->Exe{
    return {
        if let a = $0.__1 as? Data{ return cb(a) }
        __log__.warn("input was \($0)")
        return nil
    }
}
private func __ƒXY__(_ cb:@escaping(Struct)->((any Event.Value)?))->Exe{
    return { if let a = $0.__1 as? (Struct), a.isa(XY){ return cb(a) }; return nil }
}

private func item<W>(in a:[W],at f:Float32)->W?{
    return a.isEmpty ? nil : a[ min(max(0,Int(roundf(f))),a.count-1) ]
}

private extension Array where Element == (any Event.Value)?{
    var __1:(any Event.Value)?{ return count == 1 ? self[0] : nil }
    var __2:((any Event.Value)?,(any Event.Value)?)?{ return count == 2 ? (self[0],self[1]) : nil }
    var __3:((any Event.Value)?,(any Event.Value)?,(any Event.Value)?)?{ return count == 3 ? (self[0],self[1],self[2]) : nil }
    var __4:((any Event.Value)?,(any Event.Value)?,(any Event.Value)?,(any Event.Value)?)?{ return count == 4 ? (self[0],self[1],self[2],self[3]) : nil }
}

private extension Array where Element == T{
    func first(mismatch ts:[T])->(T,Int,T)?{
        if count == ts.count{
            for i in 0..<count{
                if self[i] == T.UNKNOWN || ts[i] == T.UNKNOWN{ /*ok */ }
                else if self[i] != ts[i]{ return (self[i],i,ts[i]) }
            }
        }
        return nil
    }
}
