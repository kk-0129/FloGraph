// 𝗙𝗟𝗢 : 𝗗𝗶𝘀𝘁𝗿𝗶𝗯𝘂𝘁𝗲𝗱 𝗛𝗶𝗲𝗿𝗮𝗿𝗰𝗵𝗶𝗰𝗮𝗹 𝗗𝗮𝘁𝗮𝗳𝗹𝗼𝘄 © 𝖪𝖾𝗏𝖾𝗇 𝖪𝖾𝖺𝗋𝗇𝖾𝗒 𝟮𝟬𝟮𝟯
import Foundation
import FloBox

public extension Box{
    
    enum Kind:UInt8{
        case GRAPH = 0
        case ANNOT = 1
        case CLOCK = 2
        case EXPR = 3
        case METER = 4
        case SWITCH = 5
        case TEXT = 6
        case PROXY = 7
        case INPUT = 8
        case OUTPUT = 9
        case IMU = 10
        case HISTO = 11
    }
    
    enum Keys{
        // meter & switch params
        public static let min$ = "min"
        public static let max$ = "max"
        public static let step$ = "step"
        public static let rate$ = "rate"
        // Date struct
        public static let Date$ = "Date"
        public static let year$ = "year"
        public static let month$ = "month"
        public static let day$ = "day"
        public static let hour$ = "hour"
        //public static let min$ = "min"
        public static let sec$ = "sec"
    }
    
}

protocol Imp{
    static func configure(_ slots:inout Slots)
    func received(_ box:Box,_ inputs:[Dot.ID:Event],_ t:Time.Interval?)
    func willChange(_ box:Box,_ id:Slot.ID,_ old:Slot.Value?,_ new:Slot.Value)
    func didChange(_ box:Box,_ id:Slot.ID)
}

extension Imp{
    func didChange(_ box:Box,_ id:Slot.ID){}
    func willChange(_ box:Box,_ id:Slot.ID,_ old:Slot.Value?,_ new:Slot.Value){}
    func received(_ box:Box,_ inputs:[Dot.ID:Event],_ t:Time.Interval?){}
}

enum IMP{
    
    static func __meter_or_switch_update_periodic__(_ b:Box,_ inputs:Ports? = nil){
        if let hub = b.hub{
            let ps = inputs ?? b.params
            if let f = ps[Box.Keys.rate$]?.dv as? Float32{
                // MUST BE THE PARAMS THAT CHANGED + we're only interested in rate here!
                if f == 0{ hub.remove(periodic:b) }
                else{ hub.add(periodic:b,period:abs(f)) }
            }
        }
    }
    
    static func __IO_validate_name__(_ b:Box,_ old:String?,_ new:String,_ input:Bool){
        if let p = b.__parent__?.parent, let g = p.__parent__{ // g = grandparent !!
            let old_arcs = g.arcs.filter({ // the arcs that feed/exit this I/O
                input ?
                $0.dst.boxID == p.id && $0.dst.dotID == old
                : $0.src.boxID == p.id && $0.src.dotID == old
            })
            g.arcs.subtract(old_arcs) // & delete them !
            let new_arcs = old_arcs.map{ // create new arcs to the new name
                input ?
                    Arc($0.src,Dot(input:p.id,new)) :
                    Arc(Dot(output:p.id,new),$0.dst)
            }
            g.arcs.formUnion(new_arcs) // & add them
        }
    }
    
}

// MARK: ANNOT
public extension Box{
    var size:F2{
        get{ return self[.size] as! F2 }
        set(s){ self[.size] = s }
    }
}
struct ANNOT_IMP:Imp{
    static func configure(_ slots:inout Slots){
        if slots[.size] == nil{ slots[.size] = F2(200,200) }
        if slots[.name] == nil{
            slots[.name] = "Annotation"
            slots[.inputs] = Ports()
            slots[.outputs] = Ports()
        }
    }
}

