//
//  ChatViewController.swift
//  WebimClientLibrary_Example
//
//  Created by Nikita Lazarev-Zubov on 02.10.17.
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

import PopupDialog
import SlackTextViewController
import UIKit
import WebimClientLibrary

/**
 View controller that visualize chat.
 - Author:
 Nikita Lazarev-Zubov
 - Copyright:
 2017 Webim
 */
class ChatViewController: SLKTextViewController {
    
    // MARK: - Properties
    private let imagePicker = UIImagePickerController()
    private let refreshControl = UIRefreshControl()
    private lazy var alreadyRated = [String: Bool]()
    private var lastOperatorID: String?
    private lazy var messages = [Message]()
    private lazy var webimService = WebimService()
    
    
    // MARK: - Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker.delegate = self
        
        setupTableView()
        setupNavigationItem()
        setupSlackTextViewController()
        setupWebimSession()
    }
    
    // For testing purposes.
    func set(messages: [Message]) {
        self.messages = messages
    }
    
    // MARK: SlackTextViewController methods
    
    override func textViewDidChange(_ textView: UITextView) {
        webimService.setVisitorTyping(draft: textView.text)
    }
    
    // Send message button.
    override func didPressRightButton(_ sender: Any?) {
        textView.refreshFirstResponder()
        
        if let text = textView.text,
            !text.isEmpty {
            webimService.send(message: text)
        }
        
        textView.text = ""
        
        // Delete visitor typing draft after message is sent.
        webimService.setVisitorTyping(draft: nil)
    }
    
    // Send file buton.
    override func didPressLeftButton(_ sender: Any?) {
        dismissKeyboard(true)
        
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .photoLibrary
        present(imagePicker,
                animated: true,
                completion: nil)
    }
    
    // MARK: UICollectionViewDataSource methods
    override func numberOfSections(in tableView: UITableView) -> Int {
        if messages.count > 0 {
            tableView.backgroundView = nil
            
            return 1
        } else {
            tableView.emptyTableView(message: EMPTY_TABLE_VIEW_TEXT)
            
            return 0
        }
    }
    
    
    // MARK: UITableViewDelegate methods
    
    override func tableView(_ tableView: UITableView,
                            numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell",
                                                       for: indexPath) as? MessageTableViewCell else {
                                                        fatalError("The dequeued cell is not an instance of MessageTableViewCell.")
        }
        
        let message = messages[indexPath.row]
        cell.setContent(withMessage: message)
        
        if let operatorID = message.getOperatorID() {
            lastOperatorID = operatorID // For using on chat closing.
            let gestureRecognizer = UITapGestureRecognizer(target: self,
                                                           action:  #selector(ChatViewController.rateOperator(_:)))
            cell.avatarImageView.addGestureRecognizer(gestureRecognizer)
        }
        
        if (message.getType() == .FILE_FROM_OPERATOR)
            || (message.getType() == .FILE_FROM_VISITOR) {
            let gestureRecognizer = UITapGestureRecognizer(target: self,
                                                           action: #selector(ChatViewController.showFile(_:)))
            cell.bodyLabel.addGestureRecognizer(gestureRecognizer)
        }
        
        return cell
    }
    
    
    // MARK: Private methods
    
    /**
     Sets up table view.
     - Author:
     Nikita Lazarev-Zubov
     - Copyright:
     2017 Webim
     */
    private func setupTableView() {
        tableView?.estimatedRowHeight = 64.0
        tableView?.rowHeight = UITableViewAutomaticDimension
        tableView?.separatorStyle = .none
        tableView?.register(MessageTableViewCell.self,
                            forCellReuseIdentifier: "MessageCell")
        
        // Setup refresh control.
        if #available(iOS 10.0, *) {
            tableView?.refreshControl = refreshControl
        } else {
            tableView?.addSubview(refreshControl)
        }
        refreshControl.addTarget(self,
                                 action: #selector(requestMessages),
                                 for: .valueChanged)
        refreshControl.tintColor = MAIN_BACKGROUND_COLOR
        refreshControl.attributedTitle = REFRESH_CONTROL_TEXT
    }
    
    /**
     Sets up SlackTextViewController view.
     - SeeAlso:
     `SLKTextViewController` protocol.
     - Author:
     Nikita Lazarev-Zubov
     - Copyright:
     2017 Webim
     */
    private func setupSlackTextViewController() {
        isInverted = false
        
        leftButton.setImage(#imageLiteral(resourceName: "Clip"),
                            for: .normal)
        leftButton.accessibilityLabel = LeftButton.ACCESSIBILITY_LABEL.rawValue.localized
        leftButton.accessibilityHint = LeftButton.ACCESSIBILITY_HINT.rawValue.localized
        
        rightButton.setImage(#imageLiteral(resourceName: "SendMessage"),
                             for: .normal)
        rightButton.setTitle(nil,
                             for: .normal)
        
        textInputbar.backgroundColor = MAIN_BACKGROUND_COLOR
    }
    
    /**
     Sets up navigation item.
     - Author:
     Nikita Lazarev-Zubov
     - Copyright:
     2017 Webim
     */
    private func setupNavigationItem() {
        self.setBackButton(image: #imageLiteral(resourceName: "Back"))
        
        let closeChatButton = UIButton(type: .custom)
        closeChatButton.setImage(#imageLiteral(resourceName: "Close"),
                                 for: .normal)
        closeChatButton.accessibilityLabel = CloseChatButton.ACCESSIBILITY_LABEL.rawValue.localized
        closeChatButton.accessibilityHint = CloseChatButton.ACCESSIBILITY_HINT.rawValue.localized
        closeChatButton.addTarget(self,
                                  action: #selector(endChat),
                                  for: .touchUpInside)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: closeChatButton)
        
        // Setting an image to NavigationItem TitleView.
        let navigationItemImageView = UIImageView(image: #imageLiteral(resourceName: "LogoWebimNavigationBar"))
        navigationItemImageView.contentMode = .scaleAspectFit
        navigationItem.titleView = navigationItemImageView
    }
    
    /**
     Sets up `WebimService` class.
     - SeeAlso:
     `WebimService` class.
     - Author:
     Nikita Lazarev-Zubov
     - Copyright:
     2017 Webim
     */
    private func setupWebimSession() {
        webimService.createSession(viewController: self)
        webimService.startSession()
        
        webimService.setMessageStream()
        
        webimService.setMessageTracker(withMessageListener: self)
        webimService.getLastMessages() { [weak self] messages in
            self?.messages.insert(contentsOf: messages,
                                  at: 0)
            
            DispatchQueue.main.async() {
                self?.tableView?.reloadData()
                
                self?.scrollToBottom()
            }
        }
    }
    
    /**
     Requests messages from above of the message history.
     - SeeAlso:
     `WebimService` class.
     - Author:
     Nikita Lazarev-Zubov
     - Copyright:
     2017 Webim
     */
    @objc
    private func requestMessages() {
        webimService.getNextMessages() { [weak self] messages in
            self?.messages.insert(contentsOf: messages,
                                  at: 0)
            
            DispatchQueue.main.async() {
                self?.tableView?.reloadData()
                
                self?.refreshControl.endRefreshing()
            }
        }
    }
    
    /**
     Closes chat in virtual context.
     - SeeAlso:
     `WebimService` class.
     - Author:
     Nikita Lazarev-Zubov
     - Copyright:
     2017 Webim
     */
    @objc
    private func endChat() {
        webimService.closeChat()
        
        if let operatorID = lastOperatorID {
            if alreadyRated[operatorID] != true { // Don't offer to rate an operator if a visitor already did it independently.
                showRatingDialog(forOperator: operatorID)
            }
        }
    }
    
    /**
     Rates current operator.
     - SeeAlso:
     `WebimService` class.
     - Author:
     Nikita Lazarev-Zubov
     - Copyright:
     2017 Webim
     */
    @objc
    private func rateOperator(_ recognizer: UITapGestureRecognizer) {
        if recognizer.state == .ended {
            let tapLocation = recognizer.location(in: tableView)
            if let tapIndexPath = tableView?.indexPathForRow(at: tapLocation) {
                let message = messages[tapIndexPath.row]
                if let operatorID = message.getOperatorID() {
                    showRatingDialog(forOperator: operatorID)
                }
            }
        }
    }
    
    /**
     Show preview of file inside a chat message.
     - SeeAlso:
     `WebimService` class.
     - Author:
     Nikita Lazarev-Zubov
     - Copyright:
     2017 Webim
     */
    @objc
    private func showFile(_ recognizer: UITapGestureRecognizer) {
        if recognizer.state == .ended {
            let tapLocation = recognizer.location(in: tableView)
            if let tapIndexPath = tableView?.indexPathForRow(at: tapLocation) {
                let message = messages[tapIndexPath.row]
                
                if let attachment = message.getAttachment() {
                    let attachmentURL = attachment.getURL()
                    
                    var popupMessage: String?
                    var image: UIImage?
                    
                    if isImage(contentType: attachment.getContentType()) {
                        let semaphore = DispatchSemaphore(value: 0)
                        let request = URLRequest(url: attachmentURL)
                        
                        print("Requesting file: \(attachmentURL.absoluteString)")
                        
                        URLSession.shared.dataTask(with: request,
                                                   completionHandler: { data, _, _ in
                                                    if let data = data {
                                                        if let downloadedImage = UIImage(data: data) {
                                                            image = downloadedImage
                                                        } else {
                                                            popupMessage = ShowFileDialog.INVALID_IMAGE_FORMAT.rawValue.localized
                                                        }
                                                    } else {
                                                        popupMessage = ShowFileDialog.INVALID_IMAGE_LINK.rawValue.localized
                                                    }
                                                    
                                                    semaphore.signal()
                        }).resume()
                        
                        _ = semaphore.wait(timeout: .distantFuture)
                    } else {
                        popupMessage = ShowFileDialog.NOT_IMAGE.rawValue
                    }
                    
                    let button = CancelButton(title: ShowFileDialog.BUTTON_TITLE.rawValue.localized,
                                              action: nil)
                    button.accessibilityHint = ShowFileDialog.ACCESSIBILITY_HINT.rawValue.localized
                    
                    let popup = PopupDialog(title: attachment.getFileName(),
                                            message: popupMessage,
                                            image: image,
                                            buttonAlignment: .horizontal,
                                            transitionStyle: .bounceUp,
                                            gestureDismissal: true,
                                            completion: nil)
                    popup.addButton(button)
                    self.present(popup,
                                 animated: true,
                                 completion: nil)
                }
            }
        }
    }
    
    /**
     Check if passed MIME type is supproted image type.
     - parameter contentType:
     MIME type.
     - returns:
     True if passed MIME type is supported image type and false otherwise.
     - Author:
     Nikita Lazarev-Zubov
     - Copyright:
     2018 Webim
     */
    private func isImage(contentType: String) -> Bool {
        return ((contentType == "image/gif")
            || (contentType == "image/jpeg")
            || (contentType == "image/png")
            || (contentType == "image/tiff"))
    }
    
    /**
     Shows RatingViewController.
     - SeeAlso:
     `RatingViewController` class.
     - Author:
     Nikita Lazarev-Zubov
     - Copyright:
     2017 Webim
     */
    private func showRatingDialog(forOperator operatorID: String) {
        let ratingViewController = RatingViewController(nibName: "RatingViewController",
                                                        bundle: nil)
        let popup = PopupDialog(viewController: ratingViewController,
                                buttonAlignment: .horizontal,
                                transitionStyle: .bounceUp,
                                gestureDismissal: true)
        
        let cancelButton = CancelButton(title: RatingDialog.CANCEL_BUTTON_TITLE.rawValue.localized,
                                        height: 60,
                                        dismissOnTap: true,
                                        action: nil)
        cancelButton.accessibilityHint = RatingDialog.CANCEL_BUTTON_ACCESSIBILITY_HINT.rawValue.localized
        
        let rateButton = DefaultButton(title: RatingDialog.ACTION_BUTTON_TITLE.rawValue.localized,
                                       height: 60,
                                       dismissOnTap: true) { [weak self] in
                                        self?.alreadyRated[operatorID] = true
                                        
                                        self?.webimService.rateOperator(withID: operatorID,
                                                                        byRating: Int(ratingViewController.ratingView.rating),
                                                                        completionHandler: self)
        }
        rateButton.accessibilityHint = RatingDialog.ACTION_BUTTON_ACCESSIBILITY_HINT.rawValue.localized
        
        popup.addButtons([cancelButton,
                          rateButton])
        
        present(popup,
                animated: true,
                completion: nil)
    }
    
    /**
     Scroll table view to the bottom.
     - Author:
     Nikita Lazarev-Zubov
     - Copyright:
     2017 Webim
     */
    private func scrollToBottom() {
        if messages.isEmpty {
            return
        }
        
        let bottomMessageIndex = IndexPath(row: (tableView?.numberOfRows(inSection: 0))! - 1,
                                           section: 0)
        tableView?.scrollToRow(at: bottomMessageIndex,
                               at: .bottom,
                               animated: true)
    }
    
}

