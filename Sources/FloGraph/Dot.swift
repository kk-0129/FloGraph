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

public struct Dot : IO™,Hashable,Equatable{
    
    public typealias ID = Ports.ID
    public static let ANON$ = "_"
 
    public let boxID:Box.ID
    public let dotID:Dot.ID
    public var input:Bool
    
    public init(input box:Box.ID,_ id:Dot.ID){ self.init(true,box,id) }
    public init(output box:Box.ID,_ id:Dot.ID){ self.init(false,box,id) }
    private init(_ input:Bool,_ box:Box.ID,_ id:Dot.ID){
        self.input = input
        self.boxID = box
        self.dotID = id
    }
    
    // MARK: HASH
    public func hash(into h:inout Hasher){
        h.combine(input)
        h.combine(boxID)
        h.combine(dotID)
    }
    public static func ==(a:Dot,b:Dot)->Bool{
        return a.input == b.input && a.boxID == b.boxID && a.dotID == b.dotID
    }
    
    // MARK: SERIALISATION
    public func ™(_ Ω:IO){
        input.™(Ω)
        boxID.™(Ω)
        dotID.™(Ω)
    }
    
    public static func ™(_ Ω:IO)throws->Dot{
        return Dot(try Bool.™(Ω),try Box.ID.™(Ω),try Dot.ID.™(Ω))
    }
    
}