// MARK: CLOCK
public extension Box{
    var datetime:Struct{
        get{ return self[.date] as! Struct }
        set(d){ if d.t == DATE{ self[.date] = d } }
    }
}
struct CLOCK_IMP:Imp{
    static func configure(_ slots:inout Slots){
        if slots[.date] == nil{ slots[.date] = NOW }
        if slots[.name] == nil{
            slots[.name] = ""
            slots[.inputs] = Ports.from([Dot.ANON$:DATE])
            slots[.outputs] = Ports.from([Dot.ANON$:DATE])
        }
    }
    func willChange(_ box:Box,_ id:Slot.ID,_ old:Slot.Value?,_ new:Slot.Value){
        switch id{
        case .date: if let v = new as? Struct{ box.__output_events__[Dot.ANON$] = Event(v) }
        default: break
        }
    }
    func update_periodic(_ box:Box,_ inputs:Ports? = nil){
        box.hub?.add(periodic:box,period:1)
    }
    func received(_ box:Box,_ inputs:[Dot.ID:Event],_ t:Time.Interval?){
        if t != nil{ box[.date] = NOW }
        else if let t = inputs[Dot.ANON$]?.value as? Struct{ box[.date] = t }
    }
}
private let DATE = Struct.type(named:Box.Keys.Date$)!
private let cal = Calendar(identifier:.gregorian)
var NOW:Struct{
    let d = Date()
    return DATE.instance([
        Box.Keys.year$:Float32(cal.component(.year,from:d)),
        Box.Keys.month$:Float32(cal.component(.month,from:d)-1),
        Box.Keys.day$:Float32(cal.component(.day,from:d)),
        Box.Keys.hour$:Float32(cal.component(.hour,from:d)),
        Box.Keys.min$:Float32(cal.component(.minute,from:d)),
        Box.Keys.sec$:Float32(cal.component(.second,from:d))
    ])!
}

// MARK: EXPR
private let x_VAR = "x"
private let x_TYPE = T.BOOL()
private let DEFAULT_EXPR = ParsedExpr("x:B",.VAR(x_VAR,x_TYPE))

struct EXPR_IMP:Imp{
    static func configure(_ slots:inout Slots){
        if slots[.pex] == nil{ slots[.pex] = DEFAULT_EXPR }
        if slots[.name] == nil{
            slots[.name] = DEFAULT_EXPR.text
            slots[.inputs] = Ports.from([x_VAR:x_TYPE])
            slots[.outputs] = Ports.from([Dot.ANON$:DATE])
        }
    }
    func willChange(_ box:Box,_ id:Slot.ID,_ old:Slot.Value?,_ new:Slot.Value){
        switch id{
        case .pex: // pex = parsed expression
            if !(box.incomingArcs.isEmpty && box.outgoingArcs.isEmpty){
                fatalError()
            }
        default: break
        }
    }
    func didChange(_ box:Box,_ id:Slot.ID){
        switch id{
        case .pex: // pex = parsed expression
            var vars = [String:any Event.Value]()
            let res = box.pex.expr.evaluate(&vars)
            for i in 0..<res.count{
                box.__output_events__[Expr.out$(i)] = Event(res[i])
            }
        default: break
        }
    }
    func received(_ box:Box,_ inputs:[Dot.ID:Event],_ t:Time.Interval?){
        var vars = [String:any Event.Value]()
        for (k,v) in box.__cached_inputs__{ vars[k] = v.value }
        for (k,v) in inputs{ vars[k] = v.value }
        let res = box.pex.expr.evaluate(&vars)
        for i in 0..<res.count{
            box.__output_events__[Expr.out$(i)] = Event(res[i])
        }
    }
}

public extension Box{
    // this sett(pex: supports UNDO
    func set(pex:ParsedExpr)->Set<Arc>{ // deleted arcs
        let old_pex = self.pex
        let old_arc_ins = incomingArcs
        let old_arc_outs = outgoingArcs
        let old_pex_ins = old_pex.expr.vars
        let old_pex_outs = old_pex.expr.outs
        let new_pex_ins = pex.expr.vars
        let new_pex_outs = pex.expr.outs
        var deleted_arcs = Set<Arc>()
        var valid_arcs = Set<Arc>()
        for a in incomingArcs{
            let t1 = old_pex_ins[a.dst.dotID]! // must exist
            if let t2 = new_pex_ins[a.dst.dotID],t1==t2{ valid_arcs.insert(a) }
            else{ deleted_arcs.insert(a) }
        }
        for a in old_arc_outs{
            let t1 = old_pex_outs[a.src.dotID]! // must exist
            if let t2 = new_pex_outs[a.src.dotID],t1==t2{ valid_arcs.insert(a) }
            else{ deleted_arcs.insert(a) }
        }
        __parent__?.arcs.subtract(old_arc_ins) // delete ALL old arcs
        __parent__?.arcs.subtract(old_arc_outs) // delete ALL old arcs
        self[.pex] = pex
        __parent__?.arcs.formUnion(valid_arcs) // add the valid ones
        return deleted_arcs
    }
    var pex:ParsedExpr{ return self[.pex] as! ParsedExpr }
}

