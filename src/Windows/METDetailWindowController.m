//
//  METDetailWindowController.m
//  Vitality
//
//  Created by Andrew Salamon on 6/22/15.
//  Copyright (c) 2015 Sebastian Kruemling. All rights reserved.
//

#import "METDetailWindowController.h"

#import "macros.h"
#import "CCPType.h"
#import "CCPGroup.h"
#import "ShipDetailsWindowController.h"
#import "ModuleDetailsWindowController.h"
#import "SkillDetailsWindowController.h"

/**
 This is currently a bit of a placeholder.
 There is enough similarity between all of the detail controllers that there should be a super-class.
 For now, this makes it easier to launch the appropriate type of detail window.
 */
@implementation METDetailWindowController

+ (id)displayDetailsOfType:(CCPType*)type forCharacter:(Character*)ch
{
    if( [[type group] categoryID] == DB_CATEGORY_SHIP )
    {
        [ShipDetailsWindowController displayShip:type forCharacter:ch];
    }
    else if( ([[type group] categoryID] == DB_CATEGORY_MODULE)
            || ([[type group] categoryID] == DB_CATEGORY_CHARGE)
            || ([[type group] categoryID] == DB_CATEGORY_SUBSYSTEM) )
    {
        [ModuleDetailsWindowController displayModule:type forCharacter:ch];
    }
    else if( [[type group] categoryID] == DB_CATEGORY_SKILL )
    {
        [SkillDetailsWindowController displayWindowForTypeID:[NSNumber numberWithInteger:[type typeID]] forCharacter:ch];
    }
    else
    {
        // Currently not handling:
        // Small Secure Container: 3467
        // Blueprint: 32867
        
        NSLog( @"Unable to handle detail view for type: %@", [type typeName] );
    }
    
    // TODO: Change this (and all of the display... methods, to return a pointer to the window controller
    return nil;
}


@end
