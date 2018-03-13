
import Foundation
import UIKit
import JustLayout
import Dispatch

public let kDefaultToastCornerRadius: CGFloat = 3
public let kDefaultToastDuration: TimeInterval = 2.5
public let kDefaultToastTopPadding: CGFloat = 50
public let kDefaultToastBottomPadding: CGFloat = 50

private let kDefaultToastAnimationDuration: TimeInterval = 0.25
private let kSharedToastQueue: DispatchQueue = DispatchQueue.init(label: "cn.meniny.Toast.queue")
private let kSharedToastSemaphore: DispatchSemaphore = DispatchSemaphore.init(value: 1)

open class Toast {
    
    /// Toast Position
    ///
    /// - top: At top with padding
    /// - center: At center with vertically offset
    /// - bottom: At bottom with padding
    public enum Position: Equatable {
        case top(CGFloat)
        case center(CGFloat)
        case bottom(CGFloat)
        
        public static func ==(lhs: Toast.Position, rhs: Toast.Position) -> Bool {
            switch (lhs, rhs) {
            case let (.top(a), .top(b)):
                return a == b
            case let (.bottom(a), .bottom(b)):
                return a == b
            case let (.center(a), .center(b)):
                return a == b
            default:
                return false
            }
        }
    }
    
    public enum QueueType {
        case shared, specified(DispatchQueue, DispatchSemaphore)
    }
    
    // MARK: - OBJECTS
    
    open let text: String
    open let position: Toast.Position
    open let queueType: Toast.QueueType
    open private(set) var duration: TimeInterval = kDefaultToastDuration
    open private(set) var hiddingCompletion: (() -> Void)?
    
    public var queue: DispatchQueue {
        switch self.queueType {
        case .specified(let q, _):
            return q
        default:
            return kSharedToastQueue
        }
    }
    
    public var semaphore: DispatchSemaphore {
        switch self.queueType {
        case .specified(_, let s):
            return s
        default:
            return kSharedToastSemaphore
        }
    }
    
    open var hasBorder: Bool {
        get {
            return self.contentView.hasBorder
        }
        set {
            self.contentView.hasBorder = newValue
        }
    }
    open var roundCornerRadius: CGFloat {
        get {
            return self.contentView.layer.cornerRadius
        }
        set {
            self.contentView.layer.cornerRadius = newValue
        }
    }
    open var borderColor: UIColor {
        get {
            return self.contentView.line.backgroundColor ?? UIColor.clear
        }
        set {
            self.contentView.line.backgroundColor = newValue
        }
    }
    open var backgroundColor: UIColor {
        get {
            return self.contentView.backgroundColor ?? UIColor.clear
        }
        set {
            self.contentView.backgroundColor = newValue
        }
    }
    open var textColor: UIColor {
        get {
            return self.contentView.label.textColor
        }
        set {
            self.contentView.label.textColor = newValue
        }
    }
    open var font: UIFont {
        get {
            return self.contentView.label.font
        }
        set {
            self.contentView.label.font = newValue
        }
    }
    open var textAlignment: NSTextAlignment {
        get {
            return self.contentView.label.textAlignment
        }
        set {
            self.contentView.label.textAlignment = newValue
        }
    }
    
    open let contentView: ToastContentView = ToastContentView.init()
    open private(set) var containerView: UIView?
    
    public init(_ text: String,
                at position: Toast.Position = Toast.Position.bottom(kDefaultToastBottomPadding),
                queue order: Toast.QueueType = Toast.QueueType.shared) {
        self.text = text
        self.position = position
        self.queueType = order
        self.contentView.text = text
    }
    
    // MARK: - PUBLIC FUNCTIONS
    
    /// Show a toast
    ///
    /// - Parameters:
    ///   - text: The text string
    ///   - view: Container view
    ///   - animated: If animated
    ///   - duration: Duration time
    ///   - position: Toast postion
    ///   - queue: Order in queue
    ///   - bordered: If has bottom line
    ///   - rounded: Corner radius
    ///   - hiddingClosure: Hidding action
    /// - Returns: A `Toast`
    @discardableResult
    open class func show(_ text: String,
                         to view: UIView? = nil,
                         animated: Bool = true,
                         duration: TimeInterval = kDefaultToastDuration,
                         at position: Toast.Position = .bottom(kDefaultToastBottomPadding),
                         queue: Toast.QueueType = .shared,
                         bordered: Bool = false,
                         rounded: CGFloat = kDefaultToastCornerRadius,
                         hiddingClosure: (() -> Void)? = nil) -> Toast {
        let toast = Toast.init(text, at: position, queue: queue)
        toast.hasBorder = bordered
        toast.roundCornerRadius = rounded
        toast.show(to: view, animated: animated, duration: duration, hiddingClosure: hiddingClosure)
        return toast
    }
    
