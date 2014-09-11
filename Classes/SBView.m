/*

SBView.m
 
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

#import "SBView.h"


@implementation SBView

@synthesize frameColor;
@synthesize animationDuration;
@synthesize keyView;
@synthesize toolbarVisible;
@dynamic frame;
@dynamic wantsLayer;
@dynamic alphaValue;
@dynamic subview;
@synthesize target;
@synthesize doneSelector;
@synthesize cancelSelector;

- (instancetype)initWithFrame:(NSRect)frame
{
	if (self = [super initWithFrame:frame])
	{
		frameColor = nil;
		animationDuration = 0.5;
		keyView = YES;
		toolbarVisible = YES;
		target = nil;
		doneSelector = nil;
		cancelSelector = nil;
	}
	return self;
}

- (void)dealloc
{
	target = nil;
	doneSelector = nil;
	cancelSelector = nil;
}

#pragma mark NSCoding Protocol

- (instancetype)initWithCoder:(NSCoder *)decoder
{
	if ((self = [super initWithCoder:decoder]))
	{
		if ([decoder allowsKeyedCoding])
		{
			if ([decoder containsValueForKey:@"frameColor"])
			{
				self.frameColor = [decoder decodeObjectForKey:@"frameColor"];
			}
			if ([decoder containsValueForKey:@"animationDuration"])
			{
				self.animationDuration = [decoder decodeFloatForKey:@"animationDuration"];
			}
			if ([decoder containsValueForKey:@"keyView"])
			{
				self.keyView = [decoder decodeBoolForKey:@"keyView"];
			}
			if ([decoder containsValueForKey:@"toolbarVisible"])
			{
				self.toolbarVisible = [decoder decodeBoolForKey:@"toolbarVisible"];
			}
		}
	}
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	[super encodeWithCoder:coder];
	if (frameColor)
		[coder encodeObject:frameColor forKey:@"frameColor"];
	[coder encodeFloat:animationDuration forKey:@"animationDuration"];
	[coder encodeBool:keyView forKey:@"keyView"];
	[coder encodeBool:toolbarVisible forKey:@"toolbarVisible"];
}

#pragma mark View

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
	return YES;
}

#pragma mark Getter

- (NSString *)description
{
	return [NSString stringWithFormat:@"%@ %@", super.description, NSStringFromRect(self.frame)];
}

- (CGFloat)alphaValue
{
	return super.alphaValue;
}

- (NSView *)subview
{
	NSView *subview = nil;
	NSArray *subviews = self.subviews;
	subview = subviews.count > 0 ? subviews[0] : nil;
	return subview;
}

#pragma mark Setter

- (void)setAlphaValue:(CGFloat)alphaValue
{
	if (alphaValue == 1.0)
	{
		if (self.wantsLayer)
			self.wantsLayer = NO;
	}
	else {
		if (!self.wantsLayer)
			self.wantsLayer = YES;
	}
    super.alphaValue = alphaValue;
}

- (void)setFrame:(NSRect)frame animate:(BOOL)animate
{
	if (animate)
	{
		NSViewAnimation *animation = nil;
        NSDictionary *info = @{NSViewAnimationTargetKey: self,
                               NSViewAnimationStartFrameKey: [NSValue valueWithRect:self.frame],
                               NSViewAnimationEndFrameKey: [NSValue valueWithRect:frame]};
		animation = [[NSViewAnimation alloc] initWithViewAnimations:@[info]];
        animation.duration = 0.25;
		[animation startAnimation];
	}
	else {
		self.frame = frame;
	}
}

- (void)setKeyView:(BOOL)isKeyView
{
	if (keyView != isKeyView)
	{
		keyView = isKeyView;
        self.needsDisplay = YES;
		if (self.subviews.count > 0)
		{
			for (NSView *subview in self.subviews)
			{
				if ([subview respondsToSelector:@selector(setKeyView:)])
				{
					[(id)subview setKeyView:isKeyView];
				}
			}
		}
	}
}

- (void)setToolbarVisible:(BOOL)isToolbarVisible
{
	if (toolbarVisible != isToolbarVisible)
	{
		toolbarVisible = isToolbarVisible;
        self.needsDisplay = YES;
	}
}

#pragma mark Actions

- (void)fadeIn:(id)delegate
{
	NSViewAnimation *animation = nil;
    NSArray *animations = nil;
    animations = @[@{NSViewAnimationTargetKey: self,
                     NSViewAnimationEffectKey: NSViewAnimationFadeInEffect}];
	animation = [[NSViewAnimation alloc] initWithViewAnimations:animations];
    animation.duration = self.animationDuration;
    animation.delegate = delegate;
	[animation startAnimation];
}

- (void)fadeOut:(id)delegate
{
    NSViewAnimation *animation = nil;
    NSArray *animations = nil;
    animations = @[@{NSViewAnimationTargetKey: self,
                     NSViewAnimationEffectKey: NSViewAnimationFadeOutEffect}];
    animation = [[NSViewAnimation alloc] initWithViewAnimations:animations];
    animation.duration = self.animationDuration;
    animation.delegate = delegate;
    [animation startAnimation];
}

- (void)done
{
	if (target && doneSelector)
	{
		if ([target respondsToSelector:doneSelector])
		{
			[target performSelector:doneSelector withObject:self];
		}
	}
}

- (void)cancel
{
	if (target && cancelSelector)
	{
		if ([target respondsToSelector:cancelSelector])
		{
			[target performSelector:cancelSelector withObject:self];
		}
	}
}

#pragma mark Drawing

- (void)drawRect:(NSRect)rect
{
	if (frameColor)
	{
		[[frameColor colorWithAlphaComponent:0.5] set];
		[[NSBezierPath bezierPathWithRect:rect] fill];	// Transparent
		[frameColor set];
		NSFrameRect(self.bounds);
	}
}

@end
