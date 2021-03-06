/*
SBRenderWindow.swift

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

@objc protocol SBRenderWindowDelegate: NSWindowDelegate {
    optional func renderWindowDidStartRendering(renderWindow: SBRenderWindow)
    optional func renderWindow(renderWindow: SBRenderWindow, didFinishRenderingImage: NSImage)
    optional func renderWindow(renderWindow: SBRenderWindow, didFailWithError: NSError)
}

class SBRenderWindow: NSWindow, WebFrameLoadDelegate {
    var webView: WebView?
    var sbDelegate: SBRenderWindowDelegate? {
        get { return delegate as? SBRenderWindowDelegate }
        set(sbDelegate) { delegate = sbDelegate }
    }
    
    class func startRenderingWithSize(size: NSSize, delegate: SBRenderWindowDelegate?, URL: NSURL) -> SBRenderWindow {
        let r = NSRect(size: size)
        let window = SBRenderWindow(contentRect: r)
        window.delegate = delegate
        window.webView!.mainFrame.loadRequest(NSURLRequest(URL: URL))
        if kSBFlagShowRenderWindow {
            window.orderFront(nil)
        }
        return window
    }
    
    init(contentRect: NSRect) {
        let styleMask = NSBorderlessWindowMask
        let bufferingType = NSBackingStoreType.Buffered
        let deferCreation = true
        super.init(contentRect: contentRect, styleMask: styleMask, backing: bufferingType, defer: deferCreation)
        
        let r = NSRect(size: contentRect.size)
        webView = WebView(frame: r, frameName: nil, groupName: nil)
        webView!.frameLoadDelegate = self
        webView!.preferences = SBGetWebPreferences
        webView!.hostWindow = self
        contentView!.addSubview(webView!)
        releasedWhenClosed = true
    }
    
    required init(coder: NSCoder) {
        fatalError("NSCoding not supported")
    }
    
    func destruct() {
        destructWebView()
        close()
    }
    
    func destructWebView() {
        if let webView = webView {
            if webView.loading {
                webView.stopLoading(nil)
            }
            //???
            webView.hostWindow = nil
            webView.frameLoadDelegate = nil
            webView.removeFromSuperview()
            self.webView = nil
        }
    }
    
    // MARK: Delegate
    
    func webView(sender: WebView, didStartProvisionalLoadForFrame frame: WebFrame) {
        sbDelegate?.renderWindowDidStartRendering?(self)
    }
    
    func webView(sender: WebView, didFinishLoadForFrame frame: WebFrame) {
        if let f: (SBRenderWindow, didFinishRenderingImage: NSImage) -> Void = sbDelegate?.renderWindow,
               webDocumentView = sender.mainFrame.frameView.documentView,
               image = NSImage(view: webDocumentView)?.inset(size: SBBookmarkImageMaxSize, intersectRect: webDocumentView.bounds, offset: .zero) {
            f(self, didFinishRenderingImage: image)
        }
        destruct()
    }
    
    func webView(sender: WebView, didFailProvisionalLoadWithError error: NSError, forFrame frame: WebFrame) {
        sbDelegate?.renderWindow?(self, didFailWithError: error)
    }
    
    func webView(sender: WebView, didFailLoadWithError error: NSError, forFrame frame: WebFrame) {
        sbDelegate?.renderWindow?(self, didFailWithError: error)
    }
}