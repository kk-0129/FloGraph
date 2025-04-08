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
