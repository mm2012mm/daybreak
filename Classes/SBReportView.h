/*
 
SBReportView.h
 
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

#import "SBDefinitions.h"
#import "SBBLKGUI.h"
#import "SBView.h"


@interface SBReportView : SBView <NSTextFieldDelegate>
{
	NSImageView *iconImageView;
	NSTextField *titleLabel;
	NSTextField *summeryLabel;
	SBBLKGUITextField *summeryField;
	NSTextField *userAgentLabel;
	SBBLKGUIPopUpButton *userAgentPopup;
	NSTextField *switchLabel;
	NSMatrix *switchMatrix;
	NSTextField *wayLabel;
	SBBLKGUITextField *wayField;
	SBBLKGUIButton *cancelButton;
	SBBLKGUIButton *doneButton;
}
@property (nonatomic, readonly) NSPoint margin;
@property (nonatomic, readonly) CGFloat labelWidth;
@property (nonatomic, readonly) NSRect iconRect;
@property (nonatomic, readonly) NSRect titleRect;
@property (nonatomic, readonly) NSRect summeryLabelRect;
@property (nonatomic, readonly) NSRect summeryFieldRect;
@property (nonatomic, readonly) NSRect switchLabelRect;
@property (nonatomic, readonly) NSRect switchRect;
@property (nonatomic, readonly) NSRect wayLabelRect;
@property (nonatomic, readonly) NSRect wayFieldRect;
@property (nonatomic, readonly) NSRect cancelRect;
@property (nonatomic, readonly) NSRect doneRect;

// Construction
- (void)constructTitle;
- (void)constructSummery;
- (void)constructUserAgent;
- (void)constructSwitch;
- (void)constructWay;
- (void)constructButtons;
// Actions
- (void)validateDoneButton;
- (void)selectApp:(id)sender;
- (void)switchReproducibility:(id)sender;
- (NSString *)sendMailWithMessage:(NSString *)message subject:(NSString *)subject to:(NSArray *)addresses;

@end
