#import "StatusItemView.h"

@implementation StatusItemView

- (id) initWithFrame: (NSRect)frame controller: (MainController*) mainController {
    self = [super initWithFrame:frame];
    
    if (self) {
        controller = mainController;
    }
    
    return self;
}

- (void)drawRect:(NSRect) dirtyRect {
    if (opened) {
        [[NSColor selectedMenuItemColor] set];
        
        NSRectFill(dirtyRect);
    }

    NSSize targetSize = NSMakeSize(16, 16);
    NSRect targetRect = NSMakeRect(0, 0, targetSize.width, targetSize.height);
    targetRect.origin.x = ([self frame].size.width - targetSize.width) / 2.0;
    targetRect.origin.y = ([self frame].size.height - targetSize.height) / 2.0;
        
    NSImage *statusIcon = [NSImage imageNamed: @"status.png"];
    [statusIcon setSize: targetSize];
    
    [statusIcon drawInRect: targetRect fromRect: NSMakeRect(0, 0, 16, 16) operation: NSCompositeSourceOver fraction: 1.0];
}

- (void) mouseDown: (NSEvent*) event {
    opened = !opened;
    
    if (opened) {
        NSRect frame = [[self window] frame];
        NSPoint point = NSMakePoint(NSMidX(frame), NSMinY(frame));
        
        [controller openStatusWindowAt: point];
    } else {
        [controller closeStatusWindow];
    }
}

- (BOOL) isOpen {
    return opened;
}

- (void) open {
    opened = YES;
    
    [self setNeedsDisplay: YES];
}

- (void) close {
    opened = NO;
    
    [self setNeedsDisplay: YES];
}

- (void) dealloc {
    controller = nil;
    
    [super dealloc];
}

@end
