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

private typealias Err = Parser.Err
let MAKE_STRUCT_OP = "§"
let IVAR_ACCESS = "."
let ARRAY_OP = "[]"
let ARRAY_INDEX = "°"

/*
 A Term is a node in the Abstract Syntax Tree
 */
struct Term{
    
    let tok:Tok
    let args:[Term]
    
    init(_ t:Tok,_ a:[Term]){ tok = t; args = a }
    
    func expr()throws->Expr{
        var vars = [String:Expr]()
        return try expr(&vars)
    }
    
    func expr(_ vars:inout[String:Expr])throws->Expr{
        switch tok{
        case .VAR(let s,let t1):
            var v = vars[s]
            if case .VAR(_,let t2) = v{
                if t1 == .UNKNOWN{ return v! }
                if t2 != .UNKNOWN, t1 != t2{
                    throw Parser.Err.CONFLICT(.TYPE)
                }
            }
            v = .VAR(s,t1)
            vars[s] = v
            return v!
        case .VAL(let v): return .VAL(v)
        case .PUNC(.SQUARE_L):
            var es = try args.map{ try $0.expr(&vars) }
            var type = T.UNKNOWN
            for e in es{
                var __t__ = T.UNKNOWN
                switch e{
                case .LIST(_): fatalError()
                case .EVAL(let pi,_): __t__ = pi.out
                case .VAL(let v): __t__ = v.t
                case .VAR(_,let t): __t__ = t
                }
                if type == .UNKNOWN{ type = __t__ }
                else if __t__ != .UNKNOWN, type != __t__{ throw Err.CONFLICT(.TYPE) }
            }
            if type == .UNKNOWN{ throw Err.UNKNOWN(.TYPE)}
            for i in 0..<es.count{
                if case .VAR(let s,_) = es[i]{ es[i] = .VAR(s,type) }
            }
            return try __MAKE_EVALUATOR__(ARRAY_OP,&es,tok)
        case .ID(let s):
            return .VAL(s)
        case .OP(let s):
            if s == ";"{
                return .LIST(try args.map{ try $0.expr(&vars) })
            }else if !args.isEmpty{
                var es = try args.map{ try $0.expr(&vars) }
                return try __MAKE_EVALUATOR__(s,&es,tok)
            }
            __log__.debug("TODO: expr for OP term \(s)")
            fallthrough
        case .STRUCT(let s):
            if let struct_type = Struct.type(named:s),
               case T.STRUCT(_,let ivar_types) = struct_type{
                var _args = [Expr]()
                for a in args{
                    var lhs : Expr?
                    var rhs : Expr?
                    switch a.tok{
                    case .VAR(let v$,_):
                        lhs = .VAL(v$)
                        rhs = try a.expr(&vars)
                    case .OP(let v$):
                        if v$ == "=", a.args.count == 2{
                            lhs = try a.args[0].expr(&vars)
                            rhs = try a.args[1].expr(&vars)
                        }else{ throw Err.UNEXPECTED(.EXPR) }
                    default: throw Err.UNEXPECTED(.EXPR)
                    }
                    if case .VAL(let s) = lhs,
                        var rhs = rhs,
                        let s = s as? String,
                        let vt = ivar_types[s]{
                        switch rhs{
                        case .VAL(let x):
                            if x.t != vt{ throw Err.UNEXPECTED(.EXPR) }
                        case .VAR(let x,let y):
                            if y == .UNKNOWN{ rhs = .VAR(x,vt) }
                            else if y != vt{ throw Err.UNEXPECTED(.EXPR) }
                        default:
                            __log__.debug("TODO: check type of non-var ivar values")
                        }
                        _args.append(.LIST([lhs!,rhs]))
                    }else{ throw Err.UNEXPECTED(.EXPR) }
                }
                return Expr.EVAL(PI(MAKE_STRUCT_OP+s,[.UNKNOWN],struct_type),_args)
            }else{ throw Err.UNEXPECTED(.EXPR) }
        default:
            __log__.debug("FAILED @ \(s)")
            throw Err.UNEXPECTED(.TOKENS)
        }
    }
    
    var s:String{
        var s = tok.description
        if !args.isEmpty{
            s += "("
            for i in 0..<args.count{
                if i > 0{ s += "," }
                s += args[i].s
            }
            s += ")"
        }
        return s
    }
    
}

private func __MAKE_EVALUATOR__(_ q:String,_ es:inout [Expr],_ tk:Tok?)throws->Expr{
    //__log__.debug("__MAKE_EVALUATOR__ \(q) # \(es.count)")
    var err:Err?
    if let e = PI.resolve(q,&es,tk,{ _,_,_ in err = Err.UNEXPECTED(.ARGS) }){
        if let err = err{ throw err }
        if q == IVAR_ACCESS,case .EVAL(let pi,let args) = e.0,args.count == 2{
            if case .VAL(let x) = args[0],
               let x = x as? Struct,
               case .STRUCT(_,let ts) = x.t{
                var ivar_name : String?
                switch args[1]{
                case .VAL(let v): if let v = v as? String{ ivar_name = v }
                case .VAR(let v,_): ivar_name = v
                default: break
                }
                if let n = ivar_name, let t = ts[n]{
                    return .EVAL(PI(pi.name,pi.ins,t),args)
                }
            }
        }
        return e.0
    }else{
        var s = "can't resolve PI: \(q)/\(es.count):)"
        for e in es{ s += "\n    " + e.description }
        __log__.debug(s)
    }
    throw Err.EXPECTED(.OPERATOR)
}
