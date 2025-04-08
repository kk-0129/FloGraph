// 𝗙𝗟𝗢 : 𝗗𝗶𝘀𝘁𝗿𝗶𝗯𝘂𝘁𝗲𝗱 𝗛𝗶𝗲𝗿𝗮𝗿𝗰𝗵𝗶𝗰𝗮𝗹 𝗗𝗮𝘁𝗮𝗳𝗹𝗼𝘄 © 𝖪𝖾𝗏𝖾𝗇 𝖪𝖾𝖺𝗋𝗇𝖾𝗒 𝟮𝟬𝟮𝟯
import Foundation
import FloBox

// MARK: IMPLEMENTATION
public final class Box:Frame,IO™{
    
    public convenience init(_ k:Kind){ self.init(nil,k,Slots(),nil) }
    public convenience init(proxy uuid:String,_ skin:Skin,_ slots:Slots){
        var s = slots
        s[.uri] = uuid
        s[.name] = skin.name
        s[.inputs] = skin.inputs
        s[.outputs] = skin.outputs
        s[.meta] = skin.metadata
        self.init(nil,.PROXY,s,nil)
    }
    public convenience init(_ k:Kind,_ slots:Slots){
        let g = k == .GRAPH ? Graph() : nil
        self.init(nil,k,slots,g)
    }
    init(_ id:ID?,_ kind:Kind,_ slots:Slots,_ g:Graph?){
        guard (kind == .GRAPH && g != nil) || (kind != .GRAPH && g == nil) else{ fatalError() }
        self.kind = kind
        var slots = slots
        // configure the slots ..
        switch kind{
        case .GRAPH,.PROXY,.INPUT,.OUTPUT:
            if slots[.rgba] == nil{ slots[.rgba] = F4.random }
            fallthrough
        default:
            if slots[.meta] == nil{ slots[.meta] = NIL.instance()! }
            if slots[.xy] == nil{ slots[.xy] = F2(0,0) }
        }
        switch kind{
        case .GRAPH: Graph.configure(&slots)
        case .ANNOT: ANNOT_IMP.configure(&slots)
        case .CLOCK: CLOCK_IMP.configure(&slots)
        case .EXPR: EXPR_IMP.configure(&slots)
        case .METER: METER_IMP.configure(&slots)
        case .SWITCH: SWITCH_IMP.configure(&slots)
        case .TEXT: TEXT_IMP.configure(&slots)
        case .PROXY: PROXY_IMP.configure(&slots)
        case .INPUT: INPUT_IMP.configure(&slots)
        case .OUTPUT: OUTPUT_IMP.configure(&slots)
        case .IMU: IMU_IMP.configure(&slots)
        case .HISTO: HISTO_IMP.configure(&slots)
        }
        //
        super.init(id,slots)
        // set the implementation ..
        switch kind{
        case .GRAPH: imp = g
        case .ANNOT: imp = ANNOT_IMP()
        case .CLOCK: imp = CLOCK_IMP()
        case .EXPR: imp = EXPR_IMP()
        case .METER: imp = METER_IMP()
        case .SWITCH: imp = SWITCH_IMP()
        case .TEXT: imp = TEXT_IMP()
        case .PROXY: imp = PROXY_IMP(self)
        case .INPUT: imp = INPUT_IMP()
        case .OUTPUT: imp = OUTPUT_IMP()
        case .IMU: imp = IMU_IMP()
        case .HISTO: imp = HISTO_IMP()
        }
        inited()
        g?.__parent__ = self
        imp.didChange(self,.pex) // invoke once at start
    }
    
    // MARK: VARS
    var imp:Imp!
    public let kind:Kind
    
    // MARK: hierarchy
    public var hub:Hub?{ didSet{
        hub?.remove(periodic:self)
        child?.hub = hub
        switch kind{
        case .PROXY: (imp as! PROXY_IMP).hub_changed()
        case .CLOCK: (imp as! CLOCK_IMP).update_periodic(self)
        case .METER: (imp as! METER_IMP).update_periodic(self)
        case .SWITCH: (imp as! SWITCH_IMP).update_periodic(self)
        default: break
        }
    }}
    var __parent__:Graph?{ didSet{ hub = __parent__?.hub }}
    public var parent:Graph{ return __parent__! }
    public var child:Graph?{ return imp as? Graph }
    
    // MARK: EVENTS
    var __cached_inputs__ = [Dot.ID:Event]()
    override func __will_change_slot_value__(_ id:Slot.ID,_ old:Slot.Value?,_ new:Slot.Value){
        imp.willChange(self,id,old,new)
    }
    override func __did_change_slot_value__(_ id:Slot.ID){
        imp.didChange(self,id)
        switch id{
        case .name:
            if let g = imp as? Graph{ g.__notify_observers__(.skin) }
        default: break
        }
    }
    
