#import <Cocoa/Cocoa.h>

#import "MainController.h"

@interface StatusItemView : NSView {
    __weak MainController *controller;
    
    BOOL opened;
}

- (id) initWithFrame: (NSRect)frame controller: (MainController*)ctrlr;

- (void) open;
- (void) close;

- (BOOL) isOpen;


@end
