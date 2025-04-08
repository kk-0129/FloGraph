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
