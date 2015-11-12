//
//  ViewController.swift
//  Beacon
//
//  Created by 仲西 渉 on 2015/10/19.
//  Copyright © 2015年 nwatabou. All rights reserved.
//

import UIKit
import CoreLocation


class ViewController: UIViewController, CLLocationManagerDelegate {
    
    //ストーリーボードで設定
    @IBOutlet var status: UILabel!
    @IBOutlet var minor: UILabel!
    @IBOutlet var distance: UILabel!
    @IBOutlet weak var quiz: UILabel!
    @IBOutlet weak var message: UILabel!

    @IBOutlet weak var nextButton: UIButton!
    @IBAction func nextButton(sender: AnyObject) {
        flg = false
        ansFlg = false
        self.answerButton.hidden = true
    }
    
    @IBOutlet weak var answerButton: UIButton!
    @IBAction func answerButton(sender: AnyObject) {
        ansFlg = true
    }
    
    
    
    var trackLocationManager : CLLocationManager!
    var beaconRegion : CLBeaconRegion!
    
    //問題を受け取っているか否かのflg
    var flg = false
    //答えるか否かのflg
    var ansFlg = false
    //問題番号の変数
    var queNo = 0
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // ロケーションマネージャを作成する
        self.trackLocationManager = CLLocationManager();
        
        // デリゲートを自身に設定
        self.trackLocationManager.delegate = self;
        
        // セキュリティ認証のステータスを取得
        let status = CLLocationManager.authorizationStatus()
        
        // まだ認証が得られていない場合は、認証ダイアログを表示
        if(status == CLAuthorizationStatus.NotDetermined) {
            
            self.trackLocationManager.requestAlwaysAuthorization();
        }
        
        // BeaconのUUIDを設定
        let uuid:NSUUID? = NSUUID(UUIDString: "00000000-7DE6-1001-B000-001C4DF13E76")
        
        //Beacon領域を作成
        self.beaconRegion = CLBeaconRegion(proximityUUID: uuid!, identifier: "net.noumenon-th")
        
