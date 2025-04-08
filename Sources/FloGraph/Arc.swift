// 𝗙𝗟𝗢 : 𝗗𝗶𝘀𝘁𝗿𝗶𝗯𝘂𝘁𝗲𝗱 𝗛𝗶𝗲𝗿𝗮𝗿𝗰𝗵𝗶𝗰𝗮𝗹 𝗗𝗮𝘁𝗮𝗳𝗹𝗼𝘄 © 𝖪𝖾𝗏𝖾𝗇 𝖪𝖾𝖺𝗋𝗇𝖾𝗒 𝟮𝟬𝟮𝟯
import Foundation
import FloBox

public struct Arc : IO™,Hashable,Equatable{
    
    public let src, dst: Dot
    
    public init(_ src:Dot,_ dst:Dot){
        guard !src.input && dst.input else{ fatalError() }
        self.src = src
        self.dst = dst
    }
    
    // MARK: Hash
    public func hash(into h:inout Hasher){ h.combine(src); h.combine(src) }
    public static func ==(a:Arc,b:Arc)->Bool{ return a.src == b.src && a.dst == b.dst }
    
    // MARK: IO
    public func ™(_ Ω:IO){
        src.™(Ω)
        dst.™(Ω)
    }
    public static func ™(_ Ω:IO)throws->Arc{
        return Arc(try Dot.™(Ω),try Dot.™(Ω))
    }
    
}

public extension Set where Element == Arc{
    func copy(_ idmap:inout[Box.ID:Box])->Set<Arc>{
        var arcs = Set<Arc>()
        for a in self{
            if let s = idmap[a.src.boxID], let d = idmap[a.dst.boxID]{
                arcs.insert(Arc(Dot(output:s.id,a.src.dotID),Dot(input:d.id,a.dst.dotID)))
            }
        }
        return arcs
    }
}
