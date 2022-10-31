/*

Abstract:
The commands view controller of the iOS app.
*/

import UIKit
import WatchConnectivity

class CommandsViewController: UITableViewController, DataProvider, SessionCommands {

    // List of supported commands. (Can be extended later)
    let commands: [Command] = [.sendMessage]
    var currentCommand: Command = .sendMessage // Default
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rowHeight = 42

        NotificationCenter.default.addObserver(
            self, selector: #selector(type(of: self).dataDidFlow(_:)),
            name: .dataDidFlow, object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc
    func dataDidFlow(_ notification: Notification) {
        if let commandStatus = notification.object as? CommandStatus {
            currentCommand = commandStatus.command
            tableView.reloadData()
        }
    }
}

extension CommandsViewController { // MARK: - UITableViewDelegate and UITableViewDataSoruce.
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return commands.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CommandCell", for: indexPath)
        
        let cellCommand = commands[indexPath.row]
        cell.textLabel?.text = cellCommand.rawValue
        
        return cell
    }
    
    // Perform command
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        currentCommand = commands[indexPath.row]
        switch currentCommand {
        case .sendMessage: sendMessage(message)
        case .receivedMessage: return
        case .transferFile: return
        }
    }
}

