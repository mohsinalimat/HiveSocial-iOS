import UIKit
import MessageKit
import InputBarAccessoryView
import Firebase
import FirebaseFirestoreSwift
import CollieGallery

/// A base class for the example controllers
class VC_ChatBase: MessagesViewController, MessagesDataSource {
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    var currentChatChannel: MockChannel!
    var messageList: [MockMessage] = []
    var blocked: Bool = false
    
    let refreshControl = UIRefreshControl()
    
    let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureMessageCollectionView()
//        configureMessageInputBar()
        loadFirstMessages()
        title = "Messages"
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.becomeFirstResponder()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    func loadFirstMessages() {
    }
    
    @objc func loadMoreMessages() {
    }
    
    func configureMessageCollectionView() {
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messageCellDelegate = self
        
        scrollsToLastItemOnKeyboardBeginsEditing = true // default false
        maintainPositionOnKeyboardFrameChanged = true // default false
        
        messagesCollectionView.addSubview(refreshControl)
        refreshControl.addTarget(self, action: #selector(loadMoreMessages), for: .valueChanged)
    }
    
    func configureMessageInputBar() {
        messageInputBar.delegate = self
    }
    
    // MARK: - Helpers
    
    func insertMessage(_ message: MockMessage) {
        messageList.append(message)
        // Reload last section to update header/footer labels and insert a new one
        messagesCollectionView.performBatchUpdates({
            messagesCollectionView.insertSections([messageList.count - 1])
            if messageList.count >= 2 {
                messagesCollectionView.reloadSections([messageList.count - 2])
            }
        }, completion: { [weak self] _ in
            if self?.isLastSectionVisible() == true {
                self?.messagesCollectionView.scrollToLastItem(animated: true)
            }
        })
    }
    
    func isLastSectionVisible() -> Bool {
        
        guard !messageList.isEmpty else { return false }
        
        let lastIndexPath = IndexPath(item: 0, section: messageList.count - 1)
        
        return messagesCollectionView.indexPathsForVisibleItems.contains(lastIndexPath)
    }
    
    // MARK: - MessagesDataSource
    
    func currentSender() -> SenderType {
        return ChatData.shared.currentSender
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messageList.count
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messageList[indexPath.section]
    }
    
    func cellTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        if indexPath.section % 3 == 0 {
            return NSAttributedString(string: MessageKitDateFormatter.shared.string(from: message.sentDate), attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 10), NSAttributedString.Key.foregroundColor: UIColor.darkGray])
        }
        return nil
    }
    
    func cellBottomLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        
        return NSAttributedString(string: "Read", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 10), NSAttributedString.Key.foregroundColor: UIColor.darkGray])
    }
    
    func messageTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        let name = message.sender.displayName
        return NSAttributedString(string: name, attributes: [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .caption1)])
    }
    
    func messageBottomLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        
        let dateString = formatter.string(from: message.sentDate)
        return NSAttributedString(string: dateString, attributes: [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .caption2)])
    }
    
}

// MARK: - MessageCellDelegate

extension VC_ChatBase: MessageCellDelegate {
    
    func didTapAvatar(in cell: MessageCollectionViewCell) {
        print("Avatar tapped")
        guard let indexPath = messagesCollectionView.indexPath(for: cell),
              let message = messagesCollectionView.messagesDataSource?.messageForItem(at: indexPath, in: messagesCollectionView) else {
            print("Failed to identify message when audio cell receive tap gesture")
            return
        }
        Utils.fetchUser(uid: message.sender.senderId) { (rusr) in
            guard let usr = rusr else { return }
            self.openUser(usr: usr)
        }
    }
    
    func didTapMessage(in cell: MessageCollectionViewCell) {
        print("Message tapped")
    }
    
    func didTapCellTopLabel(in cell: MessageCollectionViewCell) {
        print("Top cell label tapped")
    }
    
    func didTapCellBottomLabel(in cell: MessageCollectionViewCell) {
        print("Bottom cell label tapped")
    }
    
    func didTapMessageTopLabel(in cell: MessageCollectionViewCell) {
        print("Top message label tapped")
    }
    
    func didTapMessageBottomLabel(in cell: MessageCollectionViewCell) {
        print("Bottom label tapped")
    }
    
    func didTapPlayButton(in cell: AudioMessageCell) {
    }
    
    func didStartAudio(in cell: AudioMessageCell) {
        print("Did start playing audio sound")
    }
    
    func didPauseAudio(in cell: AudioMessageCell) {
        print("Did pause audio sound")
    }
    
