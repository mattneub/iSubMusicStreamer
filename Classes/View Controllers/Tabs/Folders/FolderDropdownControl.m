//
//  FolderDropdownControl.m
//  iSub
//
//  Created by Ben Baron on 3/19/11.
//  Copyright 2011 Ben Baron. All rights reserved.
//

#import "FolderDropdownControl.h"
#import "SUSDropdownFolderLoader.h"
#import <QuartzCore/QuartzCore.h>
#import "Defines.h"
#import "SUSRootFoldersDAO.h"
#import "EX2Kit.h"



#define HEIGHT 40

@interface FolderDropdownControl() {
    __strong NSDictionary *_folders;
}
@end

@implementation FolderDropdownControl

// TODO: Redraw border color after switching between light/dark mode
- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
		_selectedFolderId = @-1;
		_folders = [SUSRootFoldersDAO folderDropdownFolders];
		_labels = [[NSMutableArray alloc] init];
		_isOpen = NO;
        _borderColor = UIColor.systemGrayColor;
        _textColor   = UIColor.labelColor;
        _lightColor  = [UIColor colorNamed:@"isubBackgroundColor"];
        _darkColor   = [UIColor colorNamed:@"isubBackgroundColor"];
		
		self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		self.userInteractionEnabled = YES;
        self.backgroundColor = UIColor.systemGray5Color;
		self.layer.borderColor = _borderColor.CGColor;
		self.layer.borderWidth = 2.0;
		self.layer.cornerRadius = 8;
		self.layer.masksToBounds = YES;
		
		_selectedFolderLabel = [[UILabel alloc] initWithFrame:CGRectMake(5, 0, self.frame.size.width - 10, HEIGHT)];
		_selectedFolderLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		_selectedFolderLabel.userInteractionEnabled = YES;
		_selectedFolderLabel.backgroundColor = [UIColor clearColor];
        _selectedFolderLabel.textColor = _textColor;
		_selectedFolderLabel.textAlignment = NSTextAlignmentCenter;
        _selectedFolderLabel.font = [UIFont boldSystemFontOfSize:20];
		_selectedFolderLabel.text = @"All Folders";
		[self addSubview:_selectedFolderLabel];
		
		UIView *arrowImageView = [[UIView alloc] initWithFrame:CGRectMake(193, 12, 18, 18)];
		arrowImageView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
		[self addSubview:arrowImageView];
		
		_arrowImage = [[CALayer alloc] init];
		_arrowImage.frame = CGRectMake(0, 0, 18, 18);
		_arrowImage.contentsGravity = kCAGravityResizeAspect;
		_arrowImage.contents = (id)[UIImage imageNamed:@"folder-dropdown-arrow"].CGImage;
		[[arrowImageView layer] addSublayer:_arrowImage];
		
		_dropdownButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 220, HEIGHT)];
		_dropdownButton.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		[_dropdownButton addTarget:self action:@selector(toggleDropdown:) forControlEvents:UIControlEventTouchUpInside];
        _dropdownButton.accessibilityLabel = _selectedFolderLabel.text;
        _dropdownButton.accessibilityHint = @"Switches folders";
		[self addSubview:_dropdownButton];
		
		[self updateFolders];
    }
    return self;
}

NSInteger folderSort2(id keyVal1, id keyVal2, void *context) {
    NSString *folder1 = [(NSArray*)keyVal1 objectAtIndexSafe:1];
	NSString *folder2 = [(NSArray*)keyVal2 objectAtIndexSafe:1];
	return [folder1 caseInsensitiveCompare:folder2];
}

- (NSDictionary *)folders {
	return _folders;
}

- (void)setFolders:(NSDictionary *)namesAndIds {
	// Set the property
	_folders = namesAndIds;
	
	// Remove old labels
	for (UILabel *label in self.labels) {
		[label removeFromSuperview];
	}
	[self.labels removeAllObjects];
	
	self.sizeIncrease = _folders.count * HEIGHT;
	
	NSMutableArray *sortedValues = [NSMutableArray arrayWithCapacity:_folders.count];
	for (NSNumber *key in _folders.allKeys) {
		if ([key intValue] != -1) {
			NSArray *keyValuePair = @[ key, _folders[key] ];
			[sortedValues addObject:keyValuePair];
		}
	}
	
	// Sort by folder name
	[sortedValues sortUsingFunction:folderSort2 context:NULL];
	
	// Add All Folders again
	NSArray *keyValuePair = @[@"-1", @"All Folders"];
	[sortedValues insertObject:keyValuePair atIndex:0];
	
	// Process the names and create the labels/buttons
	for (int i = 0; i < [sortedValues count]; i++) {
		NSString *folder   = [[sortedValues objectAtIndexSafe:i] objectAtIndexSafe:1];
		NSUInteger tag     = [[[sortedValues objectAtIndexSafe:i] objectAtIndexSafe:0] intValue];
		CGRect labelFrame  = CGRectMake(0, (i + 1) * HEIGHT, self.frame.size.width, HEIGHT);
		CGRect buttonFrame = CGRectMake(0, 0, labelFrame.size.width, labelFrame.size.height);
		
		UILabel *folderLabel = [[UILabel alloc] initWithFrame:labelFrame];
		folderLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		folderLabel.userInteractionEnabled = YES;
		//folderLabel.alpha = 0.0;
		if (i % 2 == 0)
			folderLabel.backgroundColor = self.lightColor;
		else
			folderLabel.backgroundColor = self.darkColor;
		folderLabel.textColor = self.textColor;
		folderLabel.textAlignment = NSTextAlignmentCenter;
        folderLabel.font = [UIFont boldSystemFontOfSize:20];
		folderLabel.text = folder;
		folderLabel.tag = tag;
        folderLabel.isAccessibilityElement = NO;
		[self addSubview:folderLabel];
		[self.labels addObject:folderLabel];
		
		UIButton *folderButton = [UIButton buttonWithType:UIButtonTypeCustom];
		folderButton.frame = buttonFrame;
		folderButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        folderButton.accessibilityLabel = folderLabel.text;
		[folderButton addTarget:self action:@selector(selectFolder:) forControlEvents:UIControlEventTouchUpInside];
		[folderLabel addSubview:folderButton];
        folderButton.isAccessibilityElement = self.isOpen;
	}
    
    self.selectedFolderLabel.text = [self.folders objectForKey:self.selectedFolderId];
}

- (void)toggleDropdown:(id)sender {
	if (self.isOpen) {
        // Close it
        [UIView animateWithDuration:.25 animations:^{
            self.height -= self.sizeIncrease;
            if ([self.delegate respondsToSelector:@selector(folderDropdownMoveViewsY:)]) {
                [self.delegate folderDropdownMoveViewsY:-self.sizeIncrease];
            }
         } completion:^(BOOL finished) {
             if ([self.delegate respondsToSelector:@selector(folderDropdownViewsFinishedMoving)]) {
                 [self.delegate folderDropdownViewsFinishedMoving];
             }
         }];
		
		[CATransaction begin];
		[CATransaction setAnimationDuration:.25];
		self.arrowImage.transform = CATransform3DMakeRotation((M_PI / 180.0) * 0.0f, 0.0f, 0.0f, 1.0f);
		[CATransaction commit];
    } else {
        // Open it
		[UIView animateWithDuration:.25 animations:^{
			self.height += self.sizeIncrease;
            if ([self.delegate respondsToSelector:@selector(folderDropdownMoveViewsY:)]) {
                [self.delegate folderDropdownMoveViewsY:self.sizeIncrease];
            }
		} completion:^(BOOL finished) {
            if ([self.delegate respondsToSelector:@selector(folderDropdownViewsFinishedMoving)]) {
                [self.delegate folderDropdownViewsFinishedMoving];
            }
		}];
				
		[CATransaction begin];
		[CATransaction setAnimationDuration:.25];
		self.arrowImage.transform = CATransform3DMakeRotation((M_PI / 180.0) * -60.0f, 0.0f, 0.0f, 1.0f);
		[CATransaction commit];
	}
	
	self.isOpen = !self.isOpen;
    
    // Remove accessibility when not visible
    for (UILabel *label in self.labels) {
        for (UIView *subview in label.subviews) {
            if ([subview isKindOfClass:[UIButton class]]) {
                subview.isAccessibilityElement = self.isOpen;
            }
        }
    }
    
    UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil);
}

- (void)closeDropdown {
	if (self.isOpen) {
		[self toggleDropdown:nil];
	}
}

- (void)closeDropdownFast {
	if (self.isOpen) {
		self.isOpen = NO;
		
		self.height -= self.sizeIncrease;
        if ([self.delegate respondsToSelector:@selector(folderDropdownMoveViewsY:)]) {
            [self.delegate folderDropdownMoveViewsY:-self.sizeIncrease];
        }
		
		self.arrowImage.transform = CATransform3DMakeRotation((M_PI / 180.0) * 0.0f, 0.0f, 0.0f, 1.0f);
		
        if ([self.delegate respondsToSelector:@selector(folderDropdownViewsFinishedMoving)]) {
            [self.delegate folderDropdownViewsFinishedMoving];
        }
	}
}

- (void)selectFolder:(id)sender {
	UIButton *button = (UIButton *)sender;
	UILabel  *label  = (UILabel *)button.superview;
	
	//DLog(@"Folder selected: %@ -- %i", label.text, label.tag);
	
	self.selectedFolderId = @(label.tag);
	self.selectedFolderLabel.text = [self.folders objectForKey:self.selectedFolderId];
    self.dropdownButton.accessibilityLabel = self.selectedFolderLabel.text;
	//[self toggleDropdown:nil];
	[self closeDropdownFast];
	
	// Call the delegate method
    if ([self.delegate respondsToSelector:@selector(folderDropdownSelectFolder:)]) {
        [self.delegate folderDropdownSelectFolder:self.selectedFolderId];
    }
}

- (void)selectFolderWithId:(NSNumber *)folderId {
	self.selectedFolderId = folderId;
	self.selectedFolderLabel.text = [self.folders objectForKey:self.selectedFolderId];
    self.dropdownButton.accessibilityLabel = self.selectedFolderLabel.text;
}

- (void)updateFolders {
    SUSDropdownFolderLoader *loader = [[SUSDropdownFolderLoader alloc] initWithCallbackBlock:^(BOOL success, NSError *error, SUSLoader *loader) {
        SUSDropdownFolderLoader *theLoader = (SUSDropdownFolderLoader *)loader;
        if (success) {
            self.folders = theLoader.updatedfolders;
            [SUSRootFoldersDAO setFolderDropdownFolders:self.folders];
        } else {
            // TODO: Handle error
            // failed.  how to report this to the user?
            NSLog(@"[FolderDropdownControl] failed to update folders: %@", error.localizedDescription);
        }
    }];
    [loader startLoad];
    
    // Save the default
    [SUSRootFoldersDAO setFolderDropdownFolders:self.folders];
}

@end