        //始めはボタンを隠しておく
        self.nextButton.hidden = true
        self.answerButton.hidden = true

    }
    
    //位置認証のステータスが変更された時に呼ばれる
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        
        // 認証のステータス
        var statusStr = "";
        print("CLAuthorizationStatus: \(statusStr)")
        
        // 認証のステータスをチェック
        switch (status) {
        case .NotDetermined:
            statusStr = "NotDetermined"
        case .Restricted:
            statusStr = "Restricted"
        case .Denied:
            statusStr = "Denied"
            self.status.text   = "位置情報を許可していません"
        case .Authorized:
            statusStr = "Authorized"
            self.status.text   = "位置情報認証OK"
        default:
            break;
        }
        
        print(" CLAuthorizationStatus: \(statusStr)")
        
        //観測を開始させる
        trackLocationManager.startMonitoringForRegion(self.beaconRegion)
        
    }
    
    //観測の開始に成功すると呼ばれる
    func locationManager(manager: CLLocationManager, didStartMonitoringForRegion region: CLRegion) {
        
        print("didStartMonitoringForRegion");
        
        //観測開始に成功したら、領域内にいるかどうかの判定をおこなう。→（didDetermineState）へ
        trackLocationManager.requestStateForRegion(self.beaconRegion);
    }
    
    //領域内にいるかどうかを判定する
    func locationManager(manager: CLLocationManager, didDetermineState state: CLRegionState, forRegion inRegion: CLRegion) {
        
        switch (state) {
            
        case .Inside: // すでに領域内にいる場合は（didEnterRegion）は呼ばれない
            
            trackLocationManager.startRangingBeaconsInRegion(beaconRegion);
            // →(didRangeBeacons)で測定をはじめる
            break;
            
        case .Outside:
            
            // 領域外→領域に入った場合はdidEnterRegionが呼ばれる
            break;
            
        case .Unknown:
            
            // 不明→領域に入った場合はdidEnterRegionが呼ばれる
            break;
            
        default:
            break
        }
    }
    
    //領域に入った時
    func locationManager(manager: CLLocationManager, didEnterRegion region: CLRegion) {
        
        // →(didRangeBeacons)で測定をはじめる
        self.trackLocationManager.startRangingBeaconsInRegion(self.beaconRegion)
        self.status.text = "didEnterRegion"
        
        sendLocalNotificationWithMessage("領域に入りました")
        
    }
    
    //領域から出た時
    func locationManager(manager: CLLocationManager, didExitRegion region: CLRegion) {
        
        //測定を停止する
        self.trackLocationManager.stopRangingBeaconsInRegion(self.beaconRegion)
        
        reset()
        
        sendLocalNotificationWithMessage("領域から出ました")
        
    }
    
    
    //観測失敗
    func locationManager(manager: CLLocationManager, monitoringDidFailForRegion region: CLRegion?, withError error: NSError) {
        
        print("monitoringDidFailForRegion \(error)")
        
    }
    
    //通信失敗
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        
        print("didFailWithError \(error)")
        
    }
    
    //領域内にいるので測定をする
    func locationManager(manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], inRegion region: CLBeaconRegion) {
        //println(beacons)
//        
//        if(beacons.count == 0) { return }
        //↑複数あった場合は一番先頭のものを処理する
        
        //複数検出する場合で、一番近いものに接続させる場合
        let beacon = beacons[0]
        
        /*
        beaconから取得できるデータ
        proximityUUID   :   regionの識別子
        major           :   識別子１
        minor           :   識別子２
        proximity       :   相対距離
        accuracy        :   精度
        rssi            :   電波強度
        */
        
        
        if (beacon.proximity == CLProximity.Unknown) {
            self.distance.text = "Unknown Proximity"
            reset()
            return
        } else if (beacon.proximity == CLProximity.Immediate) {
            self.distance.text = "Immediate"
        } else if (beacon.proximity == CLProximity.Near) {
            self.distance.text = "Near"
        } else if (beacon.proximity == CLProximity.Far) {
            self.distance.text = "Far"
        }
        self.status.text   = "領域内です"
        
        self.minor.text    = "\(beacon.minor)"
        
        //flgがfalseの時はquestion出題
        if(flg == false){
            self.quiz.text = " - "
            self.message.text = " - "
            
            if(beacon.proximity == CLProximity.Immediate){
                
                //beaconのminor値によって条件分岐
                switch beacon.minor{
                case 2:
                    self.quiz.text = "百獣の王と言えば?"
                    flg = true
                    queNo = 2
                    break
                    
                case 4:
                    self.quiz.text = "鼻の長い動物と言えば?"
                    flg = true
                    queNo = 4
                    break
                    
                case 5:
                    self.quiz.text = "首の長い動物と言えば?"
                    flg = true
                    queNo = 5
                    break
                    
                default:
                    break
                }
            }
        }
        
        //flgがtrueの時は正解、不正解処理
        if(flg){
            //出題番号（queNo）と正解のminor番号との関係は、queNo + 1
            if(beacon.proximity == CLProximity.Immediate && beacon.minor != queNo){
                self.answerButton.hidden = false
                if(ansFlg){
                    if(beacon.minor == queNo + 1){
                        self.message.text = "正解！"
                        self.nextButton.hidden = false
            
                        //出題問題番号（queNo）がminor番号の最後尾（ここで言う 5）の正解は、minor番号の先頭（ここで言う 2）
                    }else if(beacon.minor == 2 && queNo == 5){
                        self.message.text = "正解！"
                        self.nextButton.hidden = false
                    }else{
                        self.message.text = "残念！不正解！"
                        ansFlg = false
                    }
                }
            }
        }
    }
    
    func reset(){
        self.status.text   = "none"
        self.minor.text    = "none"
        self.distance.text = "none"
        self.quiz.text     = "none"
        self.message.text  = "none"
    }
    
    //ローカル通知
    func sendLocalNotificationWithMessage(message: String!) {
        let notification:UILocalNotification = UILocalNotification()
        notification.alertBody = message
        
        UIApplication.sharedApplication().scheduleLocalNotification(notification)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}


