// 𝗙𝗟𝗢 : 𝗗𝗶𝘀𝘁𝗿𝗶𝗯𝘂𝘁𝗲𝗱 𝗛𝗶𝗲𝗿𝗮𝗿𝗰𝗵𝗶𝗰𝗮𝗹 𝗗𝗮𝘁𝗮𝗳𝗹𝗼𝘄 © 𝖪𝖾𝗏𝖾𝗇 𝖪𝖾𝖺𝗋𝗇𝖾𝗒 𝟮𝟬𝟮𝟯
import Foundation
import FloBox

// MARK: PROXY
public extension Box{
    var uri:String{ // e.g. the proxy URI, but could be other stuff as well
        get{ return self[.uri] as! String }
        set(u){  self[.uri] = u }
    }
}

class PROXY_IMP:Imp,Frame.Observer{
    
    static let skin = Skin(
        "",
        [Dot.ANON$:.BOOL(),
         Box.Keys.rate$:.FLOAT(0)],
        [Dot.ANON$:.BOOL()]
    )
    
    static func configure(_ slots:inout Slots){
        if slots[.uri] == nil{ fatalError() }
        if slots[.meta] == nil{
            slots[.meta] = NIL.instance()!
            //fatalError()
        }
        slots[.on] = false // always false = wait to see if proxy available
    }
    
    let box:Box
    init(_ box:Box){ self.box = box }
    
    var _force_publish_ = false // SEE Box.Proxy
    fileprivate var proxy:Device.Proxy?{ didSet{
        oldValue?.observers.rem(self)
        if let p = proxy{
            proxy?.observers.add(self)
            observed(p,[.dps,.skins])
        }
    }}
    
    private var __validated_proxy__:Device.Proxy?{
        if let p = proxy, p.published.contains(box.skin){ return p }
        return nil
    }
    func hub_changed(){
        proxy = box.hub?.__proxies_by_uuid__[box.uri]
    }
    func received(_ box:Box,_ inputs:[Dot.ID:Event],_ t:Time.Interval?){
        if let px = __validated_proxy__{
            var events = [Ports.ID:Event]()
            for (k,e) in inputs{
                if (_force_publish_) || (e =!= box.__cached_inputs__[k]){
                    events[k] = e
                    box.__cached_inputs__[k] = e
                }
            }
            _force_publish_ = false
            px.publish(box:box.name,events:events)
        }
    }
    public func observed(_ f:Frame,_ slots:[Slot.ID]){
        for id in slots{
            switch id{
            case .dps,.skins:
                let p = __validated_proxy__
                let on = p != nil && p!.state == .AVAILABLE
                if on != box.on{
                    box.on = on
                    if on{
                        __active_subscriptions__.removeAll()
                        for k in __connected_outputs__.keys{
                            __send_subscribe_request__(k)
                        }
                        _force_publish_ = true
                    }
                }
            default: break
            }
        }
    }
    
    // MARK: SUBSCRIPTIONS
    
    func notify(arc:Arc,added:Bool){ // called by the parent graph
        let k = arc.src.dotID
        let count = __connected_outputs__[k] ?? Int(0)
        if added{ __connected_outputs__[k] = count + 1 }
        else if count <= 1{ __connected_outputs__[k] = nil }
        else{ __connected_outputs__[k] = count - 1 }
    }
    
    private var __connected_outputs__ = [String:Int](){ didSet{
        for (k,_) in oldValue{
            if let i = oldValue[k], i <= 0{  }
            if __connected_outputs__[k] == nil{ __send_end_subscription__(k) }
        }
        for (k,_) in __connected_outputs__{
            if oldValue[k] == nil{ __send_subscribe_request__(k) }
        }
    }}
    
    private var __active_subscriptions__ = [String:Message.Token]()
    private func __send_subscribe_request__(_ output_name:String){ // return msg tkn
        if __active_subscriptions__[output_name] == nil{
            if let px = __validated_proxy__{
                let m = Message(.SUBSCRIBE(box.name,output_name,Event()))
                __active_subscriptions__[output_name] = m.token
                do{
                    try px.hub.send(msg:m,to:px.addr){ [weak self] reply in
                        if let ME = self{
                            if case .SUBSCRIBE(_,_,let event) = reply.payload{
                                ME.box.__output_events__[output_name] = event
                                return ME.__active_subscriptions__[output_name] == nil // stop if nil
                            }
                        }
                        return true
                    }
                }catch let e{
                    __log__.err(e.localizedDescription)
                }
            }
        }
    }
    private func __send_end_subscription__(_ output_index:String){
        if let msg_token = __active_subscriptions__[output_index],
           let px = __validated_proxy__{
            __active_subscriptions__[output_index] = nil
            let m = Message(msg_token,.END_SUBSCRIBE)
            do{
                try px.hub.send(msg:m,to:px.addr){ reply in
                    return true
                }
            }catch let e{ __log__.err(e.localizedDescription) }
        }
    }
    
}
