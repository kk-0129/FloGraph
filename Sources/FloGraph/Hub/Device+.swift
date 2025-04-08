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

class DEV : Device, Frame.Observer{
    override func add(box:Device.Box)->Bool{
        let b = super.add(box:box)
        if b, let g = box as? Graph{ g.observers.add(self) }
        return b
    }
    override func remove(box:Device.Box)->Bool{
        let b = super.remove(box:box)
        if b, let g = box as? Graph{ g.observers.rem(self) }
        return b
    }
    func observed(_ f: Frame,_ slots:[Slot.ID]){
        for id in slots{
            if id == .skin{ updateClients() }
        }
    }
}

/*
 FAKE EPs that just connect directly to each other
 */
struct LOCAL_ADDR:EP.Address{
    static let kind = "LA"
    let uri:String
}
class DEV_EP:EP{
    let address:Address = LOCAL_ADDR(uri:Hub.Local$)
    var hub:HUB_EP?
    var recipient:Message.Recipient?
    func send(msg:Message,to:Address,_ cb:@escaping(Message)->(Bool))throws{
        fatalError("never used")
    }
    func send(msg:FloBox.Message,to:Address)throws{
        hub?.received(reply:msg,from:address)
    }
}
class HUB_EP:EP.Base{
    var dev:DEV_EP
    init(_ dev:DEV_EP){
        self.dev = dev
        super.init(LOCAL_ADDR(uri:"HUB"))
        dev.hub = self
    }
    override func send(msg:Message,to:Address)throws{
        dev.recipient?.received(msg,from:address)
    }
}
