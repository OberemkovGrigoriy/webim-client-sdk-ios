//
//  ChatItem.swift
//  WebimClientLibrary
//
//  Created by Nikita Lazarev-Zubov on 09.08.17.
//  Copyright © 2017 Webim. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import Foundation

/**
 Class that encapsulates chat data.
 - Author:
 Nikita Lazarev-Zubov
 - Copyright:
 2017 Webim
 */
final class ChatItem {
    
    // MARK: - Constants
    
    // Raw values equal to field names received in responses from server.
    private enum JSONField: String {
        case CATEGORY = "category"
        case CLIENT_SIDE_ID = "clientSideId"
        case CREATION_TIMESTAMP = "creationTs"
        case ID = "id"
        case MESSAGES = "messages"
        case MODIFICATION_TIMESTAMP = "modificationTs"
        case OFFLINE = "offline"
        case OPERATOR = "operator"
        case OPERATOR_ID_TO_RATE = "operatorIdToRate"
        case OPERATOR_TYPING = "operatorTyping"
        case READ_BY_VISITOR = "readByVisitor"
        case STATE = "state"
        case SUBCATEGORY = "subcategory"
        case SUBJECT = "subject"
        case UNREAD_BY_OPERATOR_TIMESTAMP = "unreadByOperatorSinceTs"
        case UNREAD_BY_VISITOR_TIMESTAMP = "unreadByVisitorSinceTs"
        case VISITOR_TYPING = "visitorTyping"
    }
    
    enum ChatItemState: String {
        
        case UNKNOWN = "unknown"
        case QUEUE = "queue"
        case CHATTING = "chatting"
        case CLOSED = "closed"
        case CLOSED_BY_VISITOR = "closed_by_visitor"
        case CLOSED_BY_OPERATOR = "closed_by_operator"
        case INVITATION = "invitation"
        
        // MARK: - Initialization
        init(withType typeValue: String) {
            self = ChatItemState(rawValue: typeValue)!
        }
        
        
        // MARK: - Methods
        func isClosed() -> Bool {
            return (((self == .CLOSED)
                || (self == .CLOSED_BY_VISITOR))
                || (self == .CLOSED_BY_OPERATOR))
                || (self == .UNKNOWN)
        }
        
    }
    
    
    // MARK: - Properties
    private var category: String?
    private var clientSideID: String?
    private var creationTimestamp: Double
    private var id: String
    private lazy var messages = [MessageItem]()
    private var modificationTimestamp: Double?
    private var offline: Bool?
    private var `operator`: OperatorItem?
    private lazy var operatorIDToRate = [String: RatingItem]()
    private var operatorTyping: Bool?
    private var readByVisitor: Bool?
    private var state: String?
    private var subcategory: String?
    private var subject: String?
    private var unreadByOperatorTimestamp: Double?
    private var unreadByVisitorTimestamp: Double?
    private var visitorTyping: Bool?
    
    
    // MARK: - Initializers
    
