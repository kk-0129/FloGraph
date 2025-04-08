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

// MARK: Frame.Observer
public protocol FrameObserver : AnyObject{
    func observed(_ f:Frame,_ slots:[Slot.ID])
}
public extension Array where Element == FrameObserver{
    mutating func add(_ l:FrameObserver){
        if firstIndex(where:{$0===l})==nil{ append(l) }
    }
    mutating func rem(_ l:FrameObserver){
        if let i = firstIndex(where:{$0===l}){ remove(at:i) }
    }
}

public class Frame: Hashable,Equatable{
    
    public typealias ID = Int64
    public typealias Observer = FrameObserver
    
    init(_ id:ID?,_ slots:Slots){
        self.id = id ?? Time.now_n
        self.__slots__ = slots.__slots__
    }
    func inited(){
        var arcs:Slot.Value?
        for (k,v) in slots{
            if k == .arcs{ arcs = v.value }
            else{ __will_change_slot_value__(k,nil,v.value) }
        }
        if let v = arcs{ __will_change_slot_value__(.arcs,nil,v) }
    }
    
    public var db:Slots.DB?{ didSet{
        if var old = oldValue{ old.recieved = nil }
        db?.recieved = __received__
    }}
    private func __received__(_ slots:[Slot.ID:Slot]){
        for (k,v) in slots{ __mx__.sync{
            if v.time > (__slots__[k]?.time ?? 0){ __slots__[k] = v }
        }}
    }
    
    public let id:ID
    var slots:__Slots__{ return __mx__.sync{ __slots__ } }
    private var __slots__ = __Slots__()
    private let __mx__ = __mutex__()
    public var ids:[Slot.ID]{
        return __mx__.sync{ [Slot.ID](__slots__.keys) }
    }
    public func has(_ id:Slot.ID)->Bool{
        return __mx__.sync{ __slots__[id] != nil }
    }
    private let Q = DispatchQueue.global(qos:.userInteractive)
    public subscript(_ id:Slot.ID)->Slot.Value{
        get{
            return __mx__.sync{ __slots__[id]!.value }
        }
        set(v){
            let old = __mx__.sync{ __slots__[id] }
            __will_change_slot_value__(id,old?.value,v)
            __mx__.sync{ __slots__[id] = Slot(v) }
            __did_change_slot_value__(id)
            __Q_notify_observers__(id)
            db?.send([id:Slot(v)])
        }
    }
    
    // MARK: Frame.Observer
    public var observers = [Observer]()
    func __will_change_slot_value__(_ id:Slot.ID,_ old:Slot.Value?,_ new:Slot.Value){}
    func __did_change_slot_value__(_ id:Slot.ID){}
    func __Q_notify_observers__(_ id:Slot.ID){
        Q.async { DispatchQueue.main.async{ self.__notify_observers__(id) } }
    }
    func __notify_observers__(_ id:Slot.ID){ for o in observers{ o.observed(self,[id]) } }
    
    // MARK: Hash
    public func hash(into h:inout Hasher){ h.combine(id) }
    public static func ==(a:Frame,b:Frame)->Bool{ return a.id == b.id }
    
}