// MARK: - UIImagePickerControllerDelegate
extension ChatViewController: UIImagePickerControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [String: Any]) {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            let imageData = UIImagePNGRepresentation(image)!
            
            if let imageURL = info[UIImagePickerControllerReferenceURL] as? URL {
                let imageName = imageURL.lastPathComponent
                let mimeType = MimeType(url: imageURL as URL)
                
                webimService.send(file: imageData,
                                  fileName: imageName,
                                  mimeType: mimeType.value,
                                  completionHandler: self)
            }
        }
        
        dismiss(animated: true,
                completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true,
                completion: nil)
    }
    
}

// MARK: - UINavigationControllerDelegate
extension ChatViewController: UINavigationControllerDelegate {
    // For image picker.
}

// MARK: - WEBIM: MessageListener
extension ChatViewController: MessageListener {
    
    func added(message newMessage: Message,
               after previousMessage: Message?) {
        if let previousMessage = previousMessage {
            var added = false
            
            for (index, message) in messages.enumerated() {
                if previousMessage.isEqual(to: message) {
                    messages.insert(newMessage,
                                    at: index + 1)
                    
                    added = true
                    
                    break
                }
            }
            
            if !added {
                messages.append(newMessage)
            }
        } else {
            messages.append(newMessage)
        }
        
        DispatchQueue.main.async() {
            self.tableView?.reloadData()
            
            self.scrollToBottom()
        }
    }
    
