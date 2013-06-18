#import <Cocoa/Cocoa.h>

#import "StatusItemViewController.h"

@class Character;
@class MainController;

@interface StatusItemWindow : NSWindow {
    @private
    __weak StatusItemViewController* _controller;
    __weak MainController* _mainController;
    __weak NSView *_view;
    NSPoint _point;
}

- (StatusItemWindow *) initWithController: (StatusItemViewController*) controller attachedToPoint: (NSPoint) point andMainController: (MainController*) mainController;
- (void) setCharacter: (Character*) character;

@end
