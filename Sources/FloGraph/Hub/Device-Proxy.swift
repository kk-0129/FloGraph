// 𝗙𝗟𝗢 : 𝗗𝗶𝘀𝘁𝗿𝗶𝗯𝘂𝘁𝗲𝗱 𝗛𝗶𝗲𝗿𝗮𝗿𝗰𝗵𝗶𝗰𝗮𝗹 𝗗𝗮𝘁𝗮𝗳𝗹𝗼𝘄 © 𝖪𝖾𝗏𝖾𝗇 𝖪𝖾𝖺𝗋𝗇𝖾𝗒 𝟮𝟬𝟮𝟯
import Foundation
import FloBox

public extension Device{
    
    class Proxy:Frame{
        
        public typealias UUID = String // unique proxy identifier
        
        public var uuid:UUID
        public let addr:EP.Address
        public let hub:Hub
        
        init(_ hub:Hub,_ uuid:UUID,_ addr:EP.Address){
            self.hub = hub
            self.uuid = uuid
            self.addr = addr
            super.init(nil,[
                .dps:State.UNAVAILABLE, // state of device
                .skins:[Skin]() // skins published by the device
            ])
            inited()
        }
        
        // MARK: hashable
        public override func hash(into h: inout Hasher){ h.combine(addr.uri) }
        public static func ==(a:Proxy,b:Proxy)->Bool{ return a.addr.uri == b.addr.uri }
        
        // MARK: STATE
        public enum State:UInt8{
            
            case AVAILABLE = 2
            case WAITING = 1
            case UNAVAILABLE = 0
            
            public func ™(_ Ω:IO){ rawValue.™(Ω) }
            public static func ™(_ Ω:IO)throws->Device.Proxy.State{
                return Device.Proxy.State(rawValue:try UInt8.™(Ω))!
            }
            
        }
        
        public var state:State{
            get{ return self[.dps] as! Device.Proxy.State }
            set(s){ if s != state{ self[.dps] = s }}
        }
        
        // MARK: Skins
        public var published:[Skin]{
            get{ return self[.skins] as! [Skin] }
            set(s){ self[.skins] = s }
        }
        
        // MARK: PUBLISH
        private let _publish_token = Message.Token.next
        func publish(box:Device.Box.Name,events:[Ports.ID:Event]){
            // publish changed input values to the proxy ep
            if !events.isEmpty{
                let m = Message(_publish_token,.PUBLISH(box,events))
                do{
                    try hub.send(msg:m,to:addr)
                }catch let e{ __log__.err(e.localizedDescription) }
            }
        }
        
        // MARK: PING
        private var _missed_pings = 100
        private let MAX_MISSED_PINGS = 4
        private var ping_token:Message.Token?
        func ping(){ // invoked regularly by the hub
            do{
                _missed_pings += 1
                //__log__.debug("\(name), missed pings = \(_missed_pings)")
                if ping_token == nil{ ping_token = Message.Token.next }
                if _missed_pings > MAX_MISSED_PINGS{
                    let m = Message(ping_token!,.HANDSHAKE)
                    //__log__.debug("sending handshake #\(m.token) to \(addr.uri)")
                    __ping_update(state:.UNAVAILABLE,nil,nil)
                    try hub.send(msg:m,to:addr){ [weak self] _ in
                        return self?.__rcvd_handshake_reply() ?? true
                    }
                }else{
                    //__log__.debug("sending ping #\(ping_token!) to \(name)")
                    let m = Message(ping_token!,.PING)
                    try hub.send(msg:m,to:addr){ [weak self] msg in
                        return self?.__rcvd_ping_reply(msg) ?? true
                    }
                }
            }catch let e{ __log__.err("EP.ping: "+e.localizedDescription) }
        }
        private func __rcvd_handshake_reply()->Bool{
            //__log__.debug("\(uuid) rcvd handshake reply from \(addr.uri)")
            __ping_update(state:.WAITING,nil,nil)
            return true
        }
        private func __rcvd_ping_reply(_ msg:Message)->Bool{
            switch msg.payload{
            case .PING:
                //__log__.debug("\(self.uuid) rcvd PING reply from \(addr.uri)")
                __ping_update(state:.AVAILABLE,nil,nil)
            case .PING_UPDATE(let name,let skins): 
                //__log__.debug("\(name) rcvd PING_UPDATE reply from \(addr.uri)")
                for s in skins{
                    __log__.debug(" > \(s.s)")
                }
                __ping_update(state:.AVAILABLE,name,skins)
            default: break
            }
            return false
        }
        private func __ping_update(state:Proxy.State,_ name:String?,_ skins:[Skin]?){
            _missed_pings = state == .UNAVAILABLE ? 100 : 0
            self.state = state
            if let n = name, n != name{
                //__log__.info("changed proxy name from '\(self.uuid)' to '\(n)'")
                self.uuid = n
            }
            if let skins = skins{ published = skins }
        }
        
    }
    
}

// MARK: Message.Recipient
extension Device.Proxy: Message.Recipient{
    
    public func type(ep:EP.Address,box:Device.Box.Name,port:Ports.ID,input:Bool)->T?{
        guard ep.uri == self.addr.uri else{ return nil }
        if let s = published.first(where:{$0.name == box}){
            return input ? s.inputs[port] : s.outputs[port]
        }
        return nil
    }
    
    public func received(_ msg:Message,from:EP.Address){ // from = device or proxy
        fatalError()
        //__log__.warn("TODO: Proxy \(self.addr.uri), handle msg")
        // TODO: will be used when we implement PUBLISH !!!
    }
    
}