    func removed(message: Message) {
        var toUpdate = false
        
        for (messageIndex, iteratedMessage) in messages.enumerated() {
            if iteratedMessage.getID() == message.getID() {
                messages.remove(at: messageIndex)
                toUpdate = true
                
                break
            }
        }
        
        if toUpdate {
            DispatchQueue.main.async() {
                self.tableView?.reloadData()
                
                self.scrollToBottom()
            }
        }
    }
    
    func removedAllMessages() {
        messages.removeAll()
        
        DispatchQueue.main.async() {
            self.tableView?.reloadData()
        }
    }
    
    func changed(message oldVersion: Message,
                 to newVersion: Message) {
        var toUpdate = false
        
        for (messageIndex, iteratedMessage) in messages.enumerated() {
            if iteratedMessage.getID() == oldVersion.getID() {
                messages[messageIndex] = newVersion
                toUpdate = true
                
                break
            }
        }
        
        if toUpdate {
            DispatchQueue.main.async() {
                self.tableView?.reloadData()
                
                self.scrollToBottom()
            }
        }
    }
    
}

// MARK: - SendFileCompletionHandler
extension ChatViewController: SendFileCompletionHandler {
    
    func onSuccess(messageID: String) {
        // Ignored.
    }
    
    func onFailure(messageID: String,
                   error: SendFileError) {
        DispatchQueue.main.sync {
            var message: String?
            switch error {
            case .FILE_SIZE_EXCEEDED:
                message = SendFileErrorMessage.FILE_SIZE_EXCEEDED.rawValue.localized
                
                break
            case .FILE_TYPE_NOT_ALLOWED:
                message = SendFileErrorMessage.FILE_TYPE_NOT_ALLOWED.rawValue.localized
                
                break
            }
            
            let popupDialog = PopupDialog(title: SendFileErrorMessage.TITLE.rawValue.localized,
                                          message: message)
            
            let okButton = CancelButton(title: SendFileErrorMessage.BUTTON_TITLE.rawValue.localized) { [weak self] in
                guard let `self` = self else {
                    return
                }
                
                for (index, message) in self.messages.enumerated() {
                    if message.getID() == messageID {
                        self.messages.remove(at: index)
                        
                        DispatchQueue.main.async() {
                            self.tableView?.reloadData()
                        }
                        
                        return
                    }
                }
            }
            okButton.accessibilityHint = SendFileErrorMessage.BUTTON_ACCESSIBILITY_HINT.rawValue.localized
            popupDialog.addButton(okButton)
            
            self.present(popupDialog,
                         animated: true,
                         completion: nil)
        }
    }
    
}

// MARK: - RateOperatorCompletionHandler
extension ChatViewController: RateOperatorCompletionHandler {
    
    func onSuccess() {
        // Ignored.
    }
    
    func onFailure(error: RateOperatorError) {
        DispatchQueue.main.sync {
            let message = RateOperatorErrorMessage.MESSAGE.rawValue.localized
            
            let popupDialog = PopupDialog(title: RateOperatorErrorMessage.TITLE.rawValue.localized,
                                          message: message)
            
            let okButton = CancelButton(title: RateOperatorErrorMessage.BUTTON_TITLE.rawValue.localized,
                                        action: nil)
            okButton.accessibilityHint = RateOperatorErrorMessage.BUTTON_ACCESSIBILITY_HINT.rawValue.localized
            popupDialog.addButton(okButton)
            
            self.present(popupDialog,
                         animated: true,
                         completion: nil)
        }
    }
    
}
