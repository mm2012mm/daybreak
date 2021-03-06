/*
SBBookmarkView.swift

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

import BLKGUI

class SBBookmarkView: SBView, NSTextFieldDelegate {
    var image: NSImage? {
        didSet {
            if image != oldValue {
                needsDisplay = true
            }
        }
    }
    
    private lazy var messageLabel: NSTextField? = {
        let messageLabel = NSTextField(frame: self.messageLabelRect)
        messageLabel.autoresizingMask = [.ViewMinXMargin, .ViewMinYMargin]
        messageLabel.editable = false
        messageLabel.bordered = false
        messageLabel.drawsBackground = false
        messageLabel.textColor = .whiteColor()
        messageLabel.font = .boldSystemFontOfSize(16)
        messageLabel.alignment = .Center
        messageLabel.cell!.wraps = true
        return messageLabel
    }()
    
    private lazy var titleLabel: NSTextField = {
        let titleLabel = NSTextField(frame: self.titleLabelRect)
        titleLabel.autoresizingMask = [.ViewMinXMargin, .ViewMinYMargin]
        titleLabel.editable = false
        titleLabel.bordered = false
        titleLabel.drawsBackground = false
        titleLabel.textColor = .lightGrayColor()
        titleLabel.font = .systemFontOfSize(12)
        titleLabel.alignment = .Right
        titleLabel.stringValue = NSLocalizedString("Title", comment: "") + " :"
        return titleLabel
    }()
    
    private lazy var URLLabel: NSTextField = {
        let URLLabel = NSTextField(frame: self.URLLabelRect)
        URLLabel.autoresizingMask = [.ViewMinXMargin, .ViewMinYMargin]
        URLLabel.editable = false
        URLLabel.bordered = false
        URLLabel.drawsBackground = false
        URLLabel.textColor = .lightGrayColor()
        URLLabel.font = .systemFontOfSize(12)
        URLLabel.alignment = .Right
        URLLabel.stringValue = NSLocalizedString("URL", comment: "") + " :"
        return URLLabel
    }()
    
    private lazy var colorLabel: NSTextField = {
        let colorLabel = NSTextField(frame: self.colorLabelRect)
        colorLabel.autoresizingMask = [.ViewMinXMargin, .ViewMinYMargin]
        colorLabel.editable = false
        colorLabel.bordered = false
        colorLabel.drawsBackground = false
        colorLabel.textColor = .lightGrayColor()
        colorLabel.font = .systemFontOfSize(12)
        colorLabel.alignment = .Right
        colorLabel.stringValue = NSLocalizedString("Label", comment: "") + " :"
        return colorLabel
    }()
    
    private lazy var titleField: BLKGUI.TextField = {
        let titleField = BLKGUI.TextField(frame: self.titleFieldRect)
        titleField.autoresizingMask = [.ViewMinXMargin, .ViewMinYMargin]
        titleField.alignment = .Left
        return titleField
    }()
    
    private lazy var URLField: BLKGUI.TextField = {
        let URLField = BLKGUI.TextField(frame: self.URLFieldRect)
        URLField.autoresizingMask = [.ViewMinXMargin, .ViewMinYMargin]
        URLField.delegate = self
        URLField.alignment = .Left
        return URLField
    }()
    
    private lazy var colorPopup: BLKGUI.PopUpButton = {
        let colorPopup = BLKGUI.PopUpButton(frame: self.colorPopupRect)
        colorPopup.autoresizingMask = [.ViewMinXMargin, .ViewMinYMargin]
        colorPopup.pullsDown = true
        colorPopup.alignment = .Left
        colorPopup.menu = SBBookmarkLabelColorMenu(true, nil, nil, nil)
        colorPopup.selectItemAtIndex(1)
        return colorPopup
    }()
    
    private lazy var doneButton: BLKGUI.Button = {
        let doneButton = BLKGUI.Button(frame: self.doneButtonRect)
        doneButton.title = NSLocalizedString("Add", comment: "")
        doneButton.target = self
        doneButton.action = #selector(done)
        doneButton.keyEquivalent = "\r" // busy if button is added into a view
        doneButton.enabled = false
        return doneButton
    }()
    
    private lazy var cancelButton: BLKGUI.Button = {
        let cancelButton = BLKGUI.Button(frame: self.cancelButtonRect)
        cancelButton.title = NSLocalizedString("Cancel", comment: "")
        cancelButton.target = self
        cancelButton.action = #selector(cancel)
        cancelButton.keyEquivalent = "\u{1B}"
        return cancelButton
    }()
    
    var fillMode = 1
    
    var message: String {
        get { return messageLabel!.stringValue }
        set(message) { messageLabel!.stringValue = message }
    }
    
    var title: String {
        get { return titleField.stringValue }
        set(title) { titleField.stringValue = title }
    }
    
    var URLString: String {
        get { return URLField.stringValue }
        set(URLString) {
            URLField.stringValue = URLString
            doneButton.enabled = !URLString.isEmpty
        }
    }
    
    var itemRepresentation: NSDictionary {
        let data = image!.bitmapImageRep!.data
        let labelName = SBBookmarkLabelColorNames[colorPopup.indexOfSelectedItem - 1]
        let offset = NSStringFromPoint(.zero)
        return SBCreateBookmarkItem(title, URLString, data, NSDate(), labelName, offset)
    }
    
    // MARK: Construction
    
    override init(frame: NSRect) {
        super.init(frame: frame)
        animationDuration = 1.0
        addSubviews(messageLabel!, titleLabel, URLLabel, colorLabel, titleField, URLField, colorPopup, doneButton, cancelButton)
        makeResponderChain()
        autoresizingMask = [.ViewMinXMargin, .ViewMaxXMargin, .ViewMinYMargin, .ViewMaxYMargin]
    }
    
    required init(coder: NSCoder) {
        fatalError("NSCoding not supported")
    }
    
    func makeResponderChain() {
        titleField.nextKeyView = URLField
        URLField.nextKeyView = cancelButton
        cancelButton.nextKeyView = doneButton
        doneButton.nextKeyView = titleField
    }
    
    // MARK: Rects
    
    let margin = NSMakePoint(36.0, 32.0)
    let labelWidth: CGFloat = 85.0
    let buttonSize = NSMakeSize(105.0, 24.0)
    let buttonMargin: CGFloat = 15.0
    
    var imageRect: NSRect {
        var r = NSZeroRect
        var margin = NSZeroPoint
        r.size = SBBookmarkImageMaxSize
        margin.x = (bounds.size.height - r.size.height) / 2
        margin.y = r.size.height * 0.5
        r.origin = margin
        return r
    }
    
    var messageLabelRect: NSRect {
        var r = NSZeroRect
        r.size.width = bounds.size.width - margin.x * 2
        r.size.height = 36.0
        r.origin.x = margin.x
        r.origin.y = bounds.size.height - imageRect.origin.y / 2 - r.size.height
        return r
    }
    
    var titleLabelRect: NSRect {
        var r = NSZeroRect
        r.origin.x = imageRect.maxX + 10.0
        r.size.width = labelWidth
        r.size.height = 24.0
        r.origin.y = imageRect.maxY - r.size.height
        return r
    }
    
    var URLLabelRect: NSRect {
        var r = NSZeroRect
        r.origin.x = titleLabelRect.origin.x
        r.size.width = labelWidth
        r.size.height = 24.0
        r.origin.y = titleLabelRect.origin.y - 10.0 - r.size.height
        return r
    }
    
    var colorLabelRect: NSRect {
        var r = NSZeroRect
        r.origin.x = URLLabelRect.origin.x
        r.size.width = labelWidth
        r.size.height = 24.0
        r.origin.y = URLLabelRect.origin.y - 10.0 - r.size.height
        return r
    }
    
    var titleFieldRect: NSRect {
        var r = NSZeroRect
        r.origin.x = titleLabelRect.maxX + 10.0
        r.origin.y = titleLabelRect.origin.y
        r.size.width = bounds.size.width - r.origin.x - margin.x
        r.size.height = 24.0
        return r
    }
    
    var URLFieldRect: NSRect {
        var r = NSZeroRect
        r.origin.x = URLLabelRect.maxX + 10.0
        r.origin.y = URLLabelRect.origin.y
        r.size.width = bounds.size.width - r.origin.x - margin.x
        r.size.height = 24.0
        return r
    }
    
    var colorPopupRect: NSRect {
        var r = NSZeroRect
        r.origin.x = colorLabelRect.maxX + 10.0
        r.origin.y = colorLabelRect.origin.y
        r.size.width = 150.0
        r.size.height = 26.0
        return r
    }
    
    var doneButtonRect: NSRect {
        var r = NSZeroRect
        r.size = buttonSize
        r.origin.y = margin.y
        r.origin.x = (bounds.size.width - (r.size.width * 2 + buttonMargin)) / 2 + r.size.width + buttonMargin
        return r
    }
    
    var cancelButtonRect: NSRect {
        var r = NSZeroRect
        r.size = buttonSize
        r.origin.y = margin.y
        r.origin.x = (bounds.size.width - (r.size.width * 2 + buttonMargin)) / 2
        return r
    }
    
    // MARK: Delegate
    
    override func controlTextDidChange(notification: NSNotification) {
        if notification.object === URLField {
            doneButton.enabled = !URLField.stringValue.isEmpty
        }
    }
    
    // MARK: Actions
    
    func makeFirstResponderToTitleField() {
        window!.makeFirstResponder(titleField)
    }
    
    // MARK: Drawing
    
    override func drawRect(rect: NSRect) {
        let ctx = SBCurrentGraphicsPort
        
        // Background
        let colors = [NSColor(deviceWhite: 0.4, alpha: 0.9), .blackColor()]
        let locations: [CGFloat] = [0.0, 0.6]
        let gradient = NSGradient(colors: colors, atLocations: locations, colorSpace: .genericGrayColorSpace())!
        var mPath: NSBezierPath!
        if fillMode == 0 {
            let r = NSMakeRect(bounds.origin.x, bounds.origin.y, bounds.size.width, bounds.size.width)
            let transform = CATransform3DRotate(CATransform3DIdentity, CGFloat(-70 * M_PI / 180), 1.0, 0.0, 0.0)
            mPath = SBEllipsePath3D(r, transform)
        } else {
            var p = CGPointZero
            let behind: CGFloat = 0.7
            mPath = NSBezierPath()
            mPath.moveToPoint(p)
            p.x = bounds.size.width
            mPath.lineToPoint(p)
            p.x = bounds.size.width - ((bounds.size.width * (1.0 - behind)) / 2)
            p.y = bounds.size.height * locations[1]
            mPath.lineToPoint(p)
            p.x = (bounds.size.width * (1.0 - behind)) / 2
            mPath.lineToPoint(p)
            p = CGPointZero
            mPath.lineToPoint(p)
        }
        SBPreserveGraphicsState {
            mPath.addClip()
            gradient.drawInRect(bounds, angle: 90)
        }
        
        if let image = image {
            var imageRect = self.imageRect
            image.drawInRect(imageRect, fromRect: .zero, operation: .CompositeSourceOver, fraction: 0.85)
            
            imageRect.origin.y -= imageRect.size.height
            imageRect.size.height *= 0.5
            let maskImage = SBBookmarkReflectionMaskImage(imageRect.size)
            CGContextTranslateCTM(ctx, 0.0, 0.0)
            CGContextScaleCTM(ctx, 1.0, -1.0)
            CGContextClipToMask(ctx, imageRect, maskImage.CGImage)
            image.drawInRect(imageRect, fromRect: NSMakeRect(0, 0, image.size.width, image.size.height * 0.5), operation: .CompositeSourceOver, fraction: 1.0)
        }
    }
}

class SBEditBookmarkView: SBBookmarkView {
    var index: Int!
    
    var labelName: String? {
        get {
            let itemIndex = colorPopup.indexOfSelectedItem - 1
            return SBBookmarkLabelColorNames.get(itemIndex)
        }
        
        set(labelName) {
            if let itemIndex = SBBookmarkLabelColorNames.firstIndex({$0 == labelName}) {
                colorPopup.selectItemAtIndex(itemIndex + 1)
            }
        }
    }
    
    override var message: String {
        get { fatalError("message property not available") }
        set(message) { fatalError("message property not available") }
    }
    
    override init(frame: NSRect) {
        super.init(frame: frame)
        
        messageLabel!.removeFromSuperview()
        messageLabel = nil
        
        doneButton.title = NSLocalizedString("Done", comment: "")
    }
    
    required init(coder: NSCoder) {
        fatalError("NSCoding not supported")
    }
}