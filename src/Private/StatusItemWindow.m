#import "StatusItemWindow.h"

#import "Character.h"
#import "MainController.h"

@implementation StatusItemWindow

- (StatusItemWindow *) initWithController: (StatusItemViewController*) controller attachedToPoint: (NSPoint) point andMainController: (MainController *) mainController {
    NSView *view = controller.view;
    NSRect contentRect = NSMakeRect(0, 0, [view frame].size.width, [view frame].size.height);
    
    if ((self = [super initWithContentRect: contentRect styleMask: NSBorderlessWindowMask backing: NSBackingStoreBuffered defer: NO])) {
        _controller = controller;
        _mainController = mainController;
        _view = view;
        _point = point;
        
        [super setBackgroundColor: [NSColor colorWithCalibratedRed: 1.0f green: 1.0f blue: 1.0f alpha: 0.8f]];
        
        [self setMovableByWindowBackground: NO];
        [self setExcludedFromWindowsMenu: YES];
        [self setAlphaValue: 1.0];
        [self setOpaque: NO];
        [self setHasShadow: YES];
        [self useOptimizedDrawing: YES];
        
        _view.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
        
        [[self contentView] addSubview: _view];
        
        [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(windowDidResignKey:) name: NSWindowDidResignMainNotification object: self];
        [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(windowDidResignKey:) name: NSWindowDidResignKeyNotification object: self];
        
        [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(windowDidResize:) name: NSWindowDidResizeNotification object: self];

        [self updatePosition];
    }
    
    return self;
}

- (void) setCharacter: (Character*) character {
    [_controller setCharacter: character];
}

- (void) updatePosition {
    NSRect contentRect = NSMakeRect(0, 0, [_view frame].size.width, [_view frame].size.height);
    
    contentRect.origin = _point;
    
    contentRect.origin.x -= contentRect.size.width - 15;
    contentRect.origin.y -= contentRect.size.height;
    
    [self setFrame: contentRect display: NO];
}

- (void) windowDidResignKey: (NSNotification*) notification {   
    [_mainController closeStatusWindow];
}

- (void) windowDidResize: (NSNotification *) notification {
    [self updatePosition];
}

- (BOOL) canBecomeKeyWindow {
    return YES;
}

- (BOOL) canBecomeMainWindow {
    return NO;
}

- (BOOL) isExcludedFromWindowsMenu {
    return YES;
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver: self name: NSWindowDidResignMainNotification object: self];
    [[NSNotificationCenter defaultCenter] removeObserver: self name: NSWindowDidResignKeyNotification object: self];
    [[NSNotificationCenter defaultCenter] removeObserver: self name: NSWindowDidResizeNotification object: self];
    
    [super dealloc];
}

@end
