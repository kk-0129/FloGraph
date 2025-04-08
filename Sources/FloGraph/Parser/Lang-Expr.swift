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

public struct ParsedExpr:IO™{
    public let text:String
    public let expr:Expr
    public init(_ t:String,_ e:Expr){ text = t; expr = e }
    public func ™(_ Ω:IO){ text.™(Ω); expr.™(Ω) } 
    public static func ™(_ Ω:IO)throws->ParsedExpr{
        return ParsedExpr(try String.™(Ω),try Expr.™(Ω))
    }
}

// MARK: ► Expr
public indirect enum Expr:IO™,Equatable{
    
    static func out$(_ i:Int)->String{ return "_\(i)" }
    
    case LIST([Expr])
    case EVAL(PI,[Expr])
    case VAL(any Event.Value)
    case VAR(String,T)
    
    var outs:Ports{
        var res = Ports()
        switch self{
        case .LIST(let es):
            for i in 0..<es.count{
                res[Expr.out$(i)] = es[i].t
            }
        default: res[Expr.out$(0)] = self.t
        }
        return res
    }
    
    public var vars:Ports{
        var vars = Ports() // types & tokens
        __vars__(&vars)
        return vars
    }
    
    private func __vars__( _ vars:inout Ports){
        switch self{
        case .LIST(let es): fallthrough
        case .EVAL(_,let es):
            for e in es{
                for (s,t) in e.vars{ vars[s] = t }
            }
        case .VAL(_): break
        case .VAR(let s,let t):
            vars[s] = t
        }
    }
    
    public var t:T{
        switch self{
        case .LIST: return .UNKNOWN
        case .EVAL(let q,_): return q.out
        case .VAL(let v): return v.t
        case .VAR(_,let t): return t
        }
    }
    
    public var s:String{
        switch self{
        case .EVAL: return __s__(true)
        default: return __s__(false)
        }
    }
    
    private func __s__(_ quoted:Bool)->String{
        switch self{
        case .LIST(let es): return es.map({$0.__s__(quoted)}).joined(separator:";")
        case .EVAL(let q,let es):
            let ls = es.map({$0.__s__(quoted)}).joined(separator:",")
            return q.name == ARRAY_OP ? "[" + ls + "]" : q.name + "(" + ls + ")"
        case .VAL(let v): return (v is String && quoted) ? "\"" + v.s + "\"" : v.s
        case .VAR(let s,let t): return s + ":" + t.s$
        }
    }
    
    public var description:String{
        switch self{
        case .LIST(let es): return es.description
        case .EVAL(let q,let es):
            return ".EVAL(" + q.signature + "," + es.description + ")"
        case .VAL(let v):
            return ".VAL(\(v is String ? "\"\(v.s)\"" : v.s))"
        case .VAR(let s,let t):
            return ".VAR(\"\(s)\",\(t.s$))"
        }
    }
    
    public static func ==(a:Expr,b:Expr)->Bool{
        switch a{
        case .LIST(let es1):
            if case .LIST(let es2) = b{ return es1 == es2 }
        case .EVAL(let q1,let es1):
            if case .EVAL(let q2,let es2) = b{ return q1 == q2 && es1 == es2 }
        case .VAL(let v1):
            if case .VAL(let v2) = b{ return v1.equals(v2) }
        case .VAR(let s1,let t1):
            if case .VAR(let s2,let t2) = b{ return t1 == t2 && s1 == s2 }
        }
        return false
    }
    
    // MARK: IO
    
    public func ™(_ Ω:IO){
        switch self{
        case .LIST(let es): UInt8(0).™(Ω); es.™(Ω)
        case .EVAL(let q,let es): UInt8(1).™(Ω); q.™(Ω); es.™(Ω)
        case .VAL(let v): UInt8(2).™(Ω); v.t.™(Ω); v.™(Ω)
        case .VAR(let s,let t): UInt8(3).™(Ω); s.™(Ω); t.™(Ω)
        }
    }
    
    public static func ™(_ Ω:IO)throws->Expr{
        let c = try UInt8.™(Ω)
        switch c{
        case 0: return Expr.LIST(try [Expr].™(Ω))
        case 1: return Expr.EVAL(try PI.™(Ω),try [Expr].™(Ω))
        case 2: return Expr.VAL(try T.™(Ω).readEventValue(from:Ω))
        case 3: return Expr.VAR(try String.™(Ω),try T.™(Ω))
        default: fatalError("case = \(c)")
        }
    }
    
    // MARK: evaluate
    public func evaluate(_ vs:inout[String:any Event.Value])->[(any Event.Value)?]{
        if case .LIST(var es) = self{ return __evaluate_list__(&es,&vs) }
        else{ return [ __evaluate__(&vs) ] }
    }
    private func __evaluate__(_ vs:inout[String:any Event.Value])->(any Event.Value)?{
        switch self{
        case .LIST(_): fatalError()
        case .EVAL(let pi,var es):
            if pi.name.starts(with:MAKE_STRUCT_OP){ 
                return struct_constructor(String(pi.name.dropFirst()),&vs,&es)
            }else if let exe = pi.exe{
                let args = __evaluate_list__(&es,&vs)
                return exe(args)
            }else{ __log__.err("no exe for \(self.description)") }
            // e.g. this can happen for code boxes with no inputs (= no values to give variables)
            return nil
        case .VAL(let v): return v
        case .VAR(let s,_): return vs[s]
        }
    }
    
    private func __matches(_ vs:inout[any Event.Value],_ ts:[T])->Bool{
        if vs.count == ts.count{
            for i in 0..<vs.count{
                if vs[i].t != ts[i]{ return false }
            }
            return true
        }
        return false
    }
    
    private func __evaluate_list__(_ es:inout[Expr],_ vs:inout[String:any Event.Value])->[(any Event.Value)?]{
        var res = [(any Event.Value)?]()
        for e in es{ res.append( e.__evaluate__(&vs) ) }
        return res
    }
    
}

extension Array where Element == Expr{
    var description:String{
        return "["+map({$0.description}).joined(separator:",")+"]"
    }
}
