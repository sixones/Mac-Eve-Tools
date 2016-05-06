#import <Cocoa/Cocoa.h>

#import "StatusItemViewController.h"

@class Character;
@class MainController;

@interface StatusItemWindow : NSWindow {
    @private
    StatusItemViewController* _controller;
    MainController* _mainController;
    NSView *_view;
    NSPoint _point;
}

- (StatusItemWindow *) initWithController: (StatusItemViewController*) controller attachedToPoint: (NSPoint) point andMainController: (MainController*) mainController;
- (void) setCharacter: (Character*) character;

@end
