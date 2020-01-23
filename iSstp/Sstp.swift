//
//  Sstp.swift
//  iSstp
//
//  Created by Ezra Bühler on 06/08/17.
//  Copyright © 2017 axot. All rights reserved.
//

import Cocoa

class Sstp: NSObject {
    static let sharedInstance = Sstp()

    let settings = UserDefaults.standard
    var status: String = ""
    var account: Account?
    var statusTimer: Timer?
    var connectTimer: Timer?
    var connectCounter = 0
    let appDelegate = NSApplication.shared.delegate as! AppDelegate

    private override init() {}

    func connect(_ account: Account) {
        self.account = account
        let qualityOfServiceClass = DispatchQoS.QoSClass.background
        let backgroundQueue = DispatchQueue.global(qos: qualityOfServiceClass)

        updateStatus("Trying to connect to \(self.account!.server)...")
        NotificationCenter.default.post(name: Notification.Name(rawValue: "Connection status changed"), object: nil)

        backgroundQueue.async(execute: {
            let task = Process()
            let base = Bundle.main.resourcePath

            task.launchPath = base! + "/helper"

            var sstpcPath = base! + "/sstpc"
            if self.settings.bool(forKey: "useExtSstpc") {
                sstpcPath = self.settings.string(forKey: "sstpcPath")!
            }

            task.arguments = [
                "start",
                sstpcPath + " " + self.account!.doesSkipCertWarn!,
                self.account!.user,
                "'" + self.account!.pass.replacingOccurrences(of: "'", with: "'\"'\"'") + "'",
                self.account!.server,
                self.account!.option!
            ]

            let pipe = Pipe()
            task.standardOutput = pipe
            task.launch()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output: String = NSString(data: data, encoding: String.Encoding.utf8.rawValue)! as String

            if output.range(of: "server certificate failed") != nil {
                if (self.statusTimer != nil) {
                    self.statusTimer?.invalidate()
                    self.statusTimer = nil
                }

                self.updateStatus("Verification of server certificate failed")
            }

            print(output, terminator: "")
        })
        self.connectTimer = Timer.scheduledTimer(
            timeInterval: 1, target: self, selector: #selector(connected), userInfo: nil,
            repeats: true)
    }

    func sstpIp() -> String? {
        let result: String = runCommand("/sbin/ifconfig ppp0 | grep 'inet' | awk '{ print $2}'")
      if result.range(of: "ppp0") == nil && (!result.isEmpty) {
            return result
        }
        return nil
    }

  @objc func connected() {
        connectCounter += 1

        let timeout = connectCounter >= 10

        if sstpIp() == nil && !timeout {
            return
        }
        //show connected icon:
        if(!timeout) {
            appDelegate.toggleStatusIconOn()
        }
        connectTimer?.invalidate()
        connectTimer = nil
        connectCounter = 0

        if account!.addRoute && !timeout {
            let cmd = Bundle.main.resourcePath! + "/helper"
            let ret = runCommand("\(cmd) route \(account!.route!)")
            print(ret)
        }
        checkStatus()
    }

  @objc func checkStatus() {
        if let ip = sstpIp() {
            updateStatus("Connected to server, your ip is: " + ip)
        } else {
            updateStatus("Not Connected!")
        }

        if self.statusTimer == nil {
            self.statusTimer = Timer.scheduledTimer(
                timeInterval: 5, target: self, selector: #selector(checkStatus), userInfo: nil,
                repeats: true)
        }
    }

    func disconnect() {
        if (self.statusTimer != nil) {
            self.statusTimer?.invalidate()
            self.statusTimer = nil
        }

        //toggle connected icon off:
        appDelegate.toggleStatusIconOff()

        let qualityOfServiceClass = DispatchQoS.QoSClass.background
        let backgroundQueue = DispatchQueue.global(qos: qualityOfServiceClass)

        backgroundQueue.async(execute: {
            let task = Process()
            let base = Bundle.main.resourcePath

            task.launchPath = base! + "/helper"

            task.arguments = ["stop"]

            let pipe = Pipe()
            task.standardOutput = pipe
            task.launch()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output: String = NSString(data: data, encoding: String.Encoding.utf8.rawValue)! as String

            print(output, terminator: "")
        })
        updateStatus("Not Connected!")
    }

    func runCommand(_ cmd: String) -> String {
        let task = Process()

        task.launchPath = "/bin/sh"
        task.arguments = ["-c", cmd]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output: String = NSString(data: data, encoding: String.Encoding.utf8.rawValue)! as String
        return output
    }

    func updateStatus(_ s: String) {
        status = s
        NotificationCenter.default.post(name: Notification.Name(rawValue: "Connection status changed"), object: nil)
    }

}