    internal var __output_events__ = [Dot.ID:Event](){ didSet{
        for k in __output_events__.keys{
            let new = __output_events__[k]
            if let new = new, !new.equals(oldValue[k]){
                _ = fire(k)
            }
        }
    }}
    func fire(_ d:Dot.ID)->Event?{
        if let e = __output_events__[d]{
            if let g = __parent__,let h = g.hub{
                h.notify(output:e,d:d,of:self,in:g)
            }else{
                return e
            }
        }
        return nil
    }
    
    // MARK: IO
    public func ™(_ Ω:IO){
        id.™(Ω)
        kind.rawValue.™(Ω)
        slots.slots.™(Ω) // serialised without the time-stamps! 
        if let c = child{ c.™(Ω) }
    }
    public static func ™(_ Ω:IO)throws->Box{
        let id = try ID.™(Ω)
        let i = try UInt8.™(Ω)
        let k = Kind(rawValue:i)!
        return Box(id,k,try Slots.™(Ω),k == .GRAPH ? try Graph.™(Ω) : nil)
    }
    
    // MARK: DEEP COPY
    func copy(_ idmap:inout[Box.ID:Box])->Box{
        let b = Box(nil,kind,slots.slots,child?.copy())
        idmap[id] = b
        return b
    }
    
    // MARK: RECEIVED EVENTS
    func received(inputs:[Dot.ID:Event],tick t:Time.Interval?){
        imp.received(self,inputs,t)
        for (k,v) in inputs{ __cached_inputs__[k] = v }
    }
    
}

public extension Box{
    
    static let on$ = "Ø"
    
    // MARK: BOX SLOTS
    var skin:Skin{
        get{ return Skin(name,inputs,outputs,meta:metadata) }
        set(x){ if x != skin{
            name = x.name
            inputs = x.inputs
            outputs = x.outputs
            metadata = x.metadata
        } }
    }
    var path:String{ return (__parent__?.path ?? "") + "/" + name }
    var name:String{
        get{
            switch kind{
            case .EXPR: return pex.text
            default: return self[.name] as! String
            }
        }
        set(n){
            switch kind{
            case .EXPR: break // change the PEX instead
            default: if n != name{ self[.name] = n }
            }
        }
    }
    var xy:F2{
        get{ return self[.xy] as! F2 }
        set(v){ self[.xy] = v }
    }
    var rgba:F4{
        get{ return child?.rgba ?? self[.rgba] as! F4 }
        set(v){
            if let c = child{
                c[.rgba] = v
                __notify_observers__(.rgba)
            }else{ self[.rgba] = v }
        }
    }
    var on:Bool{ // SWITCH & GRAPH
        get{ return self[.on] as! Bool }
        set(b){ self[.on] = b }
    }
    var inputs:Ports{
        get{
            switch kind{
            case .GRAPH: return child!.inputs
            case .EXPR: return pex.expr.vars
            default: return self[.inputs] as! Ports
            }
        }
        set(p){
            switch kind{
            case .GRAPH: break // add input boxes instead
            case .EXPR: break // change the PEX instead
            default: self[.inputs] = p
            }
        }
    }
    var params:Ports{
        get { return (self[.inputs] as! Ports).filter({$0.value.dv != nil}) }
        set(v){
            var new = self[.inputs] as! Ports
            for (n,t) in v{ new[n] = t }
            self[.inputs] = new
        }
    }
    var outputs:Ports{
        get{
            switch kind{
            case .GRAPH: return child!.outputs
            case .EXPR: return pex.expr.outs
            default: return self[.outputs] as! Ports
            }
        }
        set(p){
            switch kind{
            case .GRAPH: break // add input boxes instead
            case .EXPR: break // change the epxr instead
            default: self[.outputs] = p
            }
        }
    }
    var metadata:Struct{
        get{ return self[.meta] as! Struct }
        set(p){ self[.meta] = p }
    }
    
    // MARK: HELPER
    var incomingArcs:Set<Arc>{
        return __parent__?.arcs.filter({$0.dst.boxID == self.id}) ?? Set<Arc>()
    }
    var outgoingArcs:Set<Arc>{ 
        return __parent__?.arcs.filter({$0.src.boxID == self.id}) ?? Set<Arc>()
    }
    
}

public extension Set where Element == Box{
    func copy(_ idmap:inout[Box.ID:Box])->Set<Box>{
        return Set<Box>(map{ $0.copy(&idmap) })
    }
}
