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
import CoreLocation

class ViewController: UIViewController {

    @IBOutlet weak var pathsLabel: UILabel!
    @IBOutlet weak var streamingButton: UIButton!
    
    @IBOutlet weak var hudView: UIView!
    @IBOutlet weak var objectDetectLabel: UILabel!
    
    let socket = SocketIOClient(socketURL: URL(string: "http://35.202.142.142:3000")!, config: [
            .log(true),
            .reconnects(true),
            .reconnectAttempts(10),
            .reconnectWait(1000),
            .forceWebsockets(true)
        ]
    )
    
    let locationManager = CLLocationManager()
    
    lazy var session: LFLiveSession = {
        let audioConfiguration = LFLiveAudioConfiguration.default()
        let videoConfiguration = LFLiveVideoConfiguration.defaultConfiguration(for: .medium3)
        
        let session = LFLiveSession(audioConfiguration: audioConfiguration, videoConfiguration: videoConfiguration)!
        session.delegate = self
        session.captureDevicePosition = .back
        session.preView = self.view
        return session
    }()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.hudView.isHidden = true
        self.objectDetectLabel.isHidden = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.locationManager.requestWhenInUseAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            self.locationManager.delegate = self
            self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
            self.locationManager.startUpdatingLocation()
        }
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
        socket.connect()
        socket.on(clientEvent: .connect) { data, ack in
            self.socket.emit("create", ["key": secretKey])
            self.socket.emit("stream_started", ["key": secretKey])
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
}

extension ViewController: LFLiveSessionDelegate {
    func liveSession(_ session: LFLiveSession?, debugInfo: LFLiveDebug?) {
        print("Debug: \(debugInfo?.currentCapturedVideoCount)")
    }
    
    func liveSession(_ session: LFLiveSession?, errorCode: LFLiveSocketErrorCode) {
        print("Error: \(errorCode)")
    }
}

extension ViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let newLocation = manager.location?.coordinate
        let latitude = newLocation?.latitude
        let longitude = newLocation?.longitude
        // Rework this to include secret stream key for user
        self.socket.emit("location_update", ["latitude": latitude, "longitude": longitude])
    }
}

