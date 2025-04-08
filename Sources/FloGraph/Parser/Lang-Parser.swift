// 𝗙𝗟𝗢 : 𝗗𝗶𝘀𝘁𝗿𝗶𝗯𝘂𝘁𝗲𝗱 𝗛𝗶𝗲𝗿𝗮𝗿𝗰𝗵𝗶𝗰𝗮𝗹 𝗗𝗮𝘁𝗮𝗳𝗹𝗼𝘄 © 𝖪𝖾𝗏𝖾𝗇 𝖪𝖾𝖺𝗋𝗇𝖾𝗒 𝟮𝟬𝟮𝟯
import Foundation
import FloBox

public class Parser{
    
    // MARK: access to Lexer
    //public static func tokenise(_ s:String)throws->[Tok]{
    //    return try Lexer2(s).toks().tokens
    //}
    public static func parse(expr s:String)throws->Expr?{
        var es = [Expr]()
        let ss = s.components(separatedBy:";")
        var vars = [String:Expr]()
        for s in ss{
            if let e = try __parse__(expr:s,&vars){ es.append(e) }
        }
        return es.isEmpty ? nil : (es.count == 1 ? es.first : .LIST(es))
    }
    
    
    
    // MARK: main entry point (for expressions)
    private static func __parse__(expr s:String,_ vars:inout[String:Expr])throws->Expr?{
        let toks = try Lexer(s).toks()
        __debug__("\(toks.description)")
        if let t = try _parse_term1(toks,OP.MAX_PRIORITY,""){
            return try t.expr(&vars)
        }
        return nil
    }
    
    // MARK: main entry point (for param editor)
    public static func parse(value s:String,type t:T)throws->any Event.Value{
        if let e = try parse(expr:s){
            var vars = [String:(any Event.Value)]()
            let vs = e.evaluate(&vars)
            if vars.isEmpty{
                if vs.count == 1, let v = vs[0]{
                    if v.t == t{ return v }
                    else{ throw Err.UNEXPECTED(.TYPE) }
                }else{ throw Err.EXPECTED(.VALUE)}
            }else{ throw Err.UNEXPECTED(.VARIABLE)}
        }else{ throw Err.EXPECTED(.EXPR) }
    }
    
    /*
     The parser outputs the root Term of an Abstract Syntax Tree
     */
    private static func _parse_term1(_ toks:Toks,_ priority:Int,_ ì:String)throws->Term?{
        __debug__("TERM1",ì)
        if toks.more{
            __debug__(try toks.peek(),ì)
            let mark = toks.index
            let tok = try toks.pop()
            if let op = tok.op(.PREFIX),
               !(try toks.peek()).matches(.PUNC(.ROUND_L)),
               op.priority <= priority{
                if let t = try _parse_term1(toks,op.post_priority,ì+tab$){
                    let c = Term(.OP(tok.s),[t]) // the prefix term
                    if let t = try _parse_subsequent(1,c,op.priority,toks,priority,ì+tab$){
                        return __debug__( t ,"TERM1.a",ì)
                    }else{
                        return __debug__( c ,"TERM1.b",ì)
                    }
                }
            }
            toks.index = mark
            if let t = try _parse_term2(toks,ì+tab$){
                if let t1 = try _parse_subsequent(2,t,0,toks,priority,ì+tab$){
                    return __debug__( t1 ,"TERM1.c",ì)
                }else{
                    return __debug__( t, "TERM1.d",ì)
                }
            }
            toks.index = mark
        }
        return __debug__( nil ,"TERM1.e",ì)
    }
    
    private static func _parse_term2(_ toks:Toks,_ ì:String)throws->Term?{
        __debug__("TERM2",ì)
        if toks.more{
            __debug__(try toks.peek(),ì)
            let mark = toks.index
            let tok = try toks.pop()
            do{
                switch tok{
                case .VAR,.VAL:
                    let t = Term(tok,[])
                    return __debug__( t ,"TERM2.a",ì)
                case .PUNC(let d):
                    switch d{
                    case .SQUARE_L:
                        if let t = try _parse_array(toks,ì+tab$){
                            return __debug__( t ,"TERM2.b",ì)
                        }
                    case .ROUND_L:
                        let t = try _parse_brackets(toks,.ROUND_L,.ROUND_R,ì+tab$)
                        return __debug__( t ,"TERM2.c",ì)
                    default: break
                    }
                case .ID(let s):
                    var end = DELIM.ROUND_R
                    switch try toks.peek(){
                    case .PUNC(end): return Term(tok,[])
                    case .PUNC(.CURLY_L):
                        end = .CURLY_R
                        fallthrough
                    case .PUNC(.ROUND_L):
                        _ = try toks.pop()
                        var args = [Term]()
                        while true{
                            if let a = try _parse_term1(toks,OP.MAX_PRIORITY,ì+tab$){
                                args.append(a)
                            }
                            switch try toks.pop(){
                            case .PUNC(end):
                                if end == .CURLY_R{
                                    let t = Term(.STRUCT(s),args)
                                    return __debug__( t ,"TERM2.e",ì)
                                }else{
                                    let t = Term(.OP(s),args)
                                    return __debug__( t ,"TERM2.f",ì)
                                }
                            case .PUNC(.COMMA): break
                            default:
                                return __debug__( nil ,"TERM2.g",ì)
                            }
                        }
                    default:
                        return Term(tok,[])
                    }
                default: fatalError()
                }
            }catch{
                if case .ID(_) = tok {
                    let t = Term(tok,[])
                    return __debug__( t ,"TERM2.i",ì)
                }
            }
            toks.index = mark
        }
        return __debug__( nil ,"TERM2.j",ì)
    }
    
