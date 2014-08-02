/*
SBButton.swift

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

class SBButton: SBView, NSCoding {
    private var _title: NSString?
    var image: NSImage?
    var disableImage: NSImage?
    var backImage: NSImage?
    var backDisableImage: NSImage?
    var action = Selector() //!!! should be Selector? (= nil) but the swift compiler doesn't generate the objc property declaration in that case for now
    private var _enabled = true
    private var _pressed = false
    var keyEquivalent: String?
    var keyEquivalentModifierMask: Int = 0
    
    var enabled: Bool {
        get { return _enabled }
        set(isEnabled) {
            if _enabled != isEnabled {
                _enabled = isEnabled
                self.needsDisplay = true
            }
        }
    }
    var pressed: Bool {
        get { return _pressed }
        set(isPressed) {
            if _pressed != isPressed {
                _pressed = isPressed
                self.needsDisplay = true
            }
        }
    }
    var title: NSString? {
        get { return _title }
        set(inTitle) {
            if _title != inTitle {
                _title = inTitle
                self.setNeedsDisplayInRect(self.bounds)
            }
        }
    }
    override var toolbarVisible: Bool {
        get { return super.toolbarVisible }
        set(isToolbarVisible) {
            if toolbarVisible != isToolbarVisible {
                super.toolbarVisible = isToolbarVisible
                self.needsDisplay = true
            }
        }
    }
    
    init(frame: NSRect) {
        super.init(frame: frame)
    }

    // NSCoding Protocol
    
    init(coder decoder: NSCoder) {
        super.init(coder: decoder)
        if decoder.allowsKeyedCoding {
            image = decoder.decodeObjectForKey("image") as? NSImage
            disableImage = decoder.decodeObjectForKey("disableImage") as? NSImage
            backImage = decoder.decodeObjectForKey("backImage") as? NSImage
            backDisableImage = decoder.decodeObjectForKey("backDisableImage") as? NSImage
            if let action = decoder.decodeObjectForKey("action") as? NSString {
                self.action = Selector(action)
            }
            keyEquivalent = decoder.decodeObjectForKey("keyEquivalent") as? NSString
            if decoder.containsValueForKey("enabled") {
                _enabled = decoder.decodeBoolForKey("enabled")
            }
            if decoder.containsValueForKey("keyEquivalentModifierMask") {
                keyEquivalentModifierMask = decoder.decodeIntegerForKey("keyEquivalentModifierMask")
            }
        }
    }
    
    override func encodeWithCoder(coder: NSCoder) {
        super.encodeWithCoder(coder)
        if image {
            coder.encodeObject(image!, forKey:"image")
        }
        if disableImage {
            coder.encodeObject(disableImage!, forKey:"disableImage")
        }
        if backImage {
            coder.encodeObject(backImage!, forKey:"backImage")
        }
        if backDisableImage {
            coder.encodeObject(backDisableImage!, forKey:"backDisableImage")
        }
        //if action {
        //    coder.encodeObject(String(_sel: action!), forKey:"action")
        //}
        coder.encodeObject(String(_sel: action), forKey:"action")
        if keyEquivalent {
            coder.encodeObject(keyEquivalent, forKey:"keyEquivalent")
        }
        coder.encodeBool(enabled, forKey: "enabled")
        coder.encodeInteger(keyEquivalentModifierMask, forKey: "keyEquivalentModifierMask")
    }
    
    // Exec
    
    func executeAction() {
        if let target = self.target {
            //if let action = self.action {
                //var sel = action
                if target.respondsToSelector(action) {
                    SBPerform(target, action, self)
                }
            //}
        }
    }
    
    // Event
    
    override func mouseDown(event: NSEvent) {
        if enabled {
            self.pressed = true
        }
    }
    
    override func mouseDragged(event: NSEvent) {
        if enabled {
            let location = event.locationInWindow
            let point = self.convertPoint(location, fromView: nil)
            self.pressed = NSPointInRect(point, self.bounds)
        }
    }
    
    override func mouseUp(event: NSEvent) {
        if enabled {
            let location = event.locationInWindow
            let point = self.convertPoint(location, fromView: nil)
            if NSPointInRect(point, self.bounds) {
                self.pressed = false
                self.executeAction()
            }
        }
    }
    
    // Drawing
    
    override func drawRect(rect: NSRect) {
        var anImage: NSImage?
        var r = self.bounds
        if keyView {
            anImage = (enabled || !disableImage) ? image : disableImage
        } else {
            if (enabled)
            {
                anImage = backImage ? backImage : (image ? image : nil);
            }
            else {
                anImage = backDisableImage ? backDisableImage : (backImage ? backImage : (image ? image : nil));
            }
        }
        if anImage {
            anImage!.drawInRect(r, fromRect: NSZeroRect, operation: .CompositeSourceOver, fraction: 1.0)
            if pressed {
                anImage!.drawInRect(r, fromRect: NSZeroRect, operation: .CompositeXOR, fraction: 0.3)
            }
        }
        if title {
            let padding: CGFloat = 10.0
            var shadow = NSShadow()
            shadow.shadowOffset = NSSize(width: 0.0, height: -1.0)
            shadow.shadowColor = keyView ? NSColor.blackColor() : NSColor.whiteColor()
            var style = NSMutableParagraphStyle()
            style.lineBreakMode = .ByTruncatingTail
            var color = NSColor(calibratedWhite: 1.0, alpha: keyView ? (pressed ? 0.5 : 1.0) : (pressed ? 0.25 : 0.5))
            let attributes = [
                NSFontAttributeName: NSFont.boldSystemFontOfSize(11.0),
                NSForegroundColorAttributeName: color,
                NSShadowAttributeName: shadow,
                NSParagraphStyleAttributeName: style]
            r.size = title!.sizeWithAttributes(attributes)
            if r.size.width > (self.bounds.size.width - padding * 2) {
                r.size.width = self.bounds.size.width - padding * 2
            }
            r.origin.x = padding + ((self.bounds.size.width - padding * 2) - r.size.width) / 2
            r.origin.y = (self.bounds.size.height - r.size.height) / 2
            title!.drawInRect(r, withAttributes: attributes)
        }
    }
}