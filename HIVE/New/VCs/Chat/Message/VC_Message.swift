import UIKit
import MapKit
import MessageKit
import InputBarAccessoryView
import IQKeyboardManagerSwift
import Firebase
import FirebaseFirestoreSwift
import YPImagePicker
import SDWebImage

final class VC_Message: VC_ChatBase {
    
    let outgoingAvatarOverlap: CGFloat = 17.5
    
    override func viewDidLoad() {
        messagesCollectionView = MessagesCollectionView(frame: .zero, collectionViewLayout: CustomMessagesFlowLayout())
        messagesCollectionView.register(CustomCell.self)
        
        super.viewDidLoad()
        initComponents()
    }
    
    deinit {
        msgListener?.remove()
        msgListener = nil
        
        MeTracker?.remove()
        MeTracker = nil
        
        TargetTracker?.remove()
        TargetTracker = nil
        
        TargetUserTracker?.remove()
        TargetUserTracker = nil
        
        ChannelTracker?.remove()
        ChannelTracker = nil
    }
    
    func initComponents(){
        addSwipeRight()
        
        if currentChatChannel == nil || currentChatChannel.targetUserId().isEmpty{
            self.navigationController?.popViewController(animated: true)
            return
        }
        
        if TargetUserTracker == nil{
            TargetUserTracker = FUSER_REF
                .document(self.currentChatChannel.targetUserId())
                .addSnapshotListener({ (doc, _) in
                    if let docId = doc?.documentID, let data = doc?.data(){
                        let usr = User(uid: docId, data: data)
                        self.currentChatChannel.targetUser = usr
                        ChatChannels[self.currentChatChannel.channelId] = self.currentChatChannel
                        
                        DBUsers[docId] = usr

                        self.trackUserBlock()
                        self.trackCurrentChannel()
                    }
                    else{
                        self.showError(msg: "Error happened in pulling user data!")
                        
                        self.blocked = true
                        self.currentChatChannel.activated = false
                    }
                })
        }

        configureMessageInputBar()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        IQKeyboardManager.shared.enable = false
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        
        if currentChatChannel != nil && currentChatChannel.activated{
            currentChatChannel.setLastSeen()
            currentChatChannel.setOnline()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        IQKeyboardManager.shared.enable = true
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        
        if self.isMovingFromParent || self.isBeingDismissed{
            msgListener?.remove()
            msgListener = nil
            
            MeTracker?.remove()
            MeTracker = nil
            
            TargetTracker?.remove()
            TargetTracker = nil
            
            TargetUserTracker?.remove()
            TargetUserTracker = nil
            
            ChannelTracker?.remove()
            ChannelTracker = nil
        }
        
        if currentChatChannel.activated{
            currentChatChannel.setLastSeen()
            currentChatChannel.setOnline(online: false)
        }
    }
    
    var ChannelTracker: ListenerRegistration? = nil
    var statusUpdated: Bool = false
    func trackCurrentChannel(){
        if ChannelTracker != nil{
            return
        }
        
        ChannelTracker = FCHAT_REF
            .document(self.currentChatChannel.channelId)
            .addSnapshotListener({ (doc, err) in
                if let documentID = doc?.documentID, let data = doc?.data(){
                    print("channel tracking started")
                    let chn: MockChannel = MockChannel(id: documentID, dic: data)
                    ChatChannels[chn.channelId] = chn
                    self.currentChatChannel = chn
                    
                    if self.currentChatChannel.lastMsg != nil{
                        self.currentChatChannel.activated = true
                        
                        if self.statusUpdated{
                            return
                        }

                        self.statusUpdated = true
                        self.currentChatChannel.setLastSeen()
                        self.currentChatChannel.setOnline()
                    }
                }
                else{
                    print("channel is new channel!")
                }
            })
    }
    
    var MeTracker: ListenerRegistration? = nil
    var TargetTracker: ListenerRegistration? = nil
    var TargetUserTracker: ListenerRegistration? = nil
    func trackUserBlock(){
        guard let targetUser = self.currentChatChannel.targetUser else { return }
        if MeTracker == nil{
            MeTracker = FUSER_REF
                .document(Me.uid)
                .collection(User.key_collection_blocked)
                .document(targetUser.uid)
                .addSnapshotListener { (doc, _) in
                    if doc?.exists == true{
                        self.blocked = true
                        self.currentChatChannel.activated = false
                        self.messageInputBar.sendButton.isEnabled = false
                        self.showError(msg: "You are not allowed to send message to this user.")
                    }
                    else{
                        if self.blocked{
                            self.currentChatChannel.activated = true
                            self.messageInputBar.sendButton.isEnabled = true
                        }
                    }
                }
        }
        
        if TargetTracker == nil{
            TargetTracker = FUSER_REF
                .document(targetUser.uid)
                .collection(User.key_collection_blocked)
                .document(Me.uid)
                .addSnapshotListener { (doc, _) in
                    if doc?.exists == true{
                        self.blocked = true
                        self.currentChatChannel.activated = false
                        self.messageInputBar.sendButton.isEnabled = false
                        self.showError(msg: "You are not allowed to send message to this user.")
                    }
                    else{
                        if self.blocked{
                            self.currentChatChannel.activated = true
                            self.messageInputBar.sendButton.isEnabled = true
                        }
                    }
                }
        }
    }
    
    var msgListener: ListenerRegistration?
    override func loadFirstMessages() {
        if currentChatChannel == nil || msgListener != nil {
            self.messagesCollectionView.reloadData()
            DispatchQueue.main.async {
                self.messagesCollectionView.scrollToLastItem(animated: true)
            }
            return
        }
        
        msgListener = FCHAT_REF
            .document(currentChatChannel.channelId)
            .collection(MockChannel.key_collection_msgs)
            .whereField(MockMessage.key_timestamp, isGreaterThan: currentChatChannel.deletedTime)
            .order(by: MockMessage.key_timestamp, descending: false)
            .limit(toLast: 20)
            .addSnapshotListener { (doc, err) in
                if let error = err{
                    print(error.localizedDescription)
                    return
                }
                
                if doc?.documentChanges.count ?? 0 > 1{
                    //load first messages
                    doc?.documentChanges.forEach({ (diff) in
                        switch(diff.type){
                        case .added:
                            let msg = MockMessage(id: diff.document.documentID, dic: diff.document.data())
                            self.messageList.append(msg)
                            if self.blocked{
                                self.currentChatChannel.activated = false
                            }
                            else{
                                self.currentChatChannel.activated = true
                            }
                            break
                        default:
                            break
                        }
                    })
                    self.messagesCollectionView.reloadData()
                    DispatchQueue.main.async {
                        self.messagesCollectionView.scrollToLastItem(animated: true)
                    }
                }
                else{
                    //load new message
                    doc?.documentChanges.forEach({ (diff) in
                        switch(diff.type){
                        case .added:
                            let msg = MockMessage(id: diff.document.documentID, dic: diff.document.data())
                            self.insertMessage(msg)
                            if self.blocked{
                                self.currentChatChannel.activated = false
                            }
                            else{
                                self.currentChatChannel.activated = true
                            }
                            break
                        default:
                            break
                        }
                    })
                }
            }
    }
    
    override func loadMoreMessages() {
        self.refreshControl.endRefreshing()
        guard let msg = self.messageList.first else { return }
        FCHAT_REF.document(currentChatChannel.channelId)
            .collection(MockChannel.key_collection_msgs)
            .whereField(MockMessage.key_timestamp, isGreaterThan: currentChatChannel.deletedTime)
            .whereField(MockMessage.key_timestamp, isLessThan: msg.sentDate.timeIntervalSince1970)
            .order(by: MockMessage.key_timestamp, descending: false)
            .limit(toLast: 20)
            .getDocuments { (doc, err) in
                if let error = err{
                    print(error.localizedDescription)
                    return
                }
                
                var msgs: [MockMessage] = []
                doc?.documentChanges.forEach({ (diff) in
                    switch(diff.type){
                    case .added:
                        let msg = MockMessage(id: diff.document.documentID, dic: diff.document.data())
                        msgs.append(msg)
                        if self.blocked{
                            self.currentChatChannel.activated = false
                        }
                        else{
                            self.currentChatChannel.activated = true
                        }
                        break
                    case .modified:
                        break
                    case .removed:
                        break
                    }
                })
                
                if msgs.count > 0{
                    DispatchQueue.main.async{
                        self.messageList.insert(contentsOf: msgs, at: 0)
                        self.messagesCollectionView.reloadDataAndKeepOffset()
                        self.refreshControl.endRefreshing()
                    }
                }
            }
    }
    
    override func configureMessageCollectionView() {
        super.configureMessageCollectionView()
        
        let layout = messagesCollectionView.collectionViewLayout as? MessagesCollectionViewFlowLayout
        layout?.sectionInset = UIEdgeInsets(top: 1, left: 8, bottom: 1, right: 8)
        
        // Hide the outgoing avatar and adjust the label alignment to line up with the messages
        layout?.setMessageOutgoingAvatarSize(CGSize(width: 32, height: 32))
        layout?.setMessageOutgoingMessageTopLabelAlignment(LabelAlignment(textAlignment: .right, textInsets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 8)))
        layout?.setMessageOutgoingMessageBottomLabelAlignment(LabelAlignment(textAlignment: .right, textInsets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 8)))
        
