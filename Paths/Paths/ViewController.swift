//
//  ViewController.swift
//  Paths
//
//  Created by Ryan Donaldson on 9/24/17.
//  Copyright © 2017 Ryan Donaldson. All rights reserved.
//

import UIKit
import SocketIO
import LFLiveKit

class ViewController: UIViewController, LFLiveSessionDelegate {

    @IBOutlet weak var pathsLabel: UILabel!
    @IBOutlet weak var streamingButton: UIButton!
    
    let socket = SocketIOClient(socketURL: URL(string: "http://35.202.142.142:3000")!, config: [
            .log(true),
            .reconnects(true),
            .reconnectAttempts(10),
            .reconnectWait(1000),
            .forceWebsockets(true)
        ]
    )
    
    lazy var session: LFLiveSession = {
        let audioConfiguration = LFLiveAudioConfiguration.default()
        let videoConfiguration = LFLiveVideoConfiguration.defaultConfiguration(for: .medium3)
        
        let session = LFLiveSession(audioConfiguration: audioConfiguration, videoConfiguration: videoConfiguration)!
        session.delegate = self
        session.captureDevicePosition = .back
        session.preView = self.view
        return session
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func startStreamingPressed(_ sender: Any) {
        self.pathsLabel.isHidden = true
        self.streamingButton.isHidden = true
        self.view.backgroundColor = UIColor.white
        
        let secretKey = generateSecretKey(length: 10)
        socket.on(clientEvent: .connect) { data, ack in
            self.socket.emit("create", ["key": secretKey])
        }
    
        let stream = LFLiveStreamInfo()
        print("Secret Key: \(secretKey)")
        stream.url = "rtmp://35.202.142.142/stream/\(secretKey)"
        session.running = true
        session.startLive(stream)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        session.running = false
        session.stopLive()
        socket.disconnect()
    }
    
    func generateSecretKey(length: Int) -> String {
        let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let len = UInt32(letters.length)
        var randomString = ""

        for _ in 0 ..< length {
            let rand = arc4random_uniform(len)
            var nextChar = letters.character(at: Int(rand))
            randomString += NSString(characters: &nextChar, length: 1) as String
        }
        
        return randomString
    }
    
    func liveSession(_ session: LFLiveSession?, debugInfo: LFLiveDebug?) {
        print("Debug: \(debugInfo?.currentCapturedVideoCount)")
    }
    
    func liveSession(_ session: LFLiveSession?, errorCode: LFLiveSocketErrorCode) {
        print("Error: \(errorCode)")
    }
}

