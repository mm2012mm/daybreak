/*

SBBookmarkListView.m
 
Authoring by Atsushi Jike

Copyright 2009 Atsushi Jike. All rights reserved.

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

#import "SBBookmarkListView.h"
#import "SBBookmarkListItemView.h"
#import "SBBookmarks.h"
#import "SBBookmarksView.h"
#import "SBUtil.h"

@implementation SBBookmarkListView

@synthesize wrapperView;
@synthesize mode;
@synthesize cellWidth;
@dynamic items;
@synthesize draggedItems;

- (id)initWithFrame:(NSRect)frame
{
	if (self = [super initWithFrame:frame])
	{
		mode = SBBookmarkIconMode;
		_block = NSZeroPoint;
		_point = NSZeroPoint;
		selectionView = nil;
		draggingLineView = nil;
		toolsItemView = nil;
		[self constructControls];
		[self registerForDraggedTypes:[NSArray arrayWithObjects:SBBookmarkPboardType, NSURLPboardType, NSFilenamesPboardType, nil]];
	}
	return self;
}

- (void)dealloc
{
	wrapperView = nil;
	draggedItemView = nil;
	toolsItemView = nil;
	[draggedItems release];
	[itemViews release];
	[self destructSelectionView];
	[self destructDraggingLineView];
	[self destructControls];
	[self destructToolsTimer];
	[super dealloc];
}

#pragma mark Responder

- (BOOL)acceptsFirstResponder
{
	return YES;
}

- (BOOL)becomeFirstResponder
{
	[self needsDisplaySelectedItemViews];
	return YES;
}

- (BOOL)resignFirstResponder
{
	[self needsDisplaySelectedItemViews];
	return YES;
}

- (BOOL)isFlipped
{
	return YES;
}

#pragma mark Getter

- (CGFloat)width
{
	return [[self enclosingScrollView] contentSize].width;
}

- (NSPoint)spacing
{
	NSPoint s = NSZeroPoint;
	CGFloat width = [self width];
	s.x = (width - _block.x * cellSize.width) / (_block.x + 1);
	return s;
}

- (NSPoint)block
{
	NSPoint block = NSZeroPoint;
	NSInteger count = [self.items count];
	CGFloat width = [self width];
	block.x = (NSInteger)(width / cellSize.width);
	if (block.x == 0)
		block.x = 1;
	block.y = (NSInteger)(count / (NSInteger)block.x) + (SBRemainderIsZero(count, (NSInteger)block.x) ? 0 : 1);
	return block;
}

- (NSRect)itemRectAtIndex:(NSInteger)index
{
	NSRect r = NSZeroRect;
	NSPoint spacing = [self spacing];
	NSPoint pos = NSZeroPoint;
	r.size = cellSize;
	pos.y = (NSInteger)(index / (NSInteger)_block.x);
	pos.x = SBRemainder(index, (NSInteger)_block.x);
	r.origin.x = pos.x * cellSize.width + spacing.x * pos.x;
	r.origin.y = pos.y * cellSize.height;
	return r;
}

- (SBBookmarkListItemView *)itemViewAtPoint:(NSPoint)point
{
	SBBookmarkListItemView *view = nil;
	for (SBBookmarkListItemView *itemView in itemViews)
	{
		NSRect r = itemView.frame;
		if ([itemView hitToPoint:NSMakePoint(point.x - r.origin.x, r.size.height - (point.y - r.origin.y))])
		{
			view = itemView;
			break;
		}
	}
	return view;
}

- (NSUInteger)indexAtPoint:(NSPoint)point
{
	NSInteger index = NSNotFound;
	NSUInteger count = [self.items count];
	NSPoint loc = NSZeroPoint;
	CGFloat location = 0;
	if (mode == SBBookmarkIconMode)
	{
		NSPoint spacing = [self spacing];
		loc.y = (NSInteger)(point.y / cellSize.height);
		location = (point.x / (cellSize.width + spacing.x));
		if (location > (NSUInteger)location)
		{
			if ((location - (NSUInteger)location) > 0.5)
				loc.x = (NSInteger)location + 1;
			else
				loc.x = (NSInteger)location;
		}
		else {
			loc.x = (NSInteger)location;
		}
		index = _block.x * loc.y + loc.x;
		if (index > count)
		{
			loc.x = count - _block.x * loc.y;
			index = _block.x * loc.y + loc.x;
		}
	}
	else if (mode == SBBookmarkListMode)
	{
		loc.y = (NSInteger)(point.y / 22.0);
		location = (point.y - loc.y * 22.0);
		if (location > 22.0 / 2)
		{
			loc.y += 1;
		}
		index = loc.y;
	}
	return index;
}

- (NSIndexSet *)selectedIndexes
{
	NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
	NSUInteger index = 0;
	for (SBBookmarkListItemView *itemView in itemViews)
	{
		if (itemView.selected)
		{
			[indexes addIndex:index];
		}
		index++;
	}
	return [[indexes copy] autorelease];
}

- (NSRect)dragginLineRectAtPoint:(NSPoint)point
{
	NSRect r = NSZeroRect;
	NSInteger index = NSNotFound;
	NSUInteger count = [self.items count];
	NSPoint loc = NSZeroPoint;
	CGFloat location = 0;
	if (mode == SBBookmarkIconMode)
	{
		NSPoint spacing = [self spacing];
		CGFloat spacingX = 0;
		loc.y = (NSInteger)(point.y / cellSize.height);
		location = (point.x / (cellSize.width + spacing.x));
		if (location > (NSUInteger)location)
		{
			if ((location - (NSUInteger)location) > 0.5)
				loc.x = (NSInteger)location + 1;
			else
				loc.x = (NSInteger)location;
		}
		else {
			loc.x = (NSInteger)location;
		}
		index = _block.x * loc.y + loc.x;
		if (index > count)
		{
			loc.x = count - _block.x * loc.y;
		}
		NSLog(@"loc %@ index %d count %d location %f", NSStringFromPoint(loc), index, count, location);
		r.size.width = 5.0;
		r.size.height = cellSize.height;
		spacingX = loc.x > 0 ? (loc.x * spacing.x - spacing.x / 2) : 0;
		r.origin.x = loc.x * cellSize.width - r.size.width / 2 + spacingX;
		r.origin.y = loc.y * cellSize.height;
	}
	else if (mode == SBBookmarkListMode)
	{
		loc.y = (NSInteger)(point.y / 22.0);
		location = (point.y - loc.y * 22.0);
		if (location > 22.0 / 2)
		{
			loc.y += 1;
		}
		r.size.width = cellSize.width;
		r.size.height = 5.0;
		r.origin.y = loc.y * 22.0 - r.size.height / 2;
	}
	return r;
}

- (NSRect)removeButtonRect:(SBBookmarkListItemView *)itemView
{
	NSRect r = NSZeroRect;
	r.size.width = r.size.height = 24.0;
	if (itemView)
	{
		r.origin = itemView.frame.origin;
	}
	return r;
}

- (NSRect)editButtonRect:(SBBookmarkListItemView *)itemView
{
	NSRect r = NSZeroRect;
	r.size.width = r.size.height = 24.0;
	if (itemView)
	{
		r.origin = itemView.frame.origin;
	}
	r.origin.x += r.size.width;
	return r;
}

- (NSRect)updateButtonRect:(SBBookmarkListItemView *)itemView
{
	NSRect r = NSZeroRect;
	r.size.width = r.size.height = 24.0;
	if (itemView)
	{
		r.origin = itemView.frame.origin;
	}
	r.origin.x += r.size.width * 2;
	return r;
}

- (NSMutableArray *)items
{
	SBBookmarks *bookmarks = [SBBookmarks sharedBookmarks];
	return bookmarks.items;
}

- (NSArray *)getSelectedItems
{
	NSMutableArray *ditems = nil;
	ditems = [NSMutableArray arrayWithCapacity:0];
	for (SBBookmarkListItemView *itemView in itemViews)
	{
		if (itemView.selected)
		{
			NSDictionary *item = itemView.item;
			if (item)
				[ditems addObject:item];
		}
	}
	return [ditems count] > 0 ? [[ditems copy] autorelease] : nil;
}

- (BOOL)canScrollToNext
{
	BOOL r = NO;
	NSRect bounds = [self bounds];
	NSRect visibleRect = [self visibleRect];
	r = (NSMaxY(visibleRect) < NSMaxY(bounds));
	return r;
}

- (BOOL)canScrollToPrevious
{
	BOOL r = NO;
	NSRect visibleRect = [self visibleRect];
	r = (visibleRect.origin.y > 0);
	return r;
}

#pragma mark Destruction

- (void)destructSelectionView
{
	if (selectionView)
	{
		[selectionView removeFromSuperview];
		[selectionView release];
		selectionView = nil;
	}
}

- (void)destructDraggingLineView
{
	if (draggingLineView)
	{
		[draggingLineView removeFromSuperview];
		[draggingLineView release];
		draggingLineView = nil;
	}
}

- (void)destructControls
{
	if (removeButton)
	{
		[removeButton removeFromSuperview];
		[removeButton release];
		removeButton = nil;
	}
	if (editButton)
	{
		[editButton removeFromSuperview];
		[editButton release];
		editButton = nil;
	}
	if (updateButton)
	{
		[updateButton removeFromSuperview];
		[updateButton release];
		updateButton = nil;
	}
}

- (void)destructToolsTimer
{
	if (toolsTimer)
	{
		[toolsTimer invalidate];
		[toolsTimer release];
		toolsTimer = nil;
	}
}

#pragma mark Construction

- (void)constructControls
{
	NSRect removeRect = [self removeButtonRect:nil];
	NSRect editRect = [self editButtonRect:nil];
	NSRect updateRect = [self updateButtonRect:nil];
	[self destructControls];
	removeButton = [[SBButton alloc] initWithFrame:removeRect];
	editButton = [[SBButton alloc] initWithFrame:editRect];
	updateButton = [[SBButton alloc] initWithFrame:updateRect];
	[removeButton setAutoresizingMask:(NSViewMaxXMargin | NSViewMinYMargin)];
	removeButton.image = [NSImage imageWithCGImage:SBCloseIconImage(NSSizeToCGSize(removeRect.size))];
	removeButton.action = @selector(remove);
	[editButton setAutoresizingMask:(NSViewMaxXMargin | NSViewMinYMargin)];
	[updateButton setAutoresizingMask:(NSViewMaxXMargin | NSViewMinYMargin)];
	editButton.image = [NSImage imageWithCGImage:SBIconImage(@"Edit", NSSizeToCGSize(editRect.size))];
	updateButton.image = [NSImage imageWithCGImage:SBIconImage(@"Update", NSSizeToCGSize(editRect.size))];
	editButton.action = @selector(edit);
	updateButton.action = @selector(update);
}

#pragma mark Setter

- (void)setCellSizeForMode:(SBBookmarkMode)inMode
{
	mode = inMode;
	if (mode == SBBookmarkListMode)
	{
		cellSize = NSMakeSize([self width], 22.0);
	}
	else if (mode == SBBookmarkIconMode)
	{
		cellSize = NSMakeSize(cellWidth, cellWidth);
	}
}

- (void)setMode:(SBBookmarkMode)inMode
{
	if (mode != inMode)
	{
		[self setCellSizeForMode:inMode];
		[self layout:kSBBookmarkLayoutInterval];
	}
}

- (void)setCellWidth:(CGFloat)inCellWidth
{
	if (cellWidth != inCellWidth)
	{
		cellWidth = inCellWidth;
		cellSize = NSMakeSize(cellWidth, cellWidth);
		[self layout:0.0];
	}
}

#pragma mark Actions

- (void)addForItem:(NSDictionary *)item
{
	NSInteger index = [self.items count] - 1;
	[self layoutFrame];
	[self addItemViewAtIndex:index item:item];
}

- (void)addForItems:(NSArray *)inItems toIndex:(NSInteger)toIndex
{
	[self layoutFrame];
	[self addItemViewsToIndex:toIndex items:inItems];
}

- (void)createItemViews
{
	NSInteger index = 0;
	[self layoutFrame];
	if (itemViews)
	{
		[itemViews removeAllObjects];
		[itemViews release];
		itemViews = nil;
	}
	itemViews = [[NSMutableArray alloc] initWithCapacity:0];
	for (NSDictionary *item in self.items)
	{
		[self addItemViewAtIndex:index item:item];
		index++;
	}
}

- (void)addItemViewAtIndex:(NSInteger)index item:(NSDictionary *)item
{
	SBBookmarkListItemView *itemView = nil;
	NSRect r = [self itemRectAtIndex:index];
	itemView = [SBBookmarkListItemView viewWithFrame:r item:item];
	itemView.target = self;
	itemView.mode = mode;
	[itemViews insertObject:itemView atIndex:index];
	[self addSubview:itemView];
}

- (void)addItemViewsToIndex:(NSInteger)toIndex items:(NSArray *)inItems
{
	NSInteger index = toIndex;
	for (NSDictionary *item in inItems)
	{
		[self addItemViewAtIndex:index item:item];
		index++;
	}
	[self layoutItemViewsWithAnimationFromIndex:0];
}

- (void)moveItemViewsAtIndexes:(NSIndexSet *)indexes toIndex:(NSUInteger)toIndex
{
	NSArray *views = [itemViews objectsAtIndexes:indexes];
	if ([views count] > 0 && toIndex <= [itemViews count] && toIndex >= 0)
	{
		if ([itemViews containsIndexes:indexes])
		{
			NSUInteger to = toIndex;
			NSUInteger offset = 0;
			NSUInteger i = 0;
			for (i = [indexes lastIndex]; i != NSNotFound; i = [indexes indexLessThanIndex:i])
			{
				if (i < to)
					offset++;
			}
			if ((to - offset) >= 0)
				to -= offset;
			[views retain];
			[itemViews removeObjectsAtIndexes:indexes];
			[itemViews insertObjects:views atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(to, [indexes count])]];
			[views release];
		}
	}
}

- (void)removeItemView:(SBBookmarkListItemView *)itemView
{
	[itemView removeFromSuperview];
	[self removeItemViewsAtIndexes:[NSIndexSet indexSetWithIndex:[itemViews indexOfObject:itemView]]];
}

- (void)removeItemViewsAtIndexes:(NSIndexSet *)indexes
{
	SBBookmarks *bookmarks = [SBBookmarks sharedBookmarks];
	if ([itemViews containsIndexes:indexes] && [bookmarks.items containsIndexes:indexes])
	{
		[itemViews removeObjectsAtIndexes:indexes];
		[bookmarks removeItemsAtIndexes:indexes];
		[self layout:0];
	}
	[self layoutToolsHidden];
}

- (void)editItemView:(SBBookmarkListItemView *)itemView
{
	[self editItemViewsAtIndex:[itemViews indexOfObject:itemView]];
}

- (void)editItemViewsAtIndex:(NSUInteger)index
{
	[wrapperView executeShouldEditItemAtIndex:index];
}

- (void)openItemsAtIndexes:(NSIndexSet *)indexes
{
	SBBookmarks *bookmarks = [SBBookmarks sharedBookmarks];
	[bookmarks doubleClickItemsAtIndexes:indexes];
}

- (void)selectPoint:(NSPoint)point toPoint:(NSPoint)toPoint
{
	if (selectionView)
	{
		NSRect r = NSZeroRect;
		r = NSUnionRect(NSMakeRect(toPoint.x, toPoint.y, 1.0, 1.0), NSMakeRect(point.x, point.y, 1.0, 1.0));
		for (SBBookmarkListItemView *itemView in itemViews)
		{
			NSRect intersectionRect = NSIntersectionRect(r, itemView.frame);
			if (NSEqualRects(intersectionRect, NSZeroRect))
			{
				itemView.selected = NO;
			}
			else {
				NSRect intersectionRectInView = intersectionRect;
				intersectionRectInView.origin.x = intersectionRect.origin.x - itemView.frame.origin.x;
				intersectionRectInView.origin.y = intersectionRect.origin.y - itemView.frame.origin.y;
				intersectionRectInView.origin.y = itemView.frame.size.height - NSMaxY(intersectionRectInView);
				itemView.selected = [itemView hitToRect:intersectionRectInView];
			}
		}
	}
}

- (void)layout:(NSTimeInterval)animationTime
{
	[self layoutFrame];
	if (animationTime > 0)
	{
		[self layoutItemViewsWithAnimationFromIndex:0 duration:animationTime];
	}
	else {
		[self layoutItemViews];
	}
}

- (void)layoutFrame
{
	NSRect r = self.frame;
	_block = [self block];
	r.size.width = [self width];
	r.size.height = _block.y * cellSize.height;
	self.frame = r;
}

- (void)layoutItemViews
{
	NSInteger index = 0;
	if (mode == SBBookmarkListMode)
	{
		cellSize.width = [self width];
	}
	for (SBBookmarkListItemView *itemView in itemViews)
	{
		NSRect r = [self itemRectAtIndex:index];
		if (!NSEqualRects(itemView.frame, r))
		{
			itemView.mode = mode;
			itemView.frame = r;
		}
		index++;
	}
}

- (void)layoutItemViewsWithAnimationFromIndex:(NSInteger)fromIndex
{
	[self layoutItemViewsWithAnimationFromIndex:fromIndex duration:0.25];
}

- (void)layoutItemViewsWithAnimationFromIndex:(NSInteger)fromIndex duration:(NSTimeInterval)duration
{
	NSMutableArray *animations = [NSMutableArray arrayWithCapacity:0];
	NSInteger index = 0;
	NSInteger count = [itemViews count];
	for (index = fromIndex; index < count; index++)
	{
		SBBookmarkListItemView *itemView = [itemViews objectAtIndex:index];
		NSRect r = [self itemRectAtIndex:index];
		itemView.mode = mode;
		if (!NSEqualRects(itemView.frame, r))
		{
			NSRect visibleRect = [self visibleRect];
			if (NSIntersectsRect(visibleRect, itemView.frame) || NSIntersectsRect(visibleRect, r))	// Only visible views
			{
				NSMutableDictionary *info = [NSMutableDictionary dictionaryWithCapacity:0];
				[info setObject:itemView forKey:NSViewAnimationTargetKey];
				[info setObject:[NSValue valueWithRect:itemView.frame] forKey:NSViewAnimationStartFrameKey];
				[info setObject:[NSValue valueWithRect:r] forKey:NSViewAnimationEndFrameKey];
				[animations addObject:[[info copy] autorelease]];
			}
			else {
				itemView.frame = r;
			}
		}
	}
	if ([animations count] > 0)
	{
		NSViewAnimation *animation = [[[NSViewAnimation alloc] initWithViewAnimations:animations] autorelease];
		[animation setDuration:duration];
		[animation setDelegate:self];
		[animation startAnimation];
	}
}

- (void)layoutSelectionView:(NSPoint)point
{
	NSRect r = NSZeroRect;
	if (!selectionView)
	{
		selectionView = [[SBView alloc] initWithFrame:NSZeroRect];
		selectionView.frameColor = [NSColor alternateSelectedControlColor];
		[self addSubview:selectionView];
	}
	r = NSUnionRect(NSMakeRect(_point.x, _point.y, 1.0, 1.0), NSMakeRect(point.x, point.y, 1.0, 1.0));
	selectionView.frame = r;
}

- (void)layoutToolsForItem:(SBBookmarkListItemView *)itemView
{
	if (toolsItemView != itemView)
	{
		toolsItemView = itemView;
		[self destructToolsTimer];
		toolsTimer = [NSTimer scheduledTimerWithTimeInterval:kSBBookmarkToolsInterval target:self selector:@selector(layoutTools) userInfo:nil repeats:NO];
		[toolsTimer retain];
	}
}

- (void)layoutTools
{
	[self destructToolsTimer];
	if (toolsItemView)
	{
		removeButton.frame = [self removeButtonRect:toolsItemView];
		editButton.frame = [self editButtonRect:toolsItemView];
		updateButton.frame = [self updateButtonRect:toolsItemView];
		removeButton.target = toolsItemView;
		editButton.target = toolsItemView;
		updateButton.target = toolsItemView;
		[self addSubview:removeButton];
		[self addSubview:editButton];
		[self addSubview:updateButton];
		[toolsItemView setNeedsDisplay:YES];
	}
}

- (void)layoutToolsHidden
{
	removeButton.target = nil;
	editButton.target = nil;
	updateButton.target = nil;
	[removeButton removeFromSuperview];
	[editButton removeFromSuperview];
	[updateButton removeFromSuperview];
	toolsItemView = nil;
}

- (void)layoutDraggingLineView:(NSPoint)point
{
	NSRect r = NSZeroRect;
	if (!draggingLineView)
	{
		draggingLineView = [[SBView alloc] initWithFrame:NSZeroRect];
		draggingLineView.frameColor = [NSColor alternateSelectedControlColor];
		[self addSubview:draggingLineView];
	}
	r = [self dragginLineRectAtPoint:point];
	draggingLineView.frame = r;
}

- (void)updateItems
{
	NSUInteger index = 0;
	for (SBBookmarkListItemView *itemView in itemViews)
	{
		NSDictionary *item = [self.items objectAtIndex:index];
		itemView.item = item;
		[itemView setNeedsDisplay:YES];
		index++;
	}
}

- (void)scrollToNext
{
	NSRect bounds = [self bounds];
	NSRect visibleRect = [self visibleRect];
	NSRect r = visibleRect;
	if ((NSMaxY(visibleRect) + visibleRect.size.height) < bounds.size.height)
	{
		r.origin.y = NSMaxY(visibleRect);
	}
	else {
		r.origin.y = bounds.size.height - visibleRect.size.height;
	}
	[self scrollRectToVisible:r];
}

- (void)scrollToPrevious
{
	NSRect visibleRect = [self visibleRect];
	NSRect r = visibleRect;
	if ((visibleRect.origin.y - visibleRect.size.height) > 0)
	{
		r.origin.y = visibleRect.origin.y - visibleRect.size.height;
	}
	else {
		r.origin.y = 0;
	}
	[self scrollRectToVisible:r];
}

- (void)needsDisplaySelectedItemViews
{
	for (SBBookmarkListItemView *itemView in itemViews)
	{
		if (itemView.selected)
			[itemView setNeedsDisplay:YES];
	}
}

#pragma mark Menu Actions

- (void)delete:(id)sender
{
	NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
	NSInteger index = 0;
	for (SBBookmarkListItemView *itemView in itemViews)
	{
		if (itemView.selected)
		{
			[itemView removeFromSuperview];
			[indexes addIndex:index];
		}
		index++;
	}
	[self removeItemViewsAtIndexes:[[indexes copy] autorelease]];
}

- (void)selectAll:(id)sender
{
	for (SBBookmarkListItemView *itemView in itemViews)
	{
		if (!itemView.selected)
		{
			itemView.selected = YES;
		}
	}
}

- (void)openSelectedItems:(id)sender
{
	NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
	NSInteger index = 0;
	for (SBBookmarkListItemView *itemView in itemViews)
	{
		if (itemView.selected)
		{
			[indexes addIndex:index];
		}
		index++;
	}
	[self openItemsAtIndexes:[[indexes copy] autorelease]];
}

#pragma mark Event

- (void)mouseDown:(NSEvent *)theEvent
{
	if([theEvent clickCount] == 2)
	{
		
	}
	else {
		NSPoint location = [theEvent locationInWindow];
		NSUInteger modifierFlags = [theEvent modifierFlags];
		NSMutableArray *selectedViews = [NSMutableArray arrayWithCapacity:0];
		NSInteger index = 0;
		BOOL alreadySelect = NO;
		BOOL selection = NO;
		_point = [self convertPoint:location fromView:nil];
		for (SBBookmarkListItemView *itemView in itemViews)
		{
			NSRect r = [self itemRectAtIndex:index];
			if ([itemView hitToPoint:NSMakePoint(_point.x - r.origin.x, r.size.height - (_point.y - r.origin.y))])
			{
				selection = YES;
				alreadySelect = itemView.selected;
				itemView.selected = YES;
			}
			else {
				if (itemView.selected)
				{
					[selectedViews addObject:itemView];
				}
			}
			index++;
		}
		if (!alreadySelect && !(modifierFlags & NSCommandKeyMask) && !(modifierFlags & NSShiftKeyMask))
		{
			for (SBBookmarkListItemView *itemView in selectedViews)
			{
				itemView.selected = NO;
			}
		}
		if (selection)
		{
			_point = NSZeroPoint;
		}
	}
	draggedItemView.dragged = NO;
	draggedItemView = nil;
	self.draggedItems = nil;
	[self destructSelectionView];
	[self destructDraggingLineView];
}

- (void)mouseDragged:(NSEvent*)theEvent
{
	NSPoint location = [theEvent locationInWindow];
	NSPoint point = [self convertPoint:location fromView:nil];
	if (NSEqualPoints(_point, NSZeroPoint))
	{
		// Drag
		if (draggedItemView && draggedItems)
		{
			NSImage *image = [NSImage imageWithView:draggedItemView];
			NSSize offset = NSMakeSize(draggedItemView.frame.origin.x - point.x, point.y - draggedItemView.frame.origin.y);
			NSPoint dragLocation = NSMakePoint(point.x + offset.width, point.y + (draggedItemView.frame.size.height - offset.height));
			NSPasteboard *pasteboard = [NSPasteboard pasteboardWithName:NSDragPboard];
			NSString *title = [draggedItemView.item objectForKey:kSBBookmarkTitle];
			NSData *imageData = [draggedItemView.item objectForKey:kSBBookmarkImage];
			NSString *urlString = [draggedItemView.item objectForKey:kSBBookmarkURL];
			NSURL *url = urlString ? [NSURL URLWithString:urlString] : nil;
			[pasteboard declareTypes:[NSArray arrayWithObjects:SBBookmarkPboardType, NSURLPboardType, nil] owner:nil];
			if (draggedItems)
				[pasteboard setPropertyList:draggedItems forType:SBBookmarkPboardType];
			if (url)
				[url writeToPasteboard:pasteboard];
			if (title)
				[pasteboard setString:title forType:NSStringPboardType];
			if (imageData)
				[pasteboard setData:imageData forType:NSTIFFPboardType];
			[self dragImage:image at:dragLocation offset:NSZeroSize event:theEvent pasteboard:pasteboard source:[self window] slideBack:YES];
			draggedItemView.dragged = NO;
		}
		else {
			draggedItemView = [self itemViewAtPoint:point];
			self.draggedItems = [self getSelectedItems];
			if (draggedItemView && draggedItems)	
			{
				draggedItemView.dragged = YES;
				[self layoutToolsHidden];
			}
		}
	}
	else {
		// Selection
		[self autoscroll:theEvent];
		[self layoutSelectionView:point];
		[self selectPoint:point toPoint:_point];
	}
}

- (void)mouseUp:(NSEvent*)theEvent
{
	if([theEvent clickCount] == 2)
	{
		NSPoint location = [theEvent locationInWindow];
		NSPoint point = [self convertPoint:location fromView:nil];
		NSInteger index = 0;
		for (SBBookmarkListItemView *itemView in itemViews)
		{
			NSRect r = [self itemRectAtIndex:index];
			if ([itemView hitToPoint:NSMakePoint(point.x - r.origin.x, r.size.height - (point.y - r.origin.y))])
			{
				[self openSelectedItems:nil];
				break;
			}
			index++;
		}
	}
	draggedItemView.dragged = NO;
	draggedItemView = nil;
	self.draggedItems = nil;
	[self destructSelectionView];
	[self destructDraggingLineView];
}

- (void)mouseEntered:(NSEvent *)theEvent
{
	[self layoutToolsHidden];
}

- (void)mouseExited:(NSEvent *)theEvent
{
	[self layoutToolsHidden];
}

- (void)rightMouseDown:(NSEvent *)theEvent
{
	NSMenu *menu = nil;
	[self mouseDown:theEvent];
	menu = [self menuForEvent:theEvent];
	_point = NSZeroPoint;
	draggedItemView.dragged = NO;
	draggedItemView = nil;
	self.draggedItems = nil;
	[self destructSelectionView];
	[self destructDraggingLineView];
	if (menu)
	{
		[NSMenu popUpContextMenu:menu withEvent:theEvent forView:self];
	}
}

- (void)keyDown:(NSEvent *)theEvent
{
	NSString *characters = [theEvent characters];
	unichar character = [characters characterAtIndex:0];
	if (character == NSDeleteCharacter)
	{
		[self delete:nil];
	}
	else if (character == NSEnterCharacter || character == NSCarriageReturnCharacter)
	{
		[self openSelectedItems:nil];
	}
}

- (NSMenu *)menuForEvent:(NSEvent *)theEvent
{
	NSMenu *menu = nil;
	NSIndexSet *indexes = [self selectedIndexes];
	if ([indexes count] > 0)
	{
		SBBookmarks *bookmarks = nil;
		NSUInteger i = 0;
		NSMutableArray *representedItems = nil;
		NSString *title = nil;
		NSMenuItem *openItem = nil;
		NSMenuItem *removeItem = nil;
		NSMenuItem *labelsItem = nil;
		NSMenu *labelsMenu = nil;
		bookmarks = [SBBookmarks sharedBookmarks];
		representedItems = [NSMutableArray arrayWithCapacity:0];
		menu = [[[NSMenu alloc] init] autorelease];
		title = indexes.count == 1 ? NSLocalizedString(@"Open an item", nil) : [NSString stringWithFormat:NSLocalizedString(@"Open %d items", nil), indexes.count];
		openItem = [[[NSMenuItem alloc] initWithTitle:title action:@selector(openItemsFromMenuItem:) keyEquivalent:[NSString string]] autorelease];
		title = indexes.count == 1 ? NSLocalizedString(@"Remove an item", nil) : [NSString stringWithFormat:NSLocalizedString(@"Remove %d items", nil), indexes.count];
		removeItem = [[[NSMenuItem alloc] initWithTitle:title action:@selector(removeItemsFromMenuItem:) keyEquivalent:[NSString string]] autorelease];
		labelsItem = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Label", nil) action:nil keyEquivalent:[NSString string]] autorelease];
		[openItem setTarget:bookmarks];
		[removeItem setTarget:bookmarks];
		for (i = [indexes lastIndex]; i != NSNotFound; i = [indexes indexLessThanIndex:i])
		{
			NSDictionary *item = [bookmarks.items objectAtIndex:i];
			if (item)
				[representedItems addObject:item];
		}
		[openItem setRepresentedObject:representedItems];
		[removeItem setRepresentedObject:indexes];
		labelsMenu = SBBookmarkLabelColorMenu(NO, bookmarks, @selector(changeLabelFromMenuItem:), indexes);
		[labelsItem setSubmenu:labelsMenu];
		[menu addItem:openItem];
		[menu addItem:removeItem];
		[menu addItem:[NSMenuItem separatorItem]];
		[menu addItem:labelsItem];
	}
	return menu;
}

#pragma mark Dragging DataSource

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender
{
	return NSDragOperationCopy;
}

- (void)draggingExited:(id < NSDraggingInfo >)sender
{
	[self destructDraggingLineView];
}

- (NSDragOperation)draggingUpdated:(id<NSDraggingInfo>)sender
{
	NSPoint point = [self convertPoint:[sender draggingLocation] fromView:nil];
	[self layoutDraggingLineView:point];
	[self autoscroll:[NSApp currentEvent]];
	return NSDragOperationCopy;
}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender
{
	BOOL r = YES;
	NSPasteboard *pasteboard = [sender draggingPasteboard];
	NSPoint point = [self convertPoint:[sender draggingLocation] fromView:nil];
	SBBookmarks *bookmarks = nil;
	NSArray *types = [pasteboard types];
	NSArray *pbItems = [pasteboard propertyListForType:SBBookmarkPboardType];
	
	if ([types containsObject:SBBookmarkPboardType] && [pbItems count] > 0)
	{
		bookmarks = [SBBookmarks sharedBookmarks];
		NSIndexSet *indexes = [bookmarks indexesOfItems:pbItems];
		NSUInteger toIndex = [self indexAtPoint:point];
		if ([indexes count] > 0)
		{
			// Move item
			[bookmarks moveItemsAtIndexes:indexes toIndex:toIndex];
			[self moveItemViewsAtIndexes:indexes toIndex:toIndex];
			[self layoutItemViewsWithAnimationFromIndex:0];
		}
	}
	else if ([types containsObject:NSURLPboardType])
	{
		NSString *url = [[NSURL URLFromPasteboard:pasteboard] absoluteString];
		NSString *title = nil;
		NSData *data = nil;
		if ([types containsObject:NSStringPboardType])
		{
			title = [pasteboard stringForType:NSStringPboardType];
		}
		else {
			title = NSLocalizedString(@"Untitled", nil);
		}
		if ([types containsObject:NSTIFFPboardType])
		{
			BOOL shouldInset = YES;
			NSImage *image = nil;
			data = [pasteboard dataForType:NSTIFFPboardType];
			if (image = [[[NSImage alloc] initWithData:data] autorelease])
			{
				shouldInset = !NSEqualSizes([image size], SBBookmarkImageMaxSize());
			}
			if (shouldInset)
			{
				NSBitmapImageRep *bitmapImageRep = nil;
				NSImage *insetImage = nil;
				insetImage = [[[[NSImage alloc] initWithData:data] autorelease] insetWithSize:SBBookmarkImageMaxSize() intersectRect:NSZeroRect offset:NSZeroPoint];
				if (insetImage)
					bitmapImageRep = [insetImage bitmapImageRep];
				if (bitmapImageRep)
					data = [bitmapImageRep data];
			}
		}
		else {
			data = SBDefaultBookmarkImageData();
		}
		
		if (url)
		{
			bookmarks = [SBBookmarks sharedBookmarks];
			NSDictionary *item = SBCreateBookmarkItem(title, url, data, [NSDate date], nil, NSStringFromPoint(NSZeroPoint));
			NSInteger fromIndex = [bookmarks containsItem:item];
			NSUInteger toIndex = [self indexAtPoint:point];
			NSMutableArray *bookmarkItems = [NSMutableArray arrayWithCapacity:0];
			if (fromIndex != NSNotFound)
			{
				// Move item
				[bookmarks moveItemsAtIndexes:[NSIndexSet indexSetWithIndex:fromIndex] toIndex:toIndex];
				[self moveItemViewsAtIndexes:[NSIndexSet indexSetWithIndex:fromIndex] toIndex:toIndex];
				[self layoutItemViewsWithAnimationFromIndex:0];
			}
			else {
				// add as new item
				if (toIndex != NSNotFound)
				{
					[bookmarkItems addObject:item];
					[bookmarks addItems:bookmarkItems toIndex:toIndex];
					[self addForItems:bookmarkItems toIndex:toIndex];
				}
			}
		}
	}
	[self destructDraggingLineView];
	return r;
}

#pragma mark Drawing

- (void)drawRect:(NSRect)rect
{
	[super drawRect:rect];
}

#pragma mark Gesture(10.6only)

- (BOOL)acceptsTouchEvents
{
	return YES;
}

- (void)swipeWithEvent:(NSEvent *)event
{
	CGFloat deltaX = [event deltaX];
	if (deltaX > 0)			// Left
	{
		if ([self canScrollToPrevious])
		{
			[self scrollToPrevious];
		}
		else {
			NSBeep();
		}
	}
	else if (deltaX < 0)	// Right
	{
		if ([self canScrollToNext])
		{
			[self scrollToNext];
		}
		else {
			NSBeep();
		}
	}
}

@end