        // Set outgoing avatar to overlap with the message bubble
        layout?.setMessageIncomingMessageTopLabelAlignment(LabelAlignment(textAlignment: .left, textInsets: UIEdgeInsets(top: 0, left: 18, bottom: outgoingAvatarOverlap, right: 0)))
        layout?.setMessageIncomingAvatarSize(CGSize(width: 32, height: 32))
        layout?.setMessageIncomingMessagePadding(UIEdgeInsets(top: -outgoingAvatarOverlap, left: -18, bottom: outgoingAvatarOverlap, right: 18))
        
        layout?.setMessageIncomingAccessoryViewSize(CGSize(width: 32, height: 32))
        layout?.setMessageIncomingAccessoryViewPadding(HorizontalEdgeInsets(left: 8, right: 0))
        layout?.setMessageIncomingAccessoryViewPosition(.messageBottom)
        layout?.setMessageOutgoingAccessoryViewSize(CGSize(width: 32, height: 32))
        layout?.setMessageOutgoingAccessoryViewPadding(HorizontalEdgeInsets(left: 0, right: 8))
        
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        configureMessageInputBar()
    }
    
    override func configureMessageInputBar() {
        super.configureMessageInputBar()
        
        messageInputBar.isTranslucent = true
        messageInputBar.separatorLine.isHidden = true
        messageInputBar.inputTextView.tintColor = UIColor.active()
        messageInputBar.inputTextView.placeholderTextColor = UIColor.placeholderText
        messageInputBar.inputTextView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 36)
        messageInputBar.inputTextView.placeholderLabelInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 36)
        messageInputBar.inputTextView.scrollIndicatorInsets = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        
        configureInputBarItems()
    }
    
    private func configureInputBarItems() {
        messageInputBar.setLeftStackViewWidthConstant(to: 36, animated: false)
        
        let btn_img = InputBarSendButton()
            .configure {
                $0.setSize(CGSize(width: 52, height: 36), animated: false)
                $0.isEnabled = true
                $0.image = UIImage(named: "mic_top_camera")
                $0.imageView?.contentMode = .scaleAspectFit
                $0.contentEdgeInsets = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
            }.onTouchUpInside {_ in
                self.view.endEditing(true)
                
                self.sendImage()
            }
        messageInputBar.setStackViewItems([.flexibleSpace, btn_img], forStack: .left, animated: false)
        
        messageInputBar.setRightStackViewWidthConstant(to: 50, animated: false)
        messageInputBar.sendButton.contentEdgeInsets = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
        messageInputBar.sendButton.setSize(CGSize(width: 50, height: 36), animated: false)
        messageInputBar.sendButton.title = "Send"
        messageInputBar.sendButton.setTitleColor(UIColor(named: "col_lbl_body")!, for: .normal)
        messageInputBar.middleContentViewPadding.right = -38
        messageInputBar.inputTextView.placeholder = "Message..."
        
        messageInputBar.sendButton
            .onEnabled { item in
                UIView.animate(withDuration: 0.3, animations: {
                    item.setTitleColor(UIColor.active(), for: .normal)
                })
            }.onDisabled { item in
                UIView.animate(withDuration: 0.3, animations: {
                    item.setTitleColor(UIColor(named: "col_lbl_body")!, for: .normal)
                })
            }
    }
    func sendImage(){
        let picker: YPImagePicker = self.openImagePicker()
        picker.didFinishPicking { [unowned picker] items, cancelled in
            if cancelled{
                picker.dismiss(animated: true, completion: nil)
                return
            }
            for item in items{
                switch(item){
                case .photo(p: let photo):
                    guard let data_upload = photo.image.jpegData(compressionQuality: 0.5) else {
                        return
                    }
                    let filename = "msg_\(Utils.curTime)"
                    let ref_storage = STORAGE_MESSAGE_IMAGES_REF.child(self.currentChatChannel.channelId).child(filename)
                    self.setupHUD(msg: "Uploading image...")
                    ref_storage.putData(data_upload, metadata: nil) { (metadata, err) in
                        if let error = err as NSError?{
                            self.hideHUD()
                            self.showError(msg: error.localizedDescription)
                            return
                        }
                        ref_storage.downloadURL { (downloadUrl, err) in
                            self.hideHUD()
                            if let error = err{
                                self.showError(msg: error.localizedDescription)
                                return
                            }
                            guard (downloadUrl?.absoluteString) != nil else{
                                self.showError(msg: "Error in uploading image. Please try again later!")
                                return
                            }
                            self.sendMessage(img_url: downloadUrl!)
                        }
                    }
                    break
                default:
                    break
                }
                break
            }
            picker.dismiss(animated: true, completion: nil)
        }
    }
    func sendMessage(img_url: URL){
        let user = ChatData.shared.currentSender
        
        let curTime: Date = Date()
        let msgKey: String = String(curTime.timeIntervalSince1970)
        let msg = MockMessage(imageURL: img_url, user: user, messageId: UUID().uuidString, date: curTime)
        
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
                Noti.sendMessageNotification(uid: self.currentChatChannel.targetUserId(), msg: "image", command: true)
            }
        }
        else{
            Utils.fetchUser(uid: currentChatChannel.targetUserId()) { (rusr) in
                guard let usr = rusr else { return }
                self.currentChatChannel.targetUser = usr
                
                if !self.currentChatChannel.targetUserOnline && self.currentChatChannel.targetUser.push_message && !self.currentChatChannel.targetUser.token.isEmpty{
                    Noti.sendMessageNotification(uid: self.currentChatChannel.targetUserId(), msg: "image", command: true)
                }
            }
        }
    }

    // MARK: - Helpers
    
    func isTimeLabelVisible(at indexPath: IndexPath) -> Bool {
        return indexPath.section % 3 == 0 && !isPreviousMessageSameSender(at: indexPath)
    }
    
    func isPreviousMessageSameSender(at indexPath: IndexPath) -> Bool {
        guard indexPath.section - 1 >= 0 else { return false }
        return messageList[indexPath.section].user == messageList[indexPath.section - 1].user
    }
    
    func isNextMessageSameSender(at indexPath: IndexPath) -> Bool {
        guard indexPath.section + 1 < messageList.count else { return false }
        return messageList[indexPath.section].user == messageList[indexPath.section + 1].user
    }
    
    func setTypingIndicatorViewHidden(_ isHidden: Bool, performUpdates updates: (() -> Void)? = nil) {
        setTypingIndicatorViewHidden(isHidden, animated: true, whilePerforming: updates) { [weak self] success in
            if success, self?.isLastSectionVisible() == true {
                self?.messagesCollectionView.scrollToLastItem(animated: true)
            }
        }
    }
    
    // MARK: - UICollectionViewDataSource
    public override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let messagesDataSource = messagesCollectionView.messagesDataSource else {
            fatalError("Ouch. nil data source for messages")
        }
        
        // Very important to check this when overriding `cellForItemAt`
        // Super method will handle returning the typing indicator cell
        guard !isSectionReservedForTypingIndicator(indexPath.section) else {
            return super.collectionView(collectionView, cellForItemAt: indexPath)
        }
        
        let message = messagesDataSource.messageForItem(at: indexPath, in: messagesCollectionView)
        if case .custom = message.kind {
            let cell = messagesCollectionView.dequeueReusableCell(CustomCell.self, for: indexPath)
            cell.configure(with: message, at: indexPath, and: messagesCollectionView)
            return cell
        }
        return super.collectionView(collectionView, cellForItemAt: indexPath)
    }
    
    // MARK: - MessagesDataSource
    
    override func cellTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        if isTimeLabelVisible(at: indexPath) {
            return NSAttributedString(string: MessageKitDateFormatter.shared.string(from: message.sentDate), attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 10), NSAttributedString.Key.foregroundColor: UIColor.darkGray])
        }
        return nil
    }
    
    override func messageTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        if !isPreviousMessageSameSender(at: indexPath) {
            let name = message.sender.displayName
            return NSAttributedString(string: name, attributes: [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .caption1)])
        }
        return nil
    }
    
    override func messageBottomLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        
        //        if !isNextMessageSameSender(at: indexPath) && isFromCurrentSender(message: message) {
        //            return NSAttributedString(string: "Delivered", attributes: [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .caption1)])
        //        }
        return nil
    }
    
}

// MARK: - MessagesDisplayDelegate
extension VC_Message: MessagesDisplayDelegate {
    // MARK: - Text Messages
    func textColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return isFromCurrentSender(message: message) ? UIColor(named: "col_chat_msg")! : UIColor(named: "col_chat_msg")!
    }
    
    func detectorAttributes(for detector: DetectorType, and message: MessageType, at indexPath: IndexPath) -> [NSAttributedString.Key: Any] {
        switch detector {
        case .hashtag, .mention:
            if isFromCurrentSender(message: message) {
                return [.foregroundColor: UIColor.white]
            } else {
                return [.foregroundColor: UIColor.brand()]
            }
        default: return MessageLabel.defaultAttributes
        }
    }
    
    func enabledDetectors(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> [DetectorType] {
        return [.url, .address, .phoneNumber, .date, .transitInformation, .mention, .hashtag]
    }
    
    // MARK: - All Messages
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return isFromCurrentSender(message: message) ? UIColor(named: "col_chat_me")! : UIColor.clear
    }
    
    func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
        if self.isFromCurrentSender(message: message){
            return .bubbleOutline(UIColor.clear)
        }
        else{
            return .bubbleOutline(UIColor(named: "col_chat_target")!)
        }
    }
    
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        Utils.fetchUser(uid: message.sender.senderId) { (rusr) in
            guard let usr = rusr else { return }
            avatarView.loadImg(str: usr.thumb.isEmpty ? usr.avatar : usr.thumb, user: true)
        }
        avatarView.isHidden = isNextMessageSameSender(at: indexPath)
        avatarView.layer.borderWidth = 0
        avatarView.layer.borderColor = UIColor.brand().cgColor
    }
    
    func configureAccessoryView(_ accessoryView: UIView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
    }
    
    func configureMediaMessageImageView(_ imageView: UIImageView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        if case MessageKind.photo(let media) = message.kind, let imageURL = media.url {
            imageView.sd_imageTransition = .fade
            imageView.sd_setImage(with: imageURL, placeholderImage: nil, options: .continueInBackground, completed: nil)
        } else {
            //            imageView.pin_cancelImageDownload()
        }
    }
    
    // MARK: - Location Messages
    
    func annotationViewForLocation(message: MessageType, at indexPath: IndexPath, in messageCollectionView: MessagesCollectionView) -> MKAnnotationView? {
        return nil
    }
    
    func animationBlockForLocation(message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> ((UIImageView) -> Void)? {
        return { view in
            view.layer.transform = CATransform3DMakeScale(2, 2, 2)
            UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0, options: [], animations: {
                view.layer.transform = CATransform3DIdentity
            }, completion: nil)
        }
    }
    
    func snapshotOptionsForLocation(message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> LocationMessageSnapshotOptions {
        
        return LocationMessageSnapshotOptions(showsBuildings: true, showsPointsOfInterest: true, span: MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10))
    }
    
    // MARK: - Audio Messages
    
    func audioTintColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return self.isFromCurrentSender(message: message) ? .white : UIColor.brand()
    }
    
    func configureAudioCell(_ cell: AudioMessageCell, message: MessageType) {
    }
    
}