    private static func _parse_subsequent(_ caller:Int,_ prev:Term,_ prev_priority:Int,_ toks:Toks,_ top_priority:Int,_ ì:String)throws->Term?{
        __debug__("SUB",ì)
        if toks.more{
            __debug__(try toks.peek(),ì)
            let mark = toks.index
            var tok = try toks.pop()
            if let op = tok.op(.POSTFIX),
               op.priority <= top_priority,
               prev_priority < op.pre_priority{
                let x = Term(tok,[prev])
                if let t = try _parse_subsequent(3,x,op.priority,toks,top_priority,ì+tab$){
                    return __debug__( t ,"SUB.a",ì)
                }
            }
            toks.index = mark
            tok = try toks.pop()
            if let op = tok.op(.INFIX),
               op.priority <= top_priority,
               prev_priority < op.pre_priority{
                if let t = try _parse_term1(toks,op.post_priority,ì+tab$){
                    if let t = try _parse_infix(prev,op,t,toks,top_priority,ì+tab$){
                        return __debug__( t ,"SUB.b",ì)
                    }
                }
            }
            toks.index = mark
        }
        return __debug__( nil ,"SUB.c",ì)
    }
    
    private static func _parse_infix(_ t1:Term,_ op1:OP,_ t2:Term,_ toks:Toks,_ top_priority:Int,_ ì:String)throws->Term?{
        __debug__("INFIX",ì)
        let def = Term(.OP(op1.name),[t1,t2])
        if !toks.more{
            return __debug__( def ,"INFIX.a",ì)
        }
        let mark = toks.index
        if let op2 = try toks.pop().op(.INFIX),
           op2.priority <= top_priority{
            if let t3 = try _parse_term1(toks, op2.post_priority,ì+tab$){
                switch op1.under(op2){
                case 1:
                    if let t = try _parse_infix(def,op2,t3,toks,top_priority,ì+tab$){
                        return __debug__( t ,"INFIX.b",ì)
                    }
                case 2:
                    let t4 = Term(.OP(op2.name),[t2,t3])
                    let t = Term(.OP(op1.name),[t1,t4])
                    return __debug__( t ,"INFIX.c",ì)
                default: fatalError()
                }
            }
        }else{
            toks.index = mark
            return __debug__( def ,"INFIX.d",ì)
        }
        toks.index = mark
        return __debug__( nil ,"INFIX.e",ì)
    }
    
    private static func _parse_array(_ toks:Toks,_ ì:String)throws->Term?{
        __debug__("ARRAY",ì)
        let mark = toks.index
        if let head = try _parse_term1(toks,OP.MAX_PRIORITY,ì+tab$){
            if case .PUNC(let d) = try toks.pop(){
                switch d{
                case .SQUARE_R:
                    let t = Term(.PUNC(.SQUARE_L),[head])
                    return __debug__( t ,"ARRAY.a",ì)
                case .COMMA:
                    if let tail = try _parse_array(toks,ì+tab$){
                        let t = Term(.PUNC(.SQUARE_L),[head] + tail.args)
                        return __debug__( t ,"ARRAY.b",ì)
                    }
                default: break
                }
            }
        }
        toks.index = mark
        return __debug__( nil ,"ARRAY.c",ì)
    }
    
    private static func _parse_brackets(_ toks:Toks,_ start:DELIM,_ end:DELIM,_ ì:String)throws->Term?{
        __debug__("BRACKETS",ì)
        var res = [Term]()
        while true{
            if let a = try _parse_term1(toks,OP.MAX_PRIORITY,ì+tab$){
                res.append(a)
                if case .PUNC(end) = try toks.pop(){
                    if res.count == 1{ return res[0] }
                    let t = Term(.PUNC(start),res)
                    return __debug__( t ,"BRACKETS.a",ì)
                }
            }else{
                return __debug__( nil ,"BRACKETS.b",ì)
            }
        }
    }
    
}

private let tab$ = "    "
public var ___debug_parser___ = false
private func __debug__(_ s:String){
    if ___debug_parser___{ __log__.debug("# "+s) }
}
private func __debug__(_ t:Term?,_ s:String,_ ì:String)->Term?{
    if ___debug_parser___{ __log__.debug(ì+"↵"+s+" = \(t == nil ? "nil" : t!.s)") }
    return t
}
private func __debug__(_ s:String,_ ì:String){
    if ___debug_parser___{ __log__.debug(ì+"➔"+s) }
}
private func __debug__(_ t:Tok,_ ì:String){
    if ___debug_parser___{ __log__.debug(ì+"  @ "+(t.description)) }
}
