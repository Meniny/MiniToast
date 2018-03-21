//
//  ViewController.swift
//  Sample
//
//  Created by 李二狗 on 2018/3/13.
//  Copyright © 2018年 Meniny Lab. All rights reserved.
//

import UIKit
import Toast
import JustLayout

let kAlerts = [
    "Greetings! 😀",
    "Error: failed to save your photo.",
    "Welcome to the Swift community. Together we are working to build a programming language to empower everyone to turn their ideas into apps on any platform.",
    "Announced in 2014, the Swift programming language has quickly become one of the fastest growing languages in history.\nSwift makes it easy to write software that is incredibly fast and safe by design.\nOur goals for Swift are ambitious: we want to make programming simple things easy, and difficult things possible.",
    #file
]

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.view.backgroundColor = UIColor(red:0.95, green:0.65, blue:0.21, alpha:1.00)
    }
    
    @IBOutlet weak var toast: UIBarButtonItem!
    @IBAction func showToast(_ sender: Any) {
        self.randomToast()
    }
    
    func randomToast() {
        let index = Int(arc4random_uniform(UInt32(kAlerts.count)))
        Toast.show(kAlerts[index],
                   to: self.view,
                   animated: true,
                   duration: 3,
                   at: .bottom(30),
                   hiddingClosure: nil)
    }
}

class NextViewController: UIViewController {
    
    let sub = UIView.init()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.view.backgroundColor = UIColor(red:0.13, green:0.51, blue:0.16, alpha:1.00)
        
        self.view.translates(subViews: self.sub)
        self.sub.centerInContainer().size(80%)
        self.sub.backgroundColor = UIColor(red:0.85, green:0.74, blue:0.67, alpha:1.00)
    }
    
    @IBOutlet weak var toast: UIBarButtonItem!
    @IBAction func showToast(_ sender: Any) {
        self.randomToast()
    }
    
    private let aQueue: DispatchQueue = DispatchQueue.init(label: "cn.meniny.Next.queue")
    private let aSemaphore: DispatchSemaphore = DispatchSemaphore.init(value: 1)
    
    func randomToast() {
        let index = Int(arc4random_uniform(UInt32(kAlerts.count)))
        
        let dark = #colorLiteral(red: 0.60, green:0.50, blue:0.37, alpha:1.00)
        let light = #colorLiteral(red: 1.00, green:0.91, blue:0.72, alpha:1.00)
        
        var config = ToastConfig.default
//        config.position = .center(0)
        config.backgroundColor = light
        config.textColor = dark
        config.cornerRadius = 5
        config.borderType = .edges(1, dark)
        config.queueType = .specified(aQueue, aSemaphore)
        let toast = Toast.init(kAlerts[index], configuration: config)
        toast.show(to: self.sub, animated: true, duration: 3, hiddingClosure: nil)
    }
}

