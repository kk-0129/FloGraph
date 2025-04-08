// 𝗙𝗟𝗢 : 𝗗𝗶𝘀𝘁𝗿𝗶𝗯𝘂𝘁𝗲𝗱 𝗛𝗶𝗲𝗿𝗮𝗿𝗰𝗵𝗶𝗰𝗮𝗹 𝗗𝗮𝘁𝗮𝗳𝗹𝗼𝘄 © 𝖪𝖾𝗏𝖾𝗇 𝖪𝖾𝖺𝗋𝗇𝖾𝗒 𝟮𝟬𝟮𝟯
import Foundation
import FloBox

public extension Parser{
    
    // MARK: Error
    enum Err : Error, Equatable{
        
        public enum Reason: String{
            case TYPE = "type"
            case VARIABLE = "variable"
            case QUOTES = "closing quotes"
            case TOKENS = "tokens"
            case CHARACTER = "character"
            case EXPR = "expression"
            case VALUE = "value"
            case ARGS = "arguments"
            case OPERATOR = "operator"
        }
        
        case UNKNOWN(Reason)
        case EXPECTED(Reason)
        case UNEXPECTED(Reason)
        case CONFLICT(Reason)
        
        var localizedDescription:String{
            switch self{
            case .UNKNOWN(let x): return "unknown \(x.rawValue)"
            case .EXPECTED(let x): return "expected \(x.rawValue)"
            case .UNEXPECTED(let x): return "unexpected \(x.rawValue)"
            case .CONFLICT(let x): return "conflicting \(x.rawValue)"
            }
        }
        
        public static func == (a:Err,b:Err)->Bool{
            switch a{
            case .UNKNOWN(let x):
                if case .UNKNOWN(let y) = b, x == y{ return true }
            case .EXPECTED(let x):
                if case .EXPECTED(let y) = b, x == y{ return true }
            case .UNEXPECTED(let x):
                if case .UNEXPECTED(let y) = b, x == y{ return true }
            case .CONFLICT(let x):
                if case .CONFLICT(let y) = b, x == y{ return true }
            }
            return false
        }
        
    }
    
}