// MARK: HISTOGRAM
public extension Box{
    var histo:[Float32]{
        get{ return self[.histo] as! [Float32] }
        set(fs){ if fs != histo{ self[.histo] = fs } }
    }
}
struct HISTO_IMP:Imp{
    static func configure(_ slots:inout Slots){
        if slots[.histo] == nil{ slots[.histo] = [Float32]() }
        if slots[.name] == nil{
            slots[.name] = ""
            slots[.inputs] = Ports.from([Dot.ANON$:.ARRAY(.FLOAT())])
            slots[.outputs] = Ports.from([Dot.ANON$:.ARRAY(.FLOAT())])
        }
    }
    func willChange(_ box:Box,_ id:Slot.ID,_ old:Slot.Value?,_ new:Slot.Value){
        switch id{
        case .histo: if let v = new as? [Float32]{ box.__output_events__[Dot.ANON$] = Event(v) }
        default: break
        }
    }
    func received(_ box:Box,_ inputs:[Dot.ID:Event],_ t:Time.Interval?){
        let inp = (inputs[Dot.ANON$] ?? box.__cached_inputs__[Dot.ANON$])?.value as? [Float32]
        var f = box.histo // previous value
        if let i = inp{ f = i } // follow the input
        box.histo = f
    }
}

// MARK: IMU
public extension Box{
    var euler:F3{
        get{ return self[.f3a] as! F3 }
        set(f){ if f != euler{ self[.f3a] = f } }
    }
}
struct IMU_IMP:Imp{
    static func configure(_ slots:inout Slots){
        if slots[.f3a] == nil{ slots[.f3a] = F3(0,0,0) }
        if slots[.name] == nil{
            slots[.name] = ""
            slots[.inputs] = Ports.from([Dot.ANON$:EULER])
            slots[.outputs] = Ports.from([Dot.ANON$:EULER])
        }
    }
    func willChange(_ box:Box,_ id:Slot.ID,_ old:Slot.Value?,_ new:Slot.Value){
        switch id{
        case .f3a: if let v = new as? F3{
            let e = EULER.instance(["pitch":v.x,"yaw":v.y,"roll":v.z])
            box.__output_events__[Dot.ANON$] = Event(e)
        }
        default: break
        }
    }
    func received(_ box:Box,_ inputs:[Dot.ID:Event],_ t:Time.Interval?){
        //
        if let s = inputs[Dot.ANON$]?.value as? Struct,
            s.isa(EULER),
           let x = s["pitch"] as? Float32,
           let y = s["yaw"] as? Float32,
           let z = s["roll"] as? Float32{
            box.euler = F3(x,y,z)
        }
    }
}

// MARK: INPUT
struct INPUT_IMP:Imp{
    static func configure(_ slots:inout Slots){
        if slots[.name] == nil{
            slots[.name] = "Input"
            slots[.inputs] = Ports()
            slots[.outputs] = Ports.from([Dot.ANON$:.BOOL()])
        }
    }
    func willChange(_ box:Box,_ id:Slot.ID,_ old:Slot.Value?,_ new:Slot.Value){
        if id == .name{ IMP.__IO_validate_name__(box,old as? String,new as! String,true) }
    }
    func received(_ box:Box,_ inputs:[Dot.ID:Event],_ t:Time.Interval?){}
}

// MARK: METER
public extension Box{
    var metric:Float32{
        get{ return self[.metric] as! Float32 }
        set(f){ if f != metric{ self[.metric] = f } }
    }
}
struct METER_IMP:Imp{
    static func configure(_ slots:inout Slots){
        if slots[.metric] == nil{ slots[.metric] = Float32(0) }
        if slots[.name] == nil{
            slots[.name] = ""
            slots[.inputs] = Ports.from([Dot.ANON$:.FLOAT(),
                                         Box.Keys.min$:.FLOAT(-1),
                                         Box.Keys.step$:.FLOAT(0),
                                         Box.Keys.max$:.FLOAT(1),
                                         Box.Keys.rate$:.FLOAT(0)])
            slots[.outputs] = Ports.from([Dot.ANON$:.FLOAT()])
        }
    }
    func willChange(_ box:Box,_ id:Slot.ID,_ old:Slot.Value?,_ new:Slot.Value){
        switch id{
        case .inputs: update_periodic(box,(new as! Ports))
        case .metric: if let v = new as? Float32{ box.__output_events__[Dot.ANON$] = Event(v) }
        default: break
        }
    }
    func update_periodic(_ box:Box,_ inputs:Ports? = nil){
        IMP.__meter_or_switch_update_periodic__(box,inputs)
    }
    func received(_ box:Box,_ inputs:[Dot.ID:Event],_ t:Time.Interval?){
        let ps = box.params
        let _lo = ps[Box.Keys.min$]!.dv as! Float32
        let step = ps[Box.Keys.step$]!.dv as! Float32
        let _hi = ps[Box.Keys.max$]!.dv as! Float32
        let rt = ps[Box.Keys.rate$]!.dv as! Float32
        let lo = min(_lo,_hi)
        let hi = max(_lo,_hi)
        let inp = (inputs[Dot.ANON$] ?? box.__cached_inputs__[Dot.ANON$])?.value as? Float32
        var f = box.metric // previous value
        if rt != 0{
            if t != nil{
                if rt > 0{
                    if step == 0{ // move towards input
                        if let i = inp{
                            f = (f + ((i - f) * 0.05)).clip(lo,hi)
                        }
                    }else{ f += step } // periodically increase by 'step'
                }else{ f = Float32.random(in:lo...hi) } // -ve rate --> random output
            }
        }else if let i = inp{ f = i } // follow the input
        if step != 0{
            f = lo + (step * round((f - lo) / step))
            if f < lo{ f = hi }else if f > hi{ f = lo }
        }else{ f = min( max(f, lo), hi ) }
        box.metric = f
    }
}

// MARK: OUTPUT
struct OUTPUT_IMP:Imp{
    static func configure(_ slots:inout Slots){
        if slots[.name] == nil{
            slots[.name] = "Output"
            slots[.inputs] = Ports.from([Dot.ANON$:.BOOL()])
            slots[.outputs] = Ports()
        }
    }
    func willChange(_ box:Box,_ id:Slot.ID,_ old:Slot.Value?,_ new:Slot.Value){
        if id == .name{ IMP.__IO_validate_name__(box,old as? String,new as! String,false) }
    }
    func received(_ box:Box,_ inputs:[Dot.ID:Event],_ t:Time.Interval?){
        if let g = box.__parent__, let x = g.parent, let e = inputs[Dot.ANON$]{
            x.__output_events__[box.name] = e
            if let cb = g.callback{ cb([box.name:e]) }
        }
    }
}

// MARK: SWITCH
struct SWITCH_IMP:Imp{
    static func configure(_ slots:inout Slots){
        if slots[.on] == nil{ slots[.on] = false }
        if slots[.name] == nil{
            slots[.name] = ""
            slots[.inputs] = Ports.from([Dot.ANON$:.BOOL(),
                                         Box.Keys.rate$:.FLOAT(0)])
            slots[.outputs] = Ports.from([Dot.ANON$:.BOOL()])
        }
    }
    func update_periodic(_ box:Box,_ inputs:Ports? = nil){
        IMP.__meter_or_switch_update_periodic__(box,inputs)
    }
    func willChange(_ box:Box,_ id:Slot.ID,_ old:Slot.Value?,_ new:Slot.Value){
        switch id{
        case .inputs: update_periodic(box,(new as! Ports))
        case .on: if let v = new as? Bool{ box.__output_events__[Dot.ANON$] = Event(v) }
        default: break
        }
    }
    func received(_ box:Box,_ inputs:[Dot.ID:Event],_ t:Time.Interval?){
        box.on = t != nil ? !box.on : (inputs[Dot.ANON$]?.value as? Bool) ?? false
    }
}

// MARK: TEXT
struct TEXT_IMP:Imp{
    static func configure(_ slots:inout Slots){
        if slots[.name] == nil{
            slots[.name] = "Text"
            slots[.inputs] = Ports.from([Dot.ANON$:.STRING()])
            slots[.outputs] = Ports.from([Dot.ANON$:.STRING()])
        }
    }
    func willChange(_ box:Box,_ id:Slot.ID,_ old:Slot.Value?,_ new:Slot.Value){
        switch id{
        case .name: if let v = new as? String{ box.__output_events__[Dot.ANON$] = Event(v) }
        default: break
        }
    }
    func received(_ box:Box,_ inputs:[Dot.ID:Event],_ t:Time.Interval?){
        box.name = (inputs[Dot.ANON$]?.value as? String) ?? "?"
    }
}


