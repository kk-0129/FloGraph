// 𝗙𝗟𝗢 : 𝗗𝗶𝘀𝘁𝗿𝗶𝗯𝘂𝘁𝗲𝗱 𝗛𝗶𝗲𝗿𝗮𝗿𝗰𝗵𝗶𝗰𝗮𝗹 𝗗𝗮𝘁𝗮𝗳𝗹𝗼𝘄 © 𝖪𝖾𝗏𝖾𝗇 𝖪𝖾𝖺𝗋𝗇𝖾𝗒 𝟮𝟬𝟮𝟯
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
