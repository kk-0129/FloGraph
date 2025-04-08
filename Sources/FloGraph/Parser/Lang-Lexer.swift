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

class Lexer{
    
    typealias Err = Parser.Err
    
    let the_string$: String
    var index: String.Index
    
    init(_ s:String){
        the_string$ = s
        index = s.startIndex
    }
    
    func toks()throws->Toks{
        index = the_string$.startIndex
        var tks = [Tok]()
        while let tok = try _advance(&tks){ tks.append(tok) }
        return Toks(tks)
    }
    
    private var _curc:C?{
        return index < the_string$.endIndex ? the_string$[index] : nil
    }
    
    private func __advance__(){ the_string$.formIndex(after:&index) }
    
    private var _typedvar_:Tok?
    private func _advance(_ tks:inout[Tok])throws->Tok?{
        while let c = _curc{
            var previous = tks.last
            if case .VAR(let var_name,let old_type) = _typedvar_{
                _typedvar_ = nil
                let type_name = _readtypename(c)
                if let t = T.type(named:type_name){
                    if old_type != .UNKNOWN, t != old_type{ 
                        throw Err.CONFLICT(.TYPE)
                    }
                    return .VAR(var_name,t)
                }
                throw Err.EXPECTED(.TYPE)
            }else if c.isWhitespace{ __advance__() }
            else if let tok = DELIM(rawValue:c){
                __advance__()
                if let tk = tks.last, case .VAR = tk, c == DELIM.COLON.rawValue{
                    _typedvar_ = tks.removeLast()
                }else{ return .PUNC(tok) }
            }else if c.double_quote || c.single_quote{
                // STRING ...
                var z = _read(c){ return !($1 == c && !($0.escape)) }
                var ts = [Tok]()
                if let t = tks.last{ ts.append(t) }
                if c == _curc{
                    __advance__()
                    z.append(c)
                }else{ throw Err.EXPECTED(.QUOTES) }
                z = z.unquoted
                return .VAL(z)
            }else if c.graphic{
                let s = _read(c){$1.graphic}
                if s == "="{
                    if let p = previous, case .VAR(let s,_) = p{
                        tks[tks.count-1] = .ID(s)
                        previous = tks.last
                    }
                }
                return .ID(s)
            }else if c.alpha{
                // IDENTIFIER ...
                let s = _read(c){$1.alphanum}
                if s == "true"{ return .VAL(true) }
                if s == "false"{ return .VAL(false) }
                if s.count == 1, s.first!.atoz{
                    if let p = previous, case .PUNC(let q) = p,q == .DOT{
                        return .ID(s) // it's a struct ivar_name
                    }
                    return .VAR(s,.UNKNOWN)
                }else{ return .ID(s) }
            }else if c.digit{
                // DIGIT ...
                if let t = _digit(c){ return t }
            }else if c.sub != nil{
                // SUBSCRIPT ...
                let s = _read(c){ $1.sub != nil } // guarantees that s only contains subs
                tks.append(.ID("°"))
                let f = Float32( s.map({"\($0.sub!)"}).joined() )
                return .VAL(f!)
            }else{
                throw Err.EXPECTED(.CHARACTER)
            }
        }
        return nil
    }
    
    private func _digit(_ c:C)->Tok?{
        let s = _read(c){$1.digit || $1 == "."}
        if let f = Float32(s){ return .VAL(f) }
        return nil
    }
    
    private func _readtypename(_ c:C)->String{
        if c == "["{
            __advance__()
            if let c = _curc{
                let s = _readtypename(c)
                if let c = _curc, c == "]"{ __advance__() }
                return "[\(s)]"
            }else{ return "[" }
        }else{ return _read(c){ $1.alphanum } }
    }
    
    private func _read(_ c:C,_ f:@escaping(C,C)->Bool)->String{
        __advance__()
        var s = "\(c)"
        var prev = c
        while let c = _curc, f(prev,c){
            prev = c
            s.append(c)
            __advance__()
        }
        return s
    }
    
}
