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

extension Graph:Imp{
    static let skin = Skin("A Box",[:],[:])
    static func configure(_ slots:inout Slots){
        if slots[.pub] == nil{ slots[.pub] = false }
        if slots[.on] == nil{ slots[.on] = true }
        if slots[.pov] == nil{ slots[.pov] = F3(0,0,1) }
        if slots[.rgba] == nil{ slots[.rgba] = F4.random }
        if slots[.boxs] == nil{ slots[.boxs] = Set<Box>() }
        if slots[.arcs] == nil{ slots[.arcs] = Set<Arc>() }
        if slots[.name] == nil{
            slots[.name] = "A Box"
            slots[.inputs] = Ports()
            slots[.outputs] = Ports()
        }
    }
    func received(_ box:Box,_ inputs:[Dot.ID:Event],_ t:Time.Interval?){
        publish(inputs)
    }
}

public class Graph : Frame, Device.Box{
    
    public convenience init(){
        var slots = Slots()
        Graph.configure(&slots)
        self.init(nil,slots)
    }
    override init(_ id:ID?,_ slots:Slots){
        super.init(id,slots)
        inited()
    }
    
    // MARK: as a device box ..
    var path:String{ return parent?.path ?? "" }
    public var callback:(([Ports.ID:Event])->())? // set by device
    public var skin:Skin{ return Skin(path,inputs,outputs) }
    public func publish(_ inputs:[Ports.ID:Event]){
        if let box = parent{
            var ins = inputs
            if let on = ins[Box.on$]?.value as? Bool{
                ins[Box.on$] = nil
                if on != box.on{
                    box.on = on
                    if on{
                        for (k,v) in box.__cached_inputs__{
                            if ins[k] == nil{ ins[k] = v }
                        }
                    }
                }
            }
            if box.on{
                for (d,e) in ins{
                    if let i = boxs.first(where:{$0.kind == .INPUT && $0.name == d}){
                        i.__output_events__[Dot.ANON$] = e
                    }
                }
            }
        }
    }
    
    // MARK: hierarchy
    public var hub:Hub?{ didSet{
        for b in boxs{ b.hub = hub }
        __hub_or_published_state_changed__()
    }}
    private func __hub_or_published_state_changed__(){
        //if let hub = hub{
            // HERE
        //if published{ _ = hub.device.add(box:self) }
        //else{ _ = hub.device.remove(box:self) }
        //}
    }
    var __parent__:Box?
    public var parent:Box?{ return __parent__ }
    public func locate(graph id:Frame.ID)->Graph?{
        if self.id == id{ return self }
        for b in boxs{
            if let g = b.child?.locate(graph:id){ return g }
        }
        return nil
    }
    
    // MARK: vars
    public var pov:F3{
        get{ return self[.pov] as! F3 }
        set(v){ self[.pov] = v }
    }
    public var rgba:F4{
        get{ return self[.rgba] as! F4 }
        set(v){ self[.rgba] = v }
    }
    public var boxs:Set<Box>{
        get{ return self[.boxs] as! Set<Box> }
        set(new){ self[.boxs] = new }
    }
    private var __box_dict__ = [Box.ID:Box]()
    public subscript(_ id:Box.ID)->Box?{ return __box_dict__[id] }
    public var arcs:Set<Arc>{
        get{ return self[.arcs] as! Set<Arc> }
        set(v){ self[.arcs] = v }
    }
    
    // MARK: INPUTS & OUTPUTS
    public var inputs:Ports{ return __ports__(.INPUT) }
    public var outputs:Ports{ return __ports__(.OUTPUT) }
    private func __ports__(_ k:Box.Kind)->Ports{
        var res = Ports()
        if k == .INPUT{ res[Box.on$] = .BOOL() }
        let bs = boxs.filter({$0.kind == k}).sorted(by:{$0.xy.y > $1.xy.y})
        for b in bs{
             res[b.name] = (k == .INPUT) ? b.outputs[Dot.ANON$] : b.inputs[Dot.ANON$]
        }
        return res
    }
    
    // MARK: IO
    public func ™(_ Ω:IO){
        id.™(Ω)
        slots.slots.™(Ω) // serialised without the time-stamps!
    }
    public static func ™(_ Ω:IO)throws->Graph{
        return Graph(try ID.™(Ω),try Slots.™(Ω))
    }
    
    // MARK: frame slots validation
    // = BEFORE the slot value changes
    override func __will_change_slot_value__(_ id:Slot.ID,_ old:Slot.Value?,_ new:Slot.Value){
        switch id{
        case .boxs:
            let old = (old as? Set<Box>) ?? Set<Box>()
            let new = (new as? Set<Box>) ?? Set<Box>()
            // this resolves any IO name conflicts ...
            let added = new.subtracting(old)
            var existing = new.intersection(old)
            for a in added.filter({$0.kind == .INPUT || $0.kind == .OUTPUT}){
                let n = a.name
                var i = 1
                var m = n
                while existing.contains(where:{$0.kind==a.kind && $0.name==m}){
                    m = n + "\(i)"
                    i += 1
                }
                if m != n{ a.name = m }
                existing.insert(a)
            }
            var io_changed = false
            for b in old.subtracting(new){
                __box_dict__[b.id] = nil
                b.__parent__ = nil
                io_changed = io_changed || b.kind == .INPUT || b.kind == .OUTPUT
            }
            for b in added{
                __box_dict__[b.id] = b
                b.__parent__ = self
                io_changed = io_changed || b.kind == .INPUT || b.kind == .OUTPUT
            }
            if io_changed{
                super.__notify_observers__(.skin)
            }
        case .arcs:
            let old = (old as? Set<Arc>) ?? Set<Arc>()
            let new = (new as? Set<Arc>) ?? Set<Arc>()
            for a in old.subtracting(new){
                if let b = self[a.src.boxID],let i = b.imp as? PROXY_IMP{
                    i.notify(arc:a,added:false)
                }
            }
            for a in new.subtracting(old){
                if let b = self[a.src.boxID]{ // arc = output of b
                    if let i = b.imp as? PROXY_IMP{
                        i.notify(arc:a,added:true)
                    }
                    if let e = b.fire(a.src.dotID){ // fire failed, so ..
                        if let b = self[a.dst.boxID]{
                            // send it directly ..
                            b.received(inputs:[a.dst.dotID:e],tick:nil)
                        }
                    }
                }
            }
        default: break
        }
    }
    // = AFTER the slot value changes
    func didChange(_ box:Box,_ id:Slot.ID){
        super.__notify_observers__(id)
        switch id{
        case .rgba: parent?.__Q_notify_observers__(id)
        case .pub: __hub_or_published_state_changed__()
        case .name: __notify_observers__(.skin)
        default: break
        }
    }
    
    // MARK: DEEP COPY
    public func copy()->Graph{
        return Graph(nil,slots.slots)
    }
    
    // MARK: PUBLISHING AS A DEVICE BOX
    public var publishable:Bool{
        // HERE
        return false//hub?.device.publishable(box:self) ?? false
    }
    public var published:Bool{
        get{ return self[.pub] as! Bool }
        set(v){ if !v || publishable{ self[.pub] = v } }
    }
    
}
