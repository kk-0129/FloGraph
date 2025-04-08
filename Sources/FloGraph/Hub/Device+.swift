// 𝗙𝗟𝗢 : 𝗗𝗶𝘀𝘁𝗿𝗶𝗯𝘂𝘁𝗲𝗱 𝗛𝗶𝗲𝗿𝗮𝗿𝗰𝗵𝗶𝗰𝗮𝗹 𝗗𝗮𝘁𝗮𝗳𝗹𝗼𝘄 © 𝖪𝖾𝗏𝖾𝗇 𝖪𝖾𝖺𝗋𝗇𝖾𝗒 𝟮𝟬𝟮𝟯
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
