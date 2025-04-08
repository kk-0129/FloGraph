// 𝗙𝗟𝗢 : 𝗗𝗶𝘀𝘁𝗿𝗶𝗯𝘂𝘁𝗲𝗱 𝗛𝗶𝗲𝗿𝗮𝗿𝗰𝗵𝗶𝗰𝗮𝗹 𝗗𝗮𝘁𝗮𝗳𝗹𝗼𝘄 © 𝖪𝖾𝗏𝖾𝗇 𝖪𝖾𝖺𝗋𝗇𝖾𝗒 𝟮𝟬𝟮𝟯
import Foundation
import FloBox

public protocol Filter{
    typealias Block = FilterBlock
    /*
     return a Block object if the event *can not* be sent to the recipient box
     else return nil
     - the result can be asynced
     */
    func filter(
        _ sender_metadata:Struct?,
        _ event_metadata:Struct,
        _ reciever_metadata:Struct,
        _ block:@escaping(Block?)->()
    )
}

public protocol FilterBlock{
    var logMessage:String{get}
}