    func didStopAudio(in cell: AudioMessageCell) {
        print("Did stop audio sound")
    }
    
    func didTapAccessoryView(in cell: MessageCollectionViewCell) {
        print("Accessory view tapped")
    }
    
    func didTapImage(in cell: MessageCollectionViewCell) {
        print("Image tapped")
        if let v = cell as? MediaMessageCell, let img = v.imageView.image{
            let pic = CollieGalleryPicture(image: img)
            let gallery = CollieGallery(pictures: [pic])
            gallery.presentInViewController(self)
        }
    }
}

// MARK: - MessageLabelDelegate

extension VC_ChatBase: MessageLabelDelegate {
    
    func didSelectAddress(_ addressComponents: [String: String]) {
        print("Address Selected: \(addressComponents)")
    }
    
    func didSelectDate(_ date: Date) {
        print("Date Selected: \(date)")
    }
    
    func didSelectPhoneNumber(_ phoneNumber: String) {
        print("Phone Number Selected: \(phoneNumber)")
    }
    
    func didSelectURL(_ url: URL) {
        print("URL Selected: \(url)")
    }
    
    func didSelectTransitInformation(_ transitInformation: [String: String]) {
        print("TransitInformation Selected: \(transitInformation)")
    }
    
    func didSelectHashtag(_ hashtag: String) {
        print("Hashtag selected: \(hashtag)")
    }
    
    func didSelectMention(_ mention: String) {
        print("Mention selected: \(mention)")
    }
    
    func didSelectCustom(_ pattern: String, match: String?) {
        print("Custom data detector patter selected: \(pattern)")
    }
    
}

// MARK: - MessageInputBarDelegate

extension VC_ChatBase: InputBarAccessoryViewDelegate {
    
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        if self.blocked{
            self.showError(msg: "You are not allowed to send message to this user.")
            return
        }
        
        // Here we can parse for which substrings were autocompleted
        let attributedText = messageInputBar.inputTextView.attributedText!
        let range = NSRange(location: 0, length: attributedText.length)
        attributedText.enumerateAttribute(.autocompleted, in: range, options: []) { (_, range, _) in
        }
        
        let components = inputBar.inputTextView.components
        messageInputBar.inputTextView.text = String()
        messageInputBar.invalidatePlugins()
        
        // Send button activity animation
        messageInputBar.sendButton.startAnimating()
        messageInputBar.inputTextView.placeholder = "Sending..."
        
        for component in components {
            let user = ChatData.shared.currentSender
            if let str = component as? String {
                let curTime: Date = Date()
                let msgKey: String = Utils.curTimeStr

                let msg = MockMessage(text: str, user: user, messageId: msgKey, date: curTime)

                self.currentChatChannel.activated = true
                self.currentChatChannel.lastMsg = msg
                ChatChannels[self.currentChatChannel.channelId] = self.currentChatChannel
                
                if self.messageList.count == 0{
                    self.currentChatChannel.setOnline()

                    FCHAT_REF
                        .document(self.currentChatChannel.channelId)
                        .setData(self.currentChatChannel.getJson(), merge: true)
                }
                else{
                    FCHAT_REF
                        .document(self.currentChatChannel.channelId)
                        .updateData([
                            MockChannel.key_last_msg: msg.getJson()
                        ])
                }

                FCHAT_REF
                    .document(currentChatChannel.channelId)
                    .collection(MockChannel.key_collection_msgs)
                    .document(msgKey)
                    .setData(msg.getJson()) { (_) in
                        self.messageInputBar.sendButton.stopAnimating()
                        self.messageInputBar.inputTextView.placeholder = "Message..."
                        self.messagesCollectionView.scrollToLastItem(animated: true)
                    }
                
                if currentChatChannel.targetUser != nil{
                    if !currentChatChannel.targetUserOnline && currentChatChannel.targetUser.push_message && !currentChatChannel.targetUser.token.isEmpty{
                        Noti.sendMessageNotification(uid: self.currentChatChannel.targetUserId(), msg: str, command: true)
                    }
                }
                else{
                    Utils.fetchUser(uid: currentChatChannel.targetUserId()) { (rusr) in
                        guard let usr = rusr else { return }
                        self.currentChatChannel.targetUser = usr
                        
                        if !self.currentChatChannel.targetUserOnline && self.currentChatChannel.targetUser.push_message && !self.currentChatChannel.targetUser.token.isEmpty{
                            Noti.sendMessageNotification(uid: self.currentChatChannel.targetUserId(), msg: str, command: true)
                        }
                    }
                }
            }
        }
    }
}
