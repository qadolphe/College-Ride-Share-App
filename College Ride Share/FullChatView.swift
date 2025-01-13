//
//  FullChatView.swift
//  College Ride Share
//
//  Created by Quentin Adolphe on 1/10/25.
//

import SwiftUI
import StreamChat
import StreamChatUI
import StreamChatSwiftUI

struct ChatView: View {
    @Injected(\.chatClient) var chatClient
    let userIDs: [String]
    
    var body: some View {
        let id = userIDs.joined(separator: "_")
        
        ChatChannelView(
            channelController: chatClient.channelController(
               for: try! ChannelId(type: .messaging, id: id),
                messageOrdering: .topToBottom
            )
        )
    }

}

#Preview {
    ChatView(userIDs: ["user1", "user2", "user3"])
}

