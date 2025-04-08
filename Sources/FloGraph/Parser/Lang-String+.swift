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

// MARK: ■ Character +
public typealias C = Character
public extension C{
    var double_quote:Bool{ return self == "\"" }
    var single_quote:Bool{ return self == "\'" }
    var escape:Bool{ return self == "\\" }
    static let delimiters = "()[],{}:;'"
    var delimiter:Bool{ return C.delimiters.contains(self) }
    static let negation = "-"
    static let graphics = "=!><+-*/%.-!&|^#°?"
    var graphic:Bool{ return C.graphics.contains(self) }
    static let digits:[C] = ["0","1","2","3","4","5","6","7","8","9"]
    var digit:Bool{ return C.digits.contains(self) }
    var alpha:Bool{ return self == "_" || AtoZ || atoz }
    var alphanum:Bool{ return alpha || digit }
    var AtoZ: Bool{ return "A" <= self && self <= "Z" }
    var atoz: Bool{ return "a" <= self && self <= "z" }
    var _atoz: Bool{ return atoz || "_" == self }
    //
    static let PI = C("π")   
    static let True = C("⊤")
    static let False = C("⊥")
    static let subs:[C] = ["₀","₁","₂","₃","₄","₅","₆","₇","₈","₉"]
    var sub:Int?{ return C.subs.firstIndex(of:self) }
    //var sub:Bool{ return C.subs.contains(self) }
    
}

// MARK: ■ Strings +
func _is_quoted_str(_ s:String)->Bool{ return "\"" == s.first && "\"" == s.last }

extension String{
    var unquoted:String{
        for c in [C("\""),C("\'")]{
            if c == first, c == last{
                let i = index(startIndex,offsetBy:1)
                let j = index(endIndex,offsetBy:-1)
                return String(self[i..<j])
            }
        }
        return self
    }
    var subindex:Int?{
        // parses a string of 'sub' numbers (₀₁₂₃₄₅₆₇₈₉) into an Int ..
        var ints = [Int]()
        for c in self{
            if let i = C.subs.firstIndex(of:c){ ints.append(i) }
            else{ return nil }
        }
        if !ints.isEmpty{
            ints = ints.reversed()
            var n = 0
            for i in 0..<ints.count{ n += ints[i] * Int(pow(Float32(10),Float32(i))) }
            return n
        }
        return nil
    }
}
