//
//  ViewController.swift
//  iSstp
//
//  Created by Zheng Shao on 2/26/15.
//  Copyright (c) 2015 axot. All rights reserved.
//

import Cocoa
import AppKit
import Foundation

class ViewController: NSViewController, NSTableViewDelegate {

    @IBOutlet dynamic var status: NSTextField!
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet var arrayController: NSArrayController!
    @IBOutlet weak var deleteBtn: NSButton!
    @IBOutlet weak var editBtn: NSButton!
    @IBOutlet weak var connectBtn: NSButton!

    dynamic var accounts: [Account] = []
    let ud = UserDefaults.standard

    override func viewDidLoad() {
        super.viewDidLoad()
        status.stringValue = "Not Connected!"
        if let data = ud.object(forKey: "accounts") as? Data {
            let unarc = NSKeyedUnarchiver(forReadingWith: data)
            accounts = unarc.decodeObject(forKey: "root") as! [Account]
        }

        tableView.delegate = self
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.stop(_:)), name: NSNotification.Name(rawValue: "All Stop"), object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.updateStatus(_:)),
                                               name: NSNotification.Name(rawValue: "Connection status changed"),
                                               object: nil)

        let notif: Notification = Notification(name: Notification.Name(rawValue: "init"), object:self)
        tableViewSelectionDidChange(notif)
    }

    @IBAction func saveConfig(_ sender: AnyObject) {
        ud.set(NSKeyedArchiver.archivedData(withRootObject: accounts), forKey: "accounts")
        ud.synchronize()
    }

    @IBAction func connect(_ sender: AnyObject) {
        Sstp.sharedInstance.connect(accounts[arrayController.selectionIndex])
    }

    @IBAction func updateStatus(_ sender: AnyObject) {
        status.stringValue = Sstp.sharedInstance.status
    }

    @IBAction func stop(_ sender: AnyObject) {
        Sstp.sharedInstance.disconnect()
    }

    @IBAction func deleteBtnPressed(_ sender: AnyObject) {
        arrayController.remove(sender);
        let notif: Notification = Notification(name: Notification.Name(rawValue: "delete"), object:self)
        tableViewSelectionDidChange(notif)
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        if (arrayController.selectionIndexes.count != 1) {
            connectBtn.isEnabled = false
            editBtn.isEnabled = false
            deleteBtn.isEnabled = false
            return
        }
        connectBtn.isEnabled = true
        editBtn.isEnabled = true
        deleteBtn.isEnabled = true
    }

    override func prepare(for segue: NSStoryboardSegue, sender: Any!) {
        if (segue.identifier == "Advanced Options") {
            let optionViewController = segue.destinationController as! OptionViewController

            optionViewController.account = accounts[arrayController.selectionIndex]
            optionViewController.superViewController = self
        }
    }
}
