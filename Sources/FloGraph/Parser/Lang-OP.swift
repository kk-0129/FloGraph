// 𝗙𝗟𝗢 : 𝗗𝗶𝘀𝘁𝗿𝗶𝗯𝘂𝘁𝗲𝗱 𝗛𝗶𝗲𝗿𝗮𝗿𝗰𝗵𝗶𝗰𝗮𝗹 𝗗𝗮𝘁𝗮𝗳𝗹𝗼𝘄 © 𝖪𝖾𝗏𝖾𝗇 𝖪𝖾𝖺𝗋𝗇𝖾𝗒 𝟮𝟬𝟮𝟯
import Foundation
import FloBox

class OP{
    
    static let MAX_PRIORITY = 1200
    
    enum Kind{ case PREFIX, INFIX, POSTFIX }
    enum Spec{ case FX, FY, XF, XFX, XFY, YF, YFX }
    
    let spec:Spec
    /*
     The ‘f’ indicates the position of the functor
     while x and y indicate the position of the arguments
     - ‘y’= “on this position a term with precedence lower or equal to the precedence of the functor should occur''.
     - ‘x’ = the precedence of the argument must be strictly lower.
     */
    var kind:Kind{
        switch spec{
        case .XF,.YF: return .POSTFIX
        case .FX,.FY: return .PREFIX
        case .XFX,.XFY,.YFX: return .INFIX
        }
    }
    
    let name:String
    let pre_priority, priority, post_priority:Int
    let prex, postx: Bool
    
    init(_ n:String,_ spec:Spec,_ priority:Int){
        self.name = n
        self.spec = spec
        self.priority = priority
        prex = spec == .XF || spec == .XFX || spec == .XFY
        postx = spec == .FX || spec == .XFX || spec == .YFX
        pre_priority = prex ? priority-1 : priority;
        post_priority = postx ? priority-1 : priority;
    }
    
    var quoted:OP{
        // TODO: see Clause - not simple!
        return self
    }
    
    func under(_ op:OP)->Int{
        if (priority < op.priority){ return 1 }
        if (priority > op.priority){ return 2 }
        if !op.prex{ return 1 }
        if !postx{ return 2 }
        return 0
    }
    
    static func builtin(_ s:String,_ k:Kind)->OP?{
        if let ops = __builtin_ops__[s]{
            if let op = ops.values.first(where:{$0.kind == k}){
                return op
            }
        }
        return nil
    }
    
}

private let __builtin_ops__:[String:[Int:OP]] = [
    "=" : [ 2 : OP("=",.XFY,1200) ], // ivar assignment
    ";" : [ 2 : OP(";",.XFY,1100) ], // disjunction
    //"," : [ 2 : OP(",",.XFY,1000) ], // conjunction
    "&" : [ 2 : OP("&",.XFY,800) ], // logical AND
    "|" : [ 2 : OP("|",.XFY,800) ], // logical OR
    "^" : [ 2 : OP("^",.XFY,800) ], // logical XOR
    "==" : [ 2 : OP("==",.XFX,700) ],
    "!=" : [ 2 : OP("!=",.XFX,700) ],
    ">" : [ 2 : OP(">",.XFX,700) ],
    ">=" : [ 2 : OP(">=",.XFX,700) ],
    "<" : [ 2 : OP("<",.XFX,700) ],
    "<=" : [ 2 : OP("<=",.XFX,700) ],
    "+" : [ 2 : OP("+",.YFX,500) ],
    "#" : [ 2 : OP("#",.YFX,500) ], // STRING CONCATENATION
    "*" : [ 2 : OP("*",.YFX,400) ],
    "/" : [ 2 : OP("/",.YFX,400) ],
    "-" : [
        1 : OP("-",.FY,200), // NEGATE
        2 : OP("-",.YFX,500) // MINUS
    ],
    "!" : [ 1 : OP("!",.FY,200) ], // NOT
    "°" : [ 2 : OP("°",.YFX,50) ], // tuple/array indices
    "." : [ 2 : OP(".",.XFY,50) ], // struct ivar access
]