    /// Show this toast
    ///
    /// - Parameters:
    ///   - view: Container view
    ///   - animated: If animated
    ///   - duration: Duration time
    ///   - bordered: If has bottom line
    ///   - hiddingClosure: Hidding action
    open func show(to view: UIView? = nil,
                   animated: Bool = true,
                   duration: TimeInterval = kDefaultToastDuration,
                   hiddingClosure: (() -> Void)? = nil) {
        
        self.duration = duration
        self.containerView = view ?? UIApplication.shared.keyWindow
        self.hiddingCompletion = hiddingClosure
        
        guard self.containerView != nil else {
            print("Cannot find the container view for toast")
            return
        }
        
        self.ordered_show(animated: animated)
    }
    
    /// Hide toast manually
    ///
    /// - Parameters:
    ///   - animated: If animated
    ///   - completion: Completion closure
    open func hide(animated: Bool = true, completion: (() -> Void)? = nil) {
        guard !self.waitingForAutoHidding else { return }
        self.manually_hiding(animated: animated, completion: completion)
    }
    
    // MARK: - PRIVATE FUNCTIONS
    
    private func ordered_show(animated: Bool) {
        self.queue.async {
            self.semaphore.wait()
            DispatchQueue.main.async {
                self.contentView.text = self.text
                self.show_layout()
                if animated {
                    self.show_with_animation()
                } else {
                    self.show_without_animation()
                }
            }
        }
    }
    
    /// Layout the content view
    private func show_layout() {
        self.containerView?.translates(subViews: self.contentView)
        self.contentView.left(>=16).right(>=16)
        switch self.position {
        case .top(let padding):
            self.contentView.top(padding).centerHorizontally()
            break
        case .bottom(let padding):
            self.contentView.bottom(padding).centerHorizontally()
            break
        case .center(let offset):
            self.contentView.centerHorizontally().centerVertically(offset)
            break
        }
    }
    
    /// Animation - SHOW
    private func show_with_animation() {
        self.contentView.alpha = 0
        UIView.animate(withDuration: kDefaultToastAnimationDuration, animations: {
            self.contentView.alpha = 1
        }) { (f) in
//            if f {
//            }
            self.auto_hide()
        }
    }
    
    /// NO Animation - SHOW
    private func show_without_animation() {
        self.contentView.alpha = 1
        self.auto_hide()
    }
    
    private var waitingForAutoHidding: Bool = false
    
    /// Auto hidding
    private func auto_hide() {
        guard self.duration > 0 else { return }
        self.waitingForAutoHidding = true
        DispatchQueue.global(qos: .default).asyncAfter(deadline: .now() + self.duration, execute: {
            self.manually_hiding(animated: true, completion: nil)
        })
    }
    
    private func manually_hiding(animated: Bool, completion: (() -> Void)?) {
        if completion != nil {
            self.hiddingCompletion = completion
        }
        
        if animated {
            self.hide_with_animation()
        } else {
            self.hide_without_animation()
        }
    }
    
    /// Aniamtion - HIDE
    private func hide_with_animation() {
        DispatchQueue.main.async {
            self.contentView.alpha = 1
            UIView.animate(withDuration: kDefaultToastAnimationDuration, animations: {
                self.contentView.alpha = 0
            }) { (f) in
//                if f {
//                }
                self.remove()
            }
        }
    }
    
    /// NO Animation - HIDE
    private func hide_without_animation() {
        DispatchQueue.main.async {
            self.contentView.alpha = 0
            self.remove()
        }
    }
    
    /// Remove toast
    private func remove() {
        DispatchQueue.main.async {
            self.waitingForAutoHidding = false
            self.contentView.removeFromSuperview()
            self.containerView = nil
            self.hiddingCompletion?()
            self.semaphore.signal()
        }
    }
}

// MARK: - VIEWS

open class ToastBaseView: UIView {
    public init() {
        super.init(frame: .zero)
        self.config()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.config()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.config()
    }
    
    public func config() {
        self.clipsToBounds = true
    }
}

open class ToastContentView: ToastBaseView {
    
    open let line: UIView = UIView.init()
    open let label: UILabel = UILabel.init()
    
    open var hasBorder: Bool {
        get {
            return !self.line.isHidden
        }
        set {
            self.line.isHidden = !newValue
        }
    }
    
    open var text: String {
        get {
            return self.label.text ?? ""
        }
        set {
            self.label.text = newValue
        }
    }
    
    public override func config() {
        super.config()
        
        self.translates(subViews: self.line, self.label)
        self.layout(
            8,
            |-8-self.label.height(>=21)-8-|,
            7,
            |-0-self.line.height(1)-0-|,
            0
        )
        
        self.label.textColor = UIColor.lightText
        self.label.textAlignment = .center
        self.label.font = UIFont.systemFont(ofSize: 14)
        self.label.numberOfLines = 0
        
        self.line.isHidden = true
        self.line.backgroundColor = UIColor(red: 0.18, green: 0.73, blue: 0.89, alpha: 1.00)
        
        self.backgroundColor = UIColor.init(white: 0, alpha: 0.8)
    }
}
