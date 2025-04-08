// 𝗙𝗟𝗢 : 𝗗𝗶𝘀𝘁𝗿𝗶𝗯𝘂𝘁𝗲𝗱 𝗛𝗶𝗲𝗿𝗮𝗿𝗰𝗵𝗶𝗰𝗮𝗹 𝗗𝗮𝘁𝗮𝗳𝗹𝗼𝘄 © 𝖪𝖾𝗏𝖾𝗇 𝖪𝖾𝖺𝗋𝗇𝖾𝗒 𝟮𝟬𝟮𝟯
import Foundation
import FloBox

public extension Expr{
    static let TYPE_SYMBOL = ":"
}

class Toks{
    
    typealias Err = Parser.Err
    
    public let tokens:[Tok]
    var index = 0
    init(_ tks:[Tok]){ tokens = tks }
    func peek()throws->Tok{
        if more{ return tokens[index] }
        throw Err.EXPECTED(.TOKENS)
    }
    func pop()throws->Tok{
        defer{ index += 1 }
        return try peek()
    }
    var more:Bool{ return index < tokens.count }
    var description:String{ return tokens.description }
    func matches(_ tks:Toks)->Bool{
        return tokens.matches(tks.tokens)
    }
    
}

// MARK: Tokens
public enum Tok{
    
    case ID(String)
    case PUNC(DELIM)
    case VAL(any Event.Value)
    case VAR(String,T = .UNKNOWN)
    case STRUCT(String)
    case OP(String)
    
    func op(_ k:OP.Kind)->OP?{
        switch self{
        case .ID(let s): return FloGraph.OP.builtin(s,k)
        case .PUNC(let p): return FloGraph.OP.builtin("\(p.rawValue)",k)
        default: return nil
        }
    }
    
    public var s:String{
        switch self{
        case .ID(let s): return s
        case .OP(let s): return s
        case .STRUCT(let s): return s
        case .PUNC(let p): return "\(p.rawValue)"
        case .VAL(let v): return v.s
        case .VAR(let s,let t): return s + Expr.TYPE_SYMBOL + t.s$
        }
    }
    
    public var description:String{
        switch self{
        case .ID: return "ID(\(s))"
        case .STRUCT: return "STRUCT(\(s))"
        case .OP: return "OP(\(s))"
        case .PUNC(let p): return "PUNC(.\(p))"
        case .VAL: return "VALUE(\(s))"
        case .VAR: return "VAR(\(s))"
        }
    }
    
    public func matches(_ t:Tok)->Bool{
        switch self{
        case .ID(let s1):
            if case .ID(let s2) = t{ return s1 == s2 }
            return false
        case .PUNC(let p1):
            if case .PUNC(let p2) = t{ return p1 == p2 }
            return false
        case .VAL(let v1):
            if case .VAL(let v2) = t{ return v1.equals(v2) }
            return false
        case .VAR(let s1,let t1):
            if case .VAR(let s2,let t2) = t{ return t1 == t2 && s1 == s2 }
            return false
        default: return false
        }
    }
}

// MARK: DELIM
public enum DELIM:C{
    case DOT = "."
    case COLON = ":"
    case SEMI_COLON = ";"
    case COMMA = ","
    case SQUARE_L = "["
    case SQUARE_R = "]"
    case ROUND_L = "("
    case ROUND_R = ")"
    case CURLY_L = "{"
    case CURLY_R = "}"
    var s:String{ return String("\(self)") }
    public var description:String{
        switch self{
        case .DOT: return "DOT"
        case .COLON: return "COLON"
        case .SEMI_COLON: return "SEMI_COLON"
        case .COMMA: return "COMMA"
        case .SQUARE_L: return "SQUARE_L"
        case .SQUARE_R: return "SQUARE_R"
        case .ROUND_L: return "ROUND_L"
        case .ROUND_R: return "ROUND_R"
        case .CURLY_L: return "CURLY_L"
        case .CURLY_R: return "CURLY_R"
        }
    }
}

public extension Array where Element == Tok{
    var description:String{
        var s = "["
        for i in 0..<count{
            if i > 0{ s += "," }
            s += self[i].description
        }
        return s + "]"
    }
    func matches(_ tks:[Tok])->Bool{
        guard count == tks.count else{ return false }
        for i in 0..<count{
            if !self[i].matches(tks[i]){ return false }
        }
        return true
    }
}
