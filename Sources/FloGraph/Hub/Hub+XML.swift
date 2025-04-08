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

public extension Hub{
    
    convenience init(_ n:Device.Name,_ eps:[EP],_ xml:URL){
        self.init(n,eps)
        do{
            let data = try Data(contentsOf:xml)
            let devices = XMLDeviceParser().parse(data)
            __log__.err("devices # = \(devices.count)")
            for (k,v) in devices{
                add(proxy:k,for:v)
            }
        }catch let e{
            __log__.err("Hub: unable to read XML file: \(e.localizedDescription)")
        }
    }
}

class XMLDeviceParser : NSObject, XMLParserDelegate {
    
    /*
     EXAMPLE:
     <?xml version="1.0" encoding="UTF-8"?>
     <root>
         <device uuid="Simple-Test" kind="ipv4" address="local:9929"/>
     </root>
     */
    
    var _parsed_devices = [String:EP.Address]()
    
    func parse(_ data:Data)->[String:EP.Address]{
        _parsed_devices.removeAll()
        let xmlParser = XMLParser(data:data)
        xmlParser.delegate = self
        xmlParser.parse()
        return _parsed_devices
    }
    
    var __n__ : String?{ didSet{ __v__.removeAll() }}
    var __v__ = [String:T]()
    
    func parser(
        _ parser: XMLParser,
        didStartElement eName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attrs: [String : String] = [:]
    ){
        switch eName{
        case "device":
            __log__.info("xml - found device")
            if let n = attrs["uuid"],
               let k = attrs["kind"],
               let a = attrs["address"]{
                switch k{
                case IPv4.kind: _parsed_devices[n] = IPv4.from(a)
                default: break
                }
            }
        default:
            __log__.info("xml + \(eName)")
        }
    }

}
