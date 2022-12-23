import UIKit
import CollectionKit
import Firebase
import FirebaseFirestoreSwift
import SwipeCellKit

class VC_Chat: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var v_searchBar: UIView!
    
    var isTypingSearch: Bool = false
    var chatData: [MockChannel] = []
    override func viewDidLoad() {
        super.viewDidLoad()

        initComponents()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView.reloadData()
    }
    
    func initComponents(){
        addSwipeRight()
        channelsUpdated()
        
        v_searchBar.makeRoundView(r: 4)
        searchBar.autocapitalizationType = .none
        searchBar.backgroundImage = UIImage()
        if let txtField = searchBar.value(forKey: "searchField") as? UITextField{
            txtField.font = UIFont.cFont_regular(size: 16)
            if let lView = txtField.leftView as? UIImageView{
                lView.image = UIImage(named: "mic_search_bar")
            }
            txtField.backgroundColor = UIColor.clear
        }
        searchBar.delegate = self

        tableView.register(UINib(nibName: "cv_chat", bundle: nil), forCellReuseIdentifier: "cv_chat")
        ChatManager.shared.loadChannels()
        ChatManager.shared.delegateChatChannels = self
    }
    
    @IBAction func opNewChat(_ sender: Any) {
        let sb = UIStoryboard(name: "Chat", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "VC_New_Message") as! VC_New_Message
        vc.modalPresentationStyle = .pageSheet
        
        vc.opSendMessageAction = { (usr, msg) in
            self.openMessage(user: usr)
        }
        
        self.present(vc, animated: true, completion: nil)
    }
    
    @IBAction func opBack(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
}

extension VC_Chat: UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chatData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cv_chat", for: indexPath) as! cv_chat
        
        let chn = chatData
            .sorted { (item1, item2) -> Bool in
                item1.lastMsg.sentDate.timeIntervalSince1970 > item2.lastMsg.sentDate.timeIntervalSince1970
            }[indexPath.row]
        
        cell.setChannel(chn: chn)
        cell.delegate = self
        cell.selectionStyle = .none
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? cv_chat else { return }
        guard let chn = cell.channel else { return }
        
        self.openMessage(chn: chn)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
}

extension VC_Chat: ChannelsUpdated{
    func channelsUpdated(){
        chatData = ChatChannels.values
            .filter{
                $0.lastMsg != nil && $0.deletedTime < $0.lastMsg.sentDate.timeIntervalSince1970
            }
        self.tableView.reloadData()
    }
}

extension VC_Chat: SwipeTableViewCellDelegate{
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        guard orientation == .right else { return nil }
        guard let cell = tableView.cellForRow(at: indexPath) as? cv_chat else { return nil }
        guard let chn = cell.channel else { return nil }
        guard (CUID) != nil else { return nil }
        
        let deleteAction = SwipeAction(style: .destructive, title: ""){ action, indexPath in
            chn.delete()
            action.fulfill(with: .delete)
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
        deleteAction.image = UIImage(named: "nic_close")
        deleteAction.backgroundColor = UIColor.error()
        deleteAction.font = UIFont.systemFont(ofSize: 1)

        return [deleteAction]
    }
}

extension VC_Chat: UISearchBarDelegate {
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
        isTypingSearch = true
        
        self.channelsUpdated()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let text = searchBar.text, !text.isEmpty else { return }
        searchBar.resignFirstResponder()
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(false, animated: true)
        searchBar.resignFirstResponder()
        isTypingSearch = false
        
        self.channelsUpdated()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        print("~>Cancel button clicked")
        searchBar.endEditing(true)
        isTypingSearch = false
        
        self.channelsUpdated()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        guard searchText.count >= 2 else {
            self.channelsUpdated()
            return
        }
        
        chatData = ChatChannels.values
            .filter{
                $0.lastMsg != nil && $0.deletedTime < $0.lastMsg.sentDate.timeIntervalSince1970
            }
            .filter{
                switch($0.lastMsg.kind){
                    case .text(let txt):
                        if txt.lowercased().contains(searchText.lowercased()){
                            return true
                        }
                        else if let tuser = $0.targetUser, (tuser.uname.lowercased().contains(searchText.lowercased()) || tuser.fname.lowercased().contains(searchText.lowercased())){
                            return true
                        }
                        break
                    default:
                        break
                }
                return false
            }
        
        self.tableView.reloadData()
    }
}