    init(jsonDictionary: [String: Any?]) {
        if let creationTimestampValue = jsonDictionary[JSONField.CREATION_TIMESTAMP.rawValue] as? Double {
            creationTimestamp = creationTimestampValue
        } else {
            creationTimestamp = ChatItem.createCreationTimestamp()
        }
        
        if let idValue = jsonDictionary[JSONField.ID.rawValue] as? String {
            id = idValue
        } else {
            id = String(Int(-creationTimestamp))
        }
        
        if let messagesValue = jsonDictionary[JSONField.MESSAGES.rawValue] as? [Any] {
            for message in messagesValue {
                if let messageValue = message as? [String: Any?] {
                    let messageItem = MessageItem(jsonDictionary: messageValue)
                    messages.append(messageItem)
                }
            }
        }

        if let operatorValue = jsonDictionary[JSONField.OPERATOR.rawValue] as? [String: Any?] {
            `operator` = OperatorItem(jsonDictionary: operatorValue)
        }
        
        if let operatorIDToRateValue = jsonDictionary[JSONField.OPERATOR_ID_TO_RATE.rawValue] as? [String: Any?] {
            for (operatorIDValue, ratingValue) in operatorIDToRateValue {
                if let ratingItemValue = ratingValue as? [String: Any?] {
                    let rating = RatingItem(jsonDictionary: ratingItemValue)
                    operatorIDToRate[operatorIDValue] = rating
                }
            }
        }
        
        if let category = jsonDictionary[JSONField.CATEGORY.rawValue] as? String {
            self.category = category
        }
        
        if let clientSideID = jsonDictionary[JSONField.CLIENT_SIDE_ID.rawValue] as? String {
            self.clientSideID = clientSideID
        }
        
        if let modificationTimestamp = jsonDictionary[JSONField.MODIFICATION_TIMESTAMP.rawValue] as? Double {
            self.modificationTimestamp = modificationTimestamp
        }
        
        if let offline = jsonDictionary[JSONField.OFFLINE.rawValue] as? Bool {
            self.offline = offline
        }
        
        if let operatorTyping = jsonDictionary[JSONField.OPERATOR_TYPING.rawValue] as? Bool {
            self.operatorTyping = operatorTyping
        }
        
        if let readByVisitor = jsonDictionary[JSONField.READ_BY_VISITOR.rawValue] as? Bool {
            self.readByVisitor = readByVisitor
        }
        
        if let state = jsonDictionary[JSONField.STATE.rawValue] as? String {
            self.state = state
        }
        
        if let subcategory = jsonDictionary[JSONField.SUBCATEGORY.rawValue] as? String {
            self.subcategory = subcategory
        }
        
        if let subject = jsonDictionary[JSONField.SUBJECT.rawValue] as? String {
            self.subject = subject
        }
        
        if let unreadByOperatorTimestamp = jsonDictionary[JSONField.UNREAD_BY_OPERATOR_TIMESTAMP.rawValue] as? Double {
            self.unreadByOperatorTimestamp = unreadByOperatorTimestamp
        }
        
        if let unreadByVisitorTimestamp = jsonDictionary[JSONField.UNREAD_BY_VISITOR_TIMESTAMP.rawValue] as? Double {
            self.unreadByVisitorTimestamp = unreadByVisitorTimestamp
        }
        
        if let visitorTyping = jsonDictionary[JSONField.VISITOR_TYPING.rawValue] as? Bool {
            self.visitorTyping = visitorTyping
        }
    }
    
    // For testing purpoeses.
    init(id: String? = nil) {
        creationTimestamp = ChatItem.createCreationTimestamp()
        
        if id == nil {
            self.id = String(Int(-creationTimestamp))
        } else {
            self.id = id!
        }
    }
    
    
    // MARK: - Methods
    
    func getMessages() -> [MessageItem] {
        return messages
    }
    
    func set(messages: [MessageItem]) {
        self.messages = messages
    }
    
    func add(message: MessageItem,
             atPosition position: Int? = nil) {
        if position == nil {
            messages.append(message)
        } else {
            messages.insert(message,
                            at: position!)
        }
    }
    
    func isOperatorTyping() -> Bool {
        return operatorTyping == true
    }
    
    func set(operatorTyping: Bool?) {
        self.operatorTyping = operatorTyping
    }
    
    func getState() -> ChatItemState {
        return ChatItemState(withType: state!)
    }
    
    func set(state: ChatItemState) {
        self.state = state.rawValue
    }
    
    func getOperator() -> OperatorItem? {
        return `operator`
    }
    
    func set(operator: OperatorItem) {
        self.`operator` = `operator`
    }
    
    func getReadByVisitor() -> Bool? {
        return readByVisitor
    }
    
    func set(readByVisitor: Bool?) {
        self.readByVisitor = readByVisitor
    }
    
    func getOperatorIDToRate() -> [String: RatingItem]? {
        return operatorIDToRate
    }
    
    func set(rating: RatingItem,
             toOperatorWithId operatorID: String) {
        operatorIDToRate[operatorID] = rating
    }
    
    func getUnreadByVisitorTimestamp() -> Double? {
        return unreadByVisitorTimestamp
    }
    
    func getUnreadByOperatorTimestamp() -> Double? {
        return unreadByOperatorTimestamp
    }
    
    
    // MARK: Private methods
    private static func createCreationTimestamp() -> Double {
        return Double(InternalUtils.getCurrentTimeInMicrosecond()) / 1000.0
    }
    
    
}

// MARK: - Equatable
extension ChatItem: Equatable {
    
    // Used inside MessageHolderImpl.receiving(newChat:previousChat:newMessages:) only.
    static func == (lhs: ChatItem,
                    rhs: ChatItem) -> Bool {
        return (lhs.id == rhs.id)
            && (lhs.clientSideID == rhs.clientSideID)
    }
    
}
