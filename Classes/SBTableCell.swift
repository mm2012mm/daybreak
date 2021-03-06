/*
SBTableCell.swift

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

enum SBTableCellStyle {
    case Gray, White
}

class SBTableCell: NSCell {
    var style: SBTableCellStyle = .Gray
    var showSelection = true
    var showRoundedPath: Bool = false
    
    private func setDefaultValues() {
        enabled = true
        lineBreakMode = .ByTruncatingTail
    }
    
    @objc(initImageCell:)
    override init(imageCell anImage: NSImage?) {
        super.init(imageCell: anImage)
        setDefaultValues()
    }
    
    @objc(initTextCell:)
    override init(textCell aString: String) {
        super.init(textCell: aString)
        setDefaultValues()
    }
    
    required init?(coder: NSCoder) {
        fatalError("NSCoding not supported")
    }
    
    let side: CGFloat = 5.0
    
    override func drawWithFrame(cellFrame: NSRect, inView controlView: NSView) {
        drawInteriorWithFrame(cellFrame, inView: controlView)
        drawTitleWithFrame(cellFrame, inView: controlView)
    }
    
    override func drawInteriorWithFrame(cellFrame: NSRect, inView controlView: NSView) {
        var backgroundColor: NSColor!
        var cellColor: NSColor!
        var selectedCellColor: NSColor!
        if style == .Gray {
            backgroundColor = SBBackgroundColor
            cellColor = SBTableCellColor
            selectedCellColor = SBSidebarSelectedCellColor
        } else if style == .White {
            backgroundColor = SBBackgroundLightGrayColor
            cellColor = SBTableLightGrayCellColor
            selectedCellColor = NSColor.alternateSelectedControlColor().colorUsingColorSpace(.genericRGBColorSpace())!
        }
        backgroundColor.set()
        NSRectFill(cellFrame)
        
        if showRoundedPath {
            cellColor.set()
            NSRectFill(NSInsetRect(cellFrame, 0.0, 0.5))
            if highlighted && showSelection {
                let radius = (cellFrame.size.height - 0.5 * 2) / 2
                var path = NSBezierPath(roundedRect: CGRectInset(cellFrame, 1.0, 0.5), xRadius: radius, yRadius: radius)
                selectedCellColor.set()
                path.fill()
            }
        } else {
            if highlighted && showSelection {
                selectedCellColor.set()
            } else {
                cellColor.set()
            }
            NSRectFill(NSInsetRect(cellFrame, 0.0, 0.5))
        }
    }
    
    func drawTitleWithFrame(cellFrame: NSRect, inView controlView: NSView) {
        var textColor: NSColor!
        var sTextColor: NSColor!
        
        if style == .Gray {
            textColor = SBSidebarTextColor
            sTextColor = .blackColor()
        } else if style == .White {
            textColor = ((enabled ? .blackColor() : .grayColor()) as NSColor).colorUsingColorSpace(.genericRGBColorSpace())!
            sTextColor = highlighted ? .clearColor() : .whiteColor()
        }
        
        if let title: NSString = title.ifNotEmpty {
            var r = NSZeroRect
            var sr = NSZeroRect
            let side = self.side + (cellFrame.size.height - 0.5 * 2) / 2
            
            let color = highlighted ? .whiteColor() : textColor
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineBreakMode = lineBreakMode
            let attribute = [NSFontAttributeName: font!, NSForegroundColorAttributeName: color, NSParagraphStyleAttributeName: paragraphStyle]
            let sAttribute = [NSFontAttributeName: font!, NSForegroundColorAttributeName: sTextColor, NSParagraphStyleAttributeName: paragraphStyle]
            var size = title.sizeWithAttributes(attribute)
            size.width.constrain(max: cellFrame.size.width - side * 2)
            r.size = size
            r.origin.x = cellFrame.origin.x
            switch alignment {
                case .Left: r.origin.x += side
                case .Right: r.origin.x += side + ((cellFrame.size.width - side * 2) - size.width)
                case .Center: r.origin.x += ((cellFrame.size.width - side * 2) - size.width) / 2
                default: break
            }
            r.origin.y = cellFrame.origin.y + (cellFrame.size.height - r.size.height) / 2
            sr = r
            switch style {
                case .Gray: sr.origin.y -= 1.0
                case .White: sr.origin.y += 1.0
            }
            title.drawInRect(sr, withAttributes: sAttribute)
            title.drawInRect(r, withAttributes: attribute)
        }
    }
}


class SBIconDataCell: NSCell {
    var drawsBackground = true
    
    override func drawWithFrame(cellFrame: NSRect, inView controlView: NSView) {
        drawInteriorWithFrame(cellFrame, inView: controlView)
        drawImageWithFrame(cellFrame, inView: controlView)
    }
    
   override func drawInteriorWithFrame(cellFrame: NSRect, inView controlView: NSView) {
        if drawsBackground {
            SBBackgroundLightGrayColor.set()
            NSRectFill(cellFrame)
            SBTableLightGrayCellColor.set()
            NSRectFill(NSInsetRect(cellFrame, 0.0, 0.5))
        }
    }
    
    func drawImageWithFrame(cellFrame: NSRect, inView controlView: NSView) {
        if image != nil {
            var r = NSZeroRect
            r.size = image!.size
            r.origin.x = cellFrame.origin.x + (cellFrame.size.width - r.size.width) / 2
            r.origin.y = cellFrame.origin.y + (cellFrame.size.height - r.size.height) / 2
            image!.drawInRect(r, operation: .CompositeSourceOver, fraction: 1.0, respectFlipped: true)
        }
    }
}