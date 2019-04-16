
import Foundation
import UIKit
import JustLayout
import Dispatch

public let kDefaultToastCornerRadius: CGFloat = 3
public let kDefaultToastDuration: TimeInterval = 2.5
public let kDefaultToastTopPadding: CGFloat = 50
public let kDefaultToastBottomPadding: CGFloat = 50
public let kDefaultToastBackgroundColor: UIColor = UIColor.init(white: 0, alpha: 0.8)
public let kDefaultToastTextColor: UIColor = UIColor.lightText
public let kDefaultToastFont: UIFont = UIFont.systemFont(ofSize: 14)

private let kDefaultToastAnimationDuration: TimeInterval = 0.25
private let kSharedToastQueue: DispatchQueue = DispatchQueue.init(label: "cn.meniny.Toast.queue")
private let kSharedToastSemaphore: DispatchSemaphore = DispatchSemaphore.init(value: 1)

/// Toast Position
///
/// - top: At top with padding
/// - center: At center with vertically offset
/// - bottom: At bottom with padding
public enum ToastPosition: Equatable {
    case top(CGFloat)
    case center(CGFloat)
    case bottom(CGFloat)
    
    public static func ==(lhs: ToastPosition, rhs: ToastPosition) -> Bool {
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

public enum ToastQueueType {
    case shared, specified(DispatchQueue, DispatchSemaphore)
}

public enum ToastBorderPosition {
    case top, bottom
}

public enum ToastBorderType: Equatable {
    case none
    case single(ToastBorderPosition, UIColor)
    case edges(CGFloat, UIColor)
    
    public static func ==(lhs: ToastBorderType, rhs: ToastBorderType) -> Bool {
        switch (lhs, rhs) {
        case (.none, .none):
            return true
        case let (.single(a, c), .single(b, d)):
            return a == b && c == d
        case let (.edges(a, c), .edges(b, d)):
            return a == b && c == d
        default:
            return false
        }
    }
}

public struct ToastConfig {
    public var position: ToastPosition = .bottom(kDefaultToastBottomPadding)
    public var queueType: ToastQueueType = .shared
    public var borderType: ToastBorderType = .none
    public var duration: TimeInterval = kDefaultToastDuration
    public var cornerRadius: CGFloat = kDefaultToastCornerRadius
    public var backgroundColor: UIColor = kDefaultToastBackgroundColor
    public var textColor: UIColor = kDefaultToastTextColor
    public var font: UIFont = kDefaultToastFont
    public var textAlignment: NSTextAlignment = .center
    
    public static var `default`: ToastConfig {
        let config = ToastConfig.init()
        return config
    }
}

open class Toast {
    // MARK: - OBJECTS
    
    open var text: String
    open var configuration: ToastConfig
    open private(set) var hiddingCompletion: (() -> Void)?
    
    public var queue: DispatchQueue {
        switch self.configuration.queueType {
        case .specified(let q, _):
            return q
        default:
            return kSharedToastQueue
        }
    }
    
    public var semaphore: DispatchSemaphore {
        switch self.configuration.queueType {
        case .specified(_, let s):
            return s
        default:
            return kSharedToastSemaphore
        }
    }
    
    public let contentView: ToastContentView = ToastContentView.init()
    open private(set) var containerView: UIView?
    
    public init(_ text: String, configuration: ToastConfig) {
        self.text = text
        self.configuration = configuration
        self.contentView.text = self.text
        self.apply(config: self.configuration)
    }
    
    public func apply(config: ToastConfig) {
        self.contentView.layer.cornerRadius = config.cornerRadius
        self.contentView.borderType = config.borderType
        self.contentView.backgroundColor = config.backgroundColor
        self.contentView.label.textColor = config.textColor
        self.contentView.label.textAlignment = config.textAlignment
        self.contentView.label.font = config.font
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
    ///   - border: Border type
    ///   - corner: Corner radius
    ///   - queue: Ordered in queue
    ///   - hiddingClosure: Hidding action
    /// - Returns: A `Toast`
    @discardableResult
    open class func show(_ text: String,
                         to view: UIView? = nil,
                         animated: Bool = true,
                         duration: TimeInterval = kDefaultToastDuration,
                         at position: ToastPosition = .bottom(kDefaultToastBottomPadding),
                         border: ToastBorderType = .none,
                         corner: CGFloat = kDefaultToastCornerRadius,
                         queue: ToastQueueType = .shared,
                         hiddingClosure: (() -> Void)? = nil) -> Toast {
        var config = ToastConfig.default
        config.duration = duration
        config.position = position
        config.borderType = border
        config.cornerRadius = corner
        config.queueType = queue
        let toast = Toast.init(text, configuration: config)
        toast.show(to: view, animated: animated, duration: duration, hiddingClosure: hiddingClosure)
        return toast
    }
    
    /// Show this toast
    ///
    /// - Parameters:
    ///   - view: Container view
    ///   - animated: If animated
    ///   - duration: Duration time
    ///   - hiddingClosure: Hidding action
    open func show(to view: UIView? = nil,
                   animated: Bool = true,
                   duration: TimeInterval = kDefaultToastDuration,
                   hiddingClosure: (() -> Void)? = nil) {
        
        self.configuration.duration = duration
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
        switch self.configuration.position {
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
        guard self.configuration.duration > 0 else { return }
        self.waitingForAutoHidding = true
        DispatchQueue.global(qos: .default).asyncAfter(deadline: .now() + self.configuration.duration, execute: {
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
    
    public let line: UIView = UIView.init()
    public let label: UILabel = UILabel.init()
    
    private var _borderType: ToastBorderType = .none
    open var borderType: ToastBorderType {
        get {
            return self._borderType
        }
        set {
            self._borderType = newValue
            switch self.borderType {
            case .none:
                self.line.isHidden = true
                self.layer.borderWidth = 0
                break
            case .single(let position, let color):
                
                self.layer.borderWidth = 0
                self.line.isHidden = false
                self.line.backgroundColor = color
                self.line.removeAllConstraints()
                self.line.left(0).right(0).height(1)
                
                switch position {
                case .top:
                    self.line.top(0)
                    break
                case .bottom:
                    self.line.bottom(0)
                    break
                }
                break
            case .edges(let w, let color):
                self.line.isHidden = true
                self.layer.borderWidth = w
                self.layer.borderColor = color.cgColor
                break
            }
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
            8
        )
        self.label.numberOfLines = 0
    }
}
