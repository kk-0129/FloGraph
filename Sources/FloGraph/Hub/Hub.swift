// 𝗙𝗟𝗢 : 𝗗𝗶𝘀𝘁𝗿𝗶𝗯𝘂𝘁𝗲𝗱 𝗛𝗶𝗲𝗿𝗮𝗿𝗰𝗵𝗶𝗰𝗮𝗹 𝗗𝗮𝘁𝗮𝗳𝗹𝗼𝘄 © 𝖪𝖾𝗏𝖾𝗇 𝖪𝖾𝖺𝗋𝗇𝖾𝗒 𝟮𝟬𝟮𝟯
import Foundation
import FloBox
import Collections

public class Hub : Message.Recipient{
    
    public static let Local$ = "Local"
    
    public init(_ n:Device.Name,_ eps:[EP]){
        let dev = DEV_EP()
        self.eps = eps + [HUB_EP(dev)]
        self.address = Combo(eps.map{$0.address})
        //
        _ping_timer = Timer.scheduledTimer(withTimeInterval:0.5,repeats:true){ [weak self] _ in
            if let pxs = self?.proxies{
                for p in pxs{ p.ping() }
            }
        }
        _clock = __clock__(ms:2){ [weak self] in self?.__iterate__() }
        __log__.info("Hub started @ \(address.uri)")
    }
    
    // MARK: EP protocol -> see: Hub+EP
    let eps:[EP]
    public let address:EP.Address
    
    // MARK: DEVICE
    //let device:Device
    
    // MARK: PROXIES
    private var _ping_timer:Timer? = nil
    public func add(proxy uuid:Device.Proxy.UUID,for ep:EP.Address){
        if __proxies_by_uuid__[uuid] == nil{
            __proxies_by_uuid__[uuid] = Device.Proxy(self,uuid,ep)
            __log__.info("Hub (\(address.uri): added proxy '\(uuid)' for \(ep.uri)")
        }
    }
    public var proxies:[Device.Proxy]{ return [Device.Proxy](__proxies_by_uuid__.values) }
    var __proxies_by_uuid__ = [Device.Proxy.UUID:Device.Proxy](){ didSet{
        for (k,v) in oldValue{
            if __proxies_by_uuid__[k] == nil{ __update_uris__(v,nil) }
        }
        for (k,v) in __proxies_by_uuid__{
            if oldValue[k] == nil{ __update_uris__(v,v.uuid) }
        }
    }}
    private func __update_uris__(_ p:Device.Proxy,_ u:Device.Proxy.UUID?){
        var eps = [p.addr]
        if let c = p.addr as? Combo{ eps = c.eps }
        for e in eps{ __proxy_uris_by_address_uri__[e.uri] = u }
    }
    private var __proxy_uris_by_address_uri__ = [EP.Address.URI:Device.Proxy.UUID]()
    
    // MARK: ENGINE
    public var filter:Filter?
    public var running = false{ didSet{
        _clock.running = running
        for ep in self.eps{
            ep.recipient = running ? self : nil
        }
    }}
    
    // MARK: mods
    private let __mods_mutex__ = __mutex__()
    var __mods__ = [Graph:[Box:[Dot.ID:Event]]]() // output dots with modified values
    func notify(output e:Event,d:Dot.ID,of b:Box,in g:Graph){
        __mods_mutex__.sync {
            var x = __mods__[g] ?? [Box:[Dot.ID:Event]]()
            var y = x[b] ?? [Dot.ID:Event]()
            y[d] = e
            x[b] = y
            __mods__[g] = x
        }
    }
    
    // MARK: periodics
    private let _periodic_mutex = __mutex__()
    private var _periodic_boxes = [Box:(Float32,Float64)]() // (period,ellapsed_time)
    func periodic(_ b:Box)->Bool{ return _periodic_mutex.sync{ _periodic_boxes[b] != nil } }
    func add(periodic b:Box,period:Float32){
        _periodic_mutex.sync{ _periodic_boxes[b] = (period,0) }
    }
    func remove(periodic b:Box){
        _periodic_mutex.sync{ _periodic_boxes[b] = nil }
    }
    
    // MARK: the clock
    private var _millisecond_clock_thread, _responder_thread: __thread__?
    private var _tick = false
    private let _interval:Int64 = 100_000// in micro seconds
    private var _clock:__clock__!
    private var max_ms_count = 9
    
    // MARK: filtered recipients
    private let __filtered_recipients_mutex__ = __mutex__()
    private var __filtered_recipients__ = [Box:[Dot.ID:Event]]()
    
    // MARK: iterate
    private func __iterate__(){
        let t = Time.now_s
        let periodics = _periodic_mutex.sync{
            for k in _periodic_boxes.keys{
                // remove dead periodics ..
                if k.__parent__ == nil{ _periodic_boxes[k] = nil }
            }
            return _periodic_boxes
        }
        var mods = [Graph:[Box:[Dot.ID:Event]]]() // changes to outputs
        __mods_mutex__.sync{
            mods = __mods__ // copy
            __mods__.removeAll()
        }
        // collect the recipients for all non-blocked outgoing events
        var recipients = [Box:[Dot.ID:Event]]()
        for (g,mod) in mods{
            for (b,outs) in mod{
                for (d,e) in outs{
                    __find_event_recipients__(g,b,d,e,&recipients)
                }
            }
        }
        // add any filtered recipients for all previously blocked outgoing events
        var frs = [Box:[Dot.ID:Event]]()
        __filtered_recipients_mutex__.sync{
            frs = __filtered_recipients__ // copy
            __filtered_recipients__.removeAll()
        }
        for (b,vs) in frs{
            var ins = recipients[b] ?? [Dot.ID:Event]()
            for (k,v) in vs{
                if ins[k] == nil{ ins[k] = v }
            }
            recipients[b] = ins
        }
        // send all the outgoing events
        let all_dst_boxs = OrderedSet<Box>(periodics.keys).union(recipients.keys)
        for b in all_dst_boxs{
            let es = recipients[b] ?? [Dot.ID:Event]()
            if let (period,last) = periodics[b], t - last >= Float64(period){
                _periodic_mutex.sync{ _periodic_boxes[b] = (period,t) }
                b.received(inputs:es,tick:t)
            }else if !es.isEmpty{
                b.received(inputs:es,tick:nil)
            }
        }
    }
    
    private func __find_event_recipients__(
        _ g:Graph,   // the graph
        _ b:Box,     // the sender
        _ d:String,  // the output index
        _ e:Event,   // the event to send
        _ recipients:inout[Box:[Dot.ID:Event]]){
            for dst in g.arcs.filter({$0.src.boxID == b.id && $0.src.dotID == d}).map({$0.dst}){
                if let b2 = g[dst.boxID]{
                    var ins = recipients[b2] ?? [Dot.ID:Event]()
                    let bm = b2.metadata
                    if !bm.isNIL, let f = filter, let em = e.metadata{
                        f.filter(b.metadata,em,bm){ [weak self] b in
                            if let block = b{
                                //__log__.err("Event blocked: \(block.logMessage)")
                                // TODO: notify the GUI for visual feedback
                            }else if let ME = self{
                                // response may be delayed
                                ME.__filtered_recipients_mutex__.sync{
                                    var ins = ME.__filtered_recipients__[b2] ?? [Dot.ID:Event]()
                                    ins[dst.dotID] = e
                                    ME.__filtered_recipients__[b2] = ins
                                }
                            }
                        }
                    }else{ // no filter or block possible, so just accept ..
                        ins[dst.dotID] = e
                        recipients[b2] = ins
                    }
                }
            }
        }
    
    // MARK: send messages 
    
    func send(msg m:Message,to a:EP.Address,_ cb:@escaping(Message)->(Bool))throws{
        if let ep = eps.first(where:{$0.address.kind == a.kind}){
            try ep.send(msg:m,to:a,cb)
        }
    }
    
    func send(msg m:Message,to a:EP.Address)throws{
        if let ep = eps.first(where:{$0.address.kind == a.kind}){
            try ep.send(msg:m,to:a)
        }
    }
    
    // MARK: Message.Recipient implementation
    
    func __proxy__(uri:EP.Address.URI)->Device.Proxy?{
        if let u = __proxy_uris_by_address_uri__[uri]{ return __proxies_by_uuid__[u] }
        return nil
    }
    
    public func type(ep:EP.Address,box:Device.Box.Name,port:Ports.ID,input:Bool)->T?{
        return __proxy__(uri:ep.uri)?.type(ep:ep,box:box,port:port,input:input)
    }
    
    public func received(_ msg:Message,from ep:EP.Address){
        __log__.warn("Hub : received msg from \(ep.uri) ..")
        if let p = __proxy__(uri: ep.uri){
            __log__.warn(" - found matching proxy: \(p.uuid) ..")
            p.received(msg,from:ep)
        }else{
            __log__.warn("Hub : can't find proxy for \(ep.uri) .., available = ")
            for p in proxies{
                __log__.warn("   * \(p.uuid)")
            }
        }
    }
    
}

    
