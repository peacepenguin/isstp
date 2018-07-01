//
//  AppDelegate.swift
//  iSstp
//
//  Created by Zheng Shao on 2/26/15.
//  Copyright (c) 2015 axot. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    @IBOutlet dynamic var myMenu: NSMenu!
    var statusItem: NSStatusItem?

    override func awakeFromNib()
    {
        statusItem = NSStatusBar.system().statusItem(withLength: 20)
        let image: NSImage = NSImage(named: "statusbar_icon")!

        statusItem?.title = "Status Menu"
        statusItem?.image = image
        statusItem?.highlightMode = true
        statusItem?.menu = myMenu

        var accounts: [Account] = []

        let ud = UserDefaults.standard
        if let data = ud.object(forKey: "accounts") as? Data {
            let unarc = NSKeyedUnarchiver(forReadingWith: data)
            accounts = unarc.decodeObject(forKey: "root") as! [Account]
        }

        if accounts.isEmpty {
            return
        }

        myMenu.insertItem(NSMenuItem.separator(), at: 0)

        for account in accounts {
            let menuItem = NSMenuItem(title: "Connect \(account.display)", action: #selector(AppDelegate.connect),
                                      keyEquivalent: "")
            menuItem.target = self
            menuItem.representedObject = account
            myMenu.insertItem(menuItem, at: 0)
        }
    }

    func connect(_ sender: NSMenuItem) {
        let account = sender.representedObject as! Account
        Sstp.sharedInstance.connect(account)
        sender.action = #selector(AppDelegate.disconnect)
        sender.title = "Disconnect \(account.display)"
    }

    func disconnect(_ sender: NSMenuItem) {
        let account = sender.representedObject as! Account
        Sstp.sharedInstance.disconnect()
        sender.action = #selector(AppDelegate.connect)
        sender.title = "Connect \(account.display)"
    }

    func doScriptWithAdmin(_ inScript:String) {
        let script = "do shell script \"/usr/bin/sudo /bin/sh \(inScript)\" with administrator privileges"
        let appleScript = NSAppleScript(source: script)
        appleScript!.executeAndReturnError(nil)
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let ud = UserDefaults.standard
        let dafaults: [String: Any] = [
            "useExtSstpc": true,
            "sstpcPath": "/usr/local/sbin/sstpc"
        ]
        ud.register(defaults: dafaults)

        let base = Bundle.main.resourcePath
        if FileManager.default.fileExists(atPath: base! + "/installed") == false {
            doScriptWithAdmin(base! + "/install.sh")
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
    }

    @IBAction func open(_ sender: NSMenuItem) {
        NSApplication.shared().unhide(self)
        NSApp.activate(ignoringOtherApps: true)
        NotificationCenter.default.post(name: Notification.Name(rawValue: "Window Open"), object: nil)
    }

    @IBAction func quit(_ sender: NSMenuItem) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "All Stop"), object: nil)
        NSApplication.shared().terminate(self)
    }
}
