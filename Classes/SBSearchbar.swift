/*
SBSearchbar.swift

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

class SBSearchbar: SBFindbar {
    override internal lazy var backwardButton: SBButton? = nil
    override internal lazy var forwardButton: SBButton? = nil
    override internal lazy var caseSensitiveCheck: SBBLKGUIButton? = nil
    override internal lazy var wrapCheck: SBBLKGUIButton? = nil

    override internal lazy var searchField: SBFindSearchField = {
        let searchField = SBFindSearchField(frame: self.searchRect)
        searchField.autoresizingMask = .ViewWidthSizable
        searchField.delegate = self
        searchField.target = self
        searchField.action = "executeDoneSelector:"
        let cell = searchField.cell() as NSSearchFieldCell
        cell.sendsWholeSearchString = true
        cell.sendsSearchStringImmediately = false
        if let string = NSPasteboard(name: NSFindPboard).stringForType(NSStringPboardType) {
            searchField.stringValue = string
        }
        return searchField
    }()
    
    
    override init(frame: NSRect) {
        super.init(frame: frame)
    }
    
    required init(coder: NSCoder) {
        fatalError("NSCoding not supported")
    }
    
    override class func minimumWidth() -> CGFloat { return 200 }
    override class func availableWidth() -> CGFloat { return 200 }
    override func minimumWidth() -> CGFloat { return SBSearchbar.minimumWidth() }
    override func availableWidth() -> CGFloat { return SBSearchbar.availableWidth() }
    
    // MARK: Rects
    
    override var searchRect: NSRect {
        var r = NSZeroRect
        r.size.width = self.bounds.size.width - NSMaxX(closeRect)
        r.size.height = 19.0
        r.origin.x = NSMaxX(closeRect)
        r.origin.y = (bounds.size.height - r.size.height) / 2
        return r
    }
    
    // MARK: Actions
    
    func executeDoneSelector(sender: AnyObject) {
        let text = searchField.stringValue
        if !text.isEmpty {
            if target != nil && doneSelector != nil {
                if target.respondsToSelector(doneSelector) {
                    SBPerform(target, doneSelector, text)
                }
            }
        }
    }
    
    override func executeClose() {
        if target != nil && cancelSelector != nil {
            if target.respondsToSelector(cancelSelector) {
                SBPerform(target, cancelSelector, self)
            }
        }
    }
}