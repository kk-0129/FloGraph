// 𝗙𝗟𝗢 : 𝗗𝗶𝘀𝘁𝗿𝗶𝗯𝘂𝘁𝗲𝗱 𝗛𝗶𝗲𝗿𝗮𝗿𝗰𝗵𝗶𝗰𝗮𝗹 𝗗𝗮𝘁𝗮𝗳𝗹𝗼𝘄 © 𝖪𝖾𝗏𝖾𝗇 𝖪𝖾𝖺𝗋𝗇𝖾𝗒 𝟮𝟬𝟮𝟯
import Foundation
import FloBox

// MARK: Slots.DB
public protocol SLOTS_DB{
    var recieved:(([Slot.ID:Slot])->())?{get set}
    func send(_ slots:[Slot.ID:Slot])
}

// MARK: Slots
public typealias Slots = Dictionary<Slot.ID,Slot.Value>
public extension Slots{ typealias DB = SLOTS_DB }
extension Dictionary where Key == Slot.ID, Value == Slot.Value{
    var __slots__:__Slots__{ return mapValues{ Slot($0) } }
    func copy()->Slots{
        return self
    }
    func ™(_ Ω:IO){
        UInt8(count).™(Ω)
        for (k,v) in self{ k.™(Ω); v.™(Ω) }
    }
    static func ™(_ Ω:IO)throws->Self{
        var res = Slots()
        let n = try UInt8.™(Ω)
        for _ in 0..<n{
            let id = try Slot.ID.™(Ω)
            var v:Value!
            switch id{
            case .dps: v = try Device.Proxy.State.™(Ω) // Device.Proxy slots
            case .xy: v = try F2.™(Ω)
            case .rgba: v = try F4.™(Ω)
            case .pov: v = try F3.™(Ω)
            case .boxs: v = try Set<Box>.™(Ω)
            case .arcs: v = try Set<Arc>.™(Ω)
            case .uri: v = try Device.Proxy.UUID.™(Ω)
            case .size: v = try F2.™(Ω)
            case .date: v = try Struct.™(Ω)
            case .on: v = try Bool.™(Ω)
            case .metric: v = try Float32.™(Ω)
            case .name: v = try String.™(Ω)
            case .inputs: v = try Ports.™(Ω)
            case .outputs: v = try Ports.™(Ω)
            case .skins: v = try [Skin].™(Ω) // Device.Proxy slots
            case .pex: v = try ParsedExpr.™(Ω)
            case .pub: v = try Bool.™(Ω)
            case .skin: v = try Skin.™(Ω)
                //
            case .f3a: v = try F3.™(Ω)
            case .f3b: v = try F3.™(Ω)
            case .f3c: v = try F3.™(Ω)
                //
            case .meta: v = try Struct.™(Ω)
            case .histo: v = try [Float32].™(Ω)
            default: fatalError()
            }
            res[id] = v
        }
        return res
    }
}

// MARK: __Slots__
typealias __Slots__ = Dictionary<Slot.ID,Slot>
extension Dictionary where Key == Slot.ID, Value == Slot{
    var slots:Slots{ return self.mapValues({$0.value}) }
    var skin:Skin{
        return Skin("TODO",[:],[:])
    }
}

// MARK: Slot
public struct Slot{
    
    public typealias ID = UInt8
    public typealias Value = SlotValue
    
    public init(_ v:Value){ self.init(v,Time.now_s) }
    init(_ v:Value,_ t:Time.Stamp){ value = v; time = t }
    
    let value:Value
    let time:Time.Stamp
     
}

// MARK: Slot.ID
public extension Slot.ID{
    static let xy  = Slot.ID(0)
    static let rgba = Slot.ID(1)
    static let pov  = Slot.ID(2)
    static let boxs = Slot.ID(3)
    static let arcs = Slot.ID(4)
    static let uri = Slot.ID(5)
    static let size = Slot.ID(6)
    static let date = Slot.ID(7) // for clock
    static let on = Slot.ID(8) // for switches
    static let metric = Slot.ID(9) // for meters
    static let pex = Slot.ID(10) // parsed expression
    static let name = Slot.ID(11)
    static let inputs = Slot.ID(12)
    static let outputs = Slot.ID(13)
    static let skins = Slot.ID(14)
    static let dps = Slot.ID(15) // Device.Proxy.State
    static let pub = Slot.ID(16) // published
    static let skin = Slot.ID(17)
    //
    static let f3a = Slot.ID(18)
    static let f3b = Slot.ID(19)
    static let f3c = Slot.ID(20)
    //
    static let meta = Slot.ID(21)
    static let histo = Slot.ID(22) // array of float for histogram
}

public protocol SlotValue:IO™{}

// MARK: Core types
extension Device.Proxy.State: Slot.Value{}
//extension Box.Proxy.State: Slot.Value{}
protocol ArrayElement:IO™{}
extension Float32:ArrayElement{}
extension Skin:ArrayElement{}
extension Array:Slot.Value where Element:ArrayElement{
    // serialisation already handled by Set:IO™ where Element = IO™ in FLXCore
}
protocol SetElement:IO™{}
extension Box:SetElement{}
extension Arc:SetElement{}
extension Set:Slot.Value where Element:SetElement{
    // serialisation already handled by Set:IO™ where Element = IO™ in FLXCore
}
extension String: Slot.Value{}
extension Struct: Slot.Value{}
extension Bool: Slot.Value{}
extension Float32: Slot.Value{}
extension Ports: Slot.Value{}
extension Skin: Slot.Value{}
//extension Set:Slot.Value where Element == Skin{}
//extension Array:Slot.Value where Element == Float{}
extension ParsedExpr: Slot.Value{}

// MARK: F2
public typealias F2 = SIMD2<Float32>
/* DO NOT ADD @Retroactive !! not compatible with RPi */
extension F2 : IO™,Slot.Value{
    public func ™(_ Ω:IO){ x.™(Ω); y.™(Ω) }
    public var bytes:[UInt8]{ return x.bytes + y.bytes }
    public static func ™(_ bytes:[UInt8])throws->F2{
        return F2(
            try Float32.™([UInt8](bytes[0...3])),
            try Float32.™([UInt8](bytes[4...7]))
        )
    }
    public static func ™(_ Ω:IO)throws->F2{
        return F2(try Float32.™(Ω),try Float32.™(Ω))
    }
}
// MARK: F3
public typealias F3 = SIMD3<Float32>
/* DO NOT ADD @Retroactive !! not compatible with RPi */
extension F3 : IO™,Slot.Value{
    public static let defaultPOV = F3(0,0,1) // IMPORTANT: zom > 0 !!
    public func ™(_ Ω:IO){ x.™(Ω); y.™(Ω); z.™(Ω) }
    public static func ™(_ Ω:IO)throws->F3{
        return F3(try Float32.™(Ω),try Float32.™(Ω),try Float32.™(Ω))
    }
}
// MARK: F4
public typealias F4 = SIMD4<Float32>
/* DO NOT ADD @Retroactive !! not compatible with RPi */
extension F4 : IO™,Slot.Value{
    public static var random:F4{
        return F4(
            Float32.random(in:0...1),
            Float32.random(in:0...1),
            Float32.random(in:0...1),
            1
        )
    }
    public func ™(_ Ω:IO){ x.™(Ω); y.™(Ω); z.™(Ω); w.™(Ω) }
    public static func ™(_ Ω:IO)throws->F4{
        return F4(try Float32.™(Ω),try Float32.™(Ω),try Float32.™(Ω),try Float32.™(Ω))
    }
}

// MARK: Int64
private let _shift64 = [0,8,16,24,32,40,48,56]
/* DO NOT ADD @Retroactive !! not compatible with RPi */
extension Int64:IO™{
    public func ™(_ Ω:IO){
        Ω.write( _shift64.map{ UInt8(truncatingIfNeeded:self>>$0) } )
    }
    public static func ™(_ Ω:IO)throws->Int64{
        var i = -1
        return try Ω.read(8,"Int64").reduce(Int64(0),{ i += 1; return $0 | Int64($1)<<_shift64[i] })
    }
}

// MARK: TIMESTAMP
/* DO NOT ADD @Retroactive !! not compatible with RPi */
extension Float64:IO™{
    public func ™(_ Ω:IO){ bitPattern.™(Ω) }
    public static func ™(_ Ω:IO)throws->Float64{
        Float64(bitPattern:try UInt64.™(Ω))
    }
}
