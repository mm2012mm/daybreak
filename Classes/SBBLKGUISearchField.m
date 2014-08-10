/*
 
 SBBLKGUISearchField.m
 
 Authoring by Atsushi Jike
 
 Copyright 2010 Atsushi Jike. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, 
 are permitted provided that the following conditions are met:
 
 Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 
 Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer 
 in the documentation and/or other materials provided with the distribution.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
 CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, 
 PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "SBBLKGUISearchField.h"
#import "SBUtil.h"

@implementation SBBLKGUISearchField

+ (void)initialize
{
	if (self == SBBLKGUISearchField.class)
	{
        self.cellClass = SBBLKGUISearchFieldCell.class;
	}
}

+ (Class)cellClass
{
    return SBBLKGUISearchFieldCell.class;
}

- (instancetype)initWithFrame:(NSRect)rect
{
	if (self = [super initWithFrame:rect])
	{
		[self setDefaultValues];
	}
	return self;
}

- (void)setDefaultValues
{
    self.alignment = NSLeftTextAlignment;
    self.drawsBackground = NO;
    self.textColor = NSColor.whiteColor;
}

@end

@implementation SBBLKGUISearchFieldCell

- (instancetype)init
{
	if (self = [super init])
	{
		[self setDefaultValues];
	}
	return self;
}

- (void)setDefaultValues
{
	NSButtonCell *searchButtonCell = nil;
	searchButtonCell = self.searchButtonCell;
    self.wraps = NO;
    self.scrollable = YES;
    self.focusRingType = NSFocusRingTypeExterior;
    searchButtonCell.image = [NSImage imageNamed:@"Search.png"];
	searchButtonCell.alternateImage = [NSImage imageNamed:@"Search.png"];
}

- (NSText *)setUpFieldEditorAttributes:(NSText *)textObj
{
	NSText *text = [super setUpFieldEditorAttributes:textObj];
	if ([text isKindOfClass:NSTextView.class])
	{
		NSDictionary *attributes = @{NSForegroundColorAttributeName: NSColor.whiteColor,
                                     NSBackgroundColorAttributeName: NSColor.grayColor};
        ((NSTextView *)text).insertionPointColor = NSColor.whiteColor;
        ((NSTextView *)text).selectedTextAttributes = attributes;
	}
	return text;
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	CGRect r = CGRectZero;
	CGContextRef ctx = NSGraphicsContext.currentContext.graphicsPort;
	CGPathRef path = nil;
	CGFloat alpha = [controlView respondsToSelector:@selector(isEnabled)] ? (((NSTextField *)controlView).enabled ? 1.0 : 0.2) : 1.0;
	
	r = NSRectToCGRect(cellFrame);
	path = SBRoundedPath(r, r.size.height / 2, 0, YES, YES);
	CGContextSaveGState(ctx);
	CGContextAddPath(ctx, path);
	CGContextSetRGBFillColor(ctx, 0.0, 0.0, 0.0, alpha * 0.1);
	CGContextFillPath(ctx);
	CGContextRestoreGState(ctx);
	
	r = NSRectToCGRect(cellFrame);
	r.origin.x += 0.5;
	r.origin.y += 0.5;
	r.size.width -= 1.0;
	r.size.height -= 1.0;
	path = SBRoundedPath(r, r.size.height / 2, 0, YES, YES);
	CGContextSaveGState(ctx);
	CGContextAddPath(ctx, path);
	CGContextSetLineWidth(ctx, 0.5);
	CGContextSetRGBStrokeColor(ctx, 1.0, 1.0, 1.0, alpha);
	CGContextStrokePath(ctx);
	CGContextRestoreGState(ctx);
	
	[self drawInteriorWithFrame:cellFrame inView:controlView];
}

@end