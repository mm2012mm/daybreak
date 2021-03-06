/*
Button.swift

Copyright (c) 2014, Alice Atlas
Copyright (c) 2010, Atsushi Jike
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright notice,
this list of conditions and the following disclaimer in the documentation
and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

public class Button: NSButton {
    override public class func initialize() {
        Button.setCellClass(ButtonCell.self)
    }
    
    override public init(frame: NSRect) {
        super.init(frame: frame)
        buttonType = .MomentaryChangeButton
        bezelStyle = .RoundedBezelStyle
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    public var buttonType: NSButtonType {
        get {
            return (cell as! ButtonCell).buttonType
        }
        
        @objc(_setButtonType:)
        set(buttonType) {
            (cell as! ButtonCell).buttonType = buttonType
        }
    }
    
    override public func setButtonType(type: NSButtonType) {
        buttonType = type
    }
    
    /*var selected: NSButtonType {
        get {
            return cell!.selected
        }
        set(selected) {
            cell!.selected = selected
        }
    }*/
    
    override public var alignmentRectInsets: NSEdgeInsets {
        return NSEdgeInsetsMake(0, 0, 0, 0)
    }
    
    override public var baselineOffsetFromBottom: CGFloat {
        return 8
    }
}


public class ButtonCell: NSButtonCell {
    private var _buttonType: NSButtonType = .MomentaryLightButton
    public var buttonType: NSButtonType {
        get { return _buttonType }
        
        @objc(_setButtonType:)
        set { setButtonType(newValue) }
    }
    override public func setButtonType(type: NSButtonType) {
        super.setButtonType(type)
        _buttonType = type
    }
    