// MARK: - MessagesLayoutDelegate

extension VC_Message: MessagesLayoutDelegate {
    
    func cellTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        if isTimeLabelVisible(at: indexPath) {
            return 18
        }
        return 0
    }
    
    func messageTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        if isFromCurrentSender(message: message) {
            return !isPreviousMessageSameSender(at: indexPath) ? 20 : 0
        } else {
            return !isPreviousMessageSameSender(at: indexPath) ? (20 + outgoingAvatarOverlap) : 0
        }
    }
    
    func messageBottomLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return (!isNextMessageSameSender(at: indexPath) && isFromCurrentSender(message: message)) ? 16 : 0
    }
    
}

open class CustomCell: UICollectionViewCell {
    
    let label = UILabel()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupSubviews()
    }
    
    open func setupSubviews() {
        contentView.addSubview(label)
        label.textAlignment = .center
        label.font = UIFont.italicSystemFont(ofSize: 13)
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        label.frame = contentView.bounds
    }
    
    open func configure(with message: MessageType, at indexPath: IndexPath, and messagesCollectionView: MessagesCollectionView) {
        // Do stuff
        switch message.kind {
        case .custom(let data):
            guard let systemMessage = data as? String else { return }
            label.text = systemMessage
        default:
            break
        }
    }
    
}

open class CustomMessagesFlowLayout: MessagesCollectionViewFlowLayout {
    
    open lazy var customMessageSizeCalculator = CustomMessageSizeCalculator(layout: self)
    
    open override func cellSizeCalculatorForItem(at indexPath: IndexPath) -> CellSizeCalculator {
        if isSectionReservedForTypingIndicator(indexPath.section) {
            return typingIndicatorSizeCalculator
        }
        let message = messagesDataSource.messageForItem(at: indexPath, in: messagesCollectionView)
        if case .custom = message.kind {
            return customMessageSizeCalculator
        }
        return super.cellSizeCalculatorForItem(at: indexPath)
    }
    
    open override func messageSizeCalculators() -> [MessageSizeCalculator] {
        var superCalculators = super.messageSizeCalculators()
        // Append any of your custom `MessageSizeCalculator` if you wish for the convenience
        // functions to work such as `setMessageIncoming...` or `setMessageOutgoing...`
        superCalculators.append(customMessageSizeCalculator)
        return superCalculators
    }
}

open class CustomMessageSizeCalculator: MessageSizeCalculator {
    
    public override init(layout: MessagesCollectionViewFlowLayout? = nil) {
        super.init()
        self.layout = layout
    }
    
    open override func sizeForItem(at indexPath: IndexPath) -> CGSize {
        guard let layout = layout else { return .zero }
        let collectionViewWidth = layout.collectionView?.bounds.width ?? 0
        let contentInset = layout.collectionView?.contentInset ?? .zero
        let inset = layout.sectionInset.left + layout.sectionInset.right + contentInset.left + contentInset.right
        return CGSize(width: collectionViewWidth - inset, height: 44)
    }
  
}