    override public func drawWithFrame(cellFrame: NSRect, inView: NSView) {
        var image: NSImage?
        let controlView = inView as? NSButton
        let alpha: CGFloat = controlView !! {$0.enabled ? 1.0 : 0.2} ?? 1.0
        let isDone = controlView &! {$0.keyEquivalent == "\r"}
        if /*NSEqualRects(cellFrame, controlView.bounds)*/ true {
            var r = NSZeroRect
            var offset: CGFloat = 0
            if buttonType == .SwitchButton {
                let highlightedFlag = highlighted ? "-Highlighted" : ""
                let selectedFlag = state == NSOnState ? "-Selected" : ""
                image = NSImage(named: "CheckBox\(selectedFlag)\(highlightedFlag).png")
                
                let imageRect = NSRect(size: image!.size)
                r.size = imageRect.size
                r.origin.y = cellFrame.origin.y + (cellFrame.size.height - r.size.height) / 2
                image!.drawInRect(r, operation: .CompositeSourceOver, fraction: (enabled ? 1.0 : 0.5), respectFlipped: true)
            } else if buttonType == .RadioButton {
                let highlightedFlag = highlighted ? "-Highlighted" : ""
                let selectedFlag = state == NSOnState ? "-Selected" : ""
                image = NSImage(named: "Radio\(selectedFlag)\(highlightedFlag).png")
                
                let imageRect = NSRect(size: image?.size ?? .zero)
                r.size = imageRect.size
                r.origin.x = cellFrame.origin.x
                r.origin.y = cellFrame.origin.y + (cellFrame.size.height - r.size.height) / 2
                image!.drawInRect(r, operation: .CompositeSourceOver, fraction: (enabled ? 1.0 : 0.5), respectFlipped: true)
            } else {
                let activeFlag = isDone ? "-Active" : ""
                let highlightedFlag = highlighted ? "-Highlighted" : ""
                let stem = "Button\(activeFlag)\(highlightedFlag)"
                let leftImage = NSImage(named: "\(stem)-Left.png")
                let centerImage = NSImage(named: "\(stem)-Center.png")
                let rightImage = NSImage(named: "\(stem)-Right.png")
                
                if leftImage != nil {
                    r.size = leftImage!.size
                    r.origin.y = (cellFrame.size.height - r.size.height) / 2
                    leftImage!.drawInRect(r, operation: .CompositeSourceOver, fraction: (enabled ? 1.0 : 0.5), respectFlipped: true)
                    offset = r.maxX
                }
                if centerImage != nil {
                    r.origin.x = leftImage?.size.width ?? 0.0
                    r.size.width = cellFrame.size.width - ((leftImage?.size.width ?? 0) + (rightImage?.size.width ?? 0))
                    r.size.height = centerImage!.size.height
                    r.origin.y = (cellFrame.size.height - r.size.height) / 2
                    centerImage!.drawInRect(r, operation: .CompositeSourceOver, fraction: (enabled ? 1.0 : 0.5), respectFlipped: true)
                    offset = r.maxX
                }
                if rightImage != nil {
                    r.origin.x = offset
                    r.size = rightImage!.size
                    r.origin.y = (cellFrame.size.height - r.size.height) / 2
                    rightImage!.drawInRect(r, operation: .CompositeSourceOver, fraction: (enabled ? 1.0 : 0.5), respectFlipped: true)
                }
            }
        }
        
        if let title: NSString = title?.ifNotEmpty {
            var size = NSZeroSize
            let frameMargin: CGFloat = 2.0
            let frame = NSMakeRect(cellFrame.origin.x + frameMargin, cellFrame.origin.y, cellFrame.size.width - frameMargin * 2, cellFrame.size.height)
            var r = frame
            let foregroundColor: NSColor
            switch buttonType {
                case .SwitchButton, .RadioButton: foregroundColor = enabled ? .whiteColor() : .grayColor()
                default:                          foregroundColor = enabled ? (highlighted ? .grayColor() : .whiteColor())
                                                                            : (isDone ? .grayColor() : .darkGrayColor())
            }
            let attributes = [NSFontAttributeName: font!,
                              NSForegroundColorAttributeName: foregroundColor]
            if buttonType == .SwitchButton || buttonType == .RadioButton {
                var i = 0
                var l = 0
                var h = 1
                size.width = frame.size.width - (image?.size.width ?? 0) + 2
                size.height = font!.pointSize + 2.0
                for i = 1; i <= title.length; i++ {
                    let t = title.substringWithRange(NSMakeRange(l, i - l))
                    let s = t.sizeWithAttributes(attributes)
                    if size.width <= s.width {
                        l = i
                        h++
                    }
                }
                size.height = size.height * CGFloat(h)
            } else {
                size = title.sizeWithAttributes(attributes)
            }
            r.size = size
            if buttonType == .SwitchButton || buttonType == .RadioButton {
                r.origin.y = frame.origin.y + (cellFrame.size.height - r.size.height) / 2
                r.origin.x = frame.origin.x + (image?.size.width ?? 0) + 3
            } else {
                r.origin.x = (frame.size.width - r.size.width) / 2
                r.origin.y = (frame.size.height - r.size.height) / 2
                r.origin.y -= 2.0
                if let image = self.image {
                    var imageRect = NSRect(size: image.size ?? .zero)
                    let margin: CGFloat = 3.0
                    if r.origin.x > (imageRect.size.width + margin) {
                        let width = imageRect.size.width + r.size.width + margin
                        imageRect.origin.x = (frame.size.width - width) / 3
                        r.origin.x = imageRect.origin.x + imageRect.size.width + margin
                    } else {
                        imageRect.origin.x = frame.origin.x
                        r.origin.x = imageRect.maxX + margin
                        size.width = frame.size.width - r.origin.x
                    }
                    imageRect.origin.y = (frame.size.height - imageRect.size.height) / 2 - 1
                    image.drawInRect(imageRect, operation: .CompositeSourceOver, fraction: (enabled ? (highlighted ? 0.5 : 1.0) : 0.5), respectFlipped: true)
                }
            }
            title.drawInRect(r, withAttributes: attributes)
        }
    }
}