#import <Cocoa/Cocoa.h>

#import "MTEveSkillQueueHeader.h"

#import "MTCountdown.h"
#import "MTImageView.h"

@class Character;
@class Skill;
@class SkillQueueDatasource;
@class MainController;

@interface StatusItemViewController : NSViewController {
    IBOutlet MTImageView *characterPortrait;
    
    IBOutlet NSTextField *characterName;
    IBOutlet NSTextField *characterBalance;
    
    IBOutlet NSTextField *skillTraining;

    IBOutlet MTEveSkillQueueHeader *skillQueueHeader;
    
    Character *currentCharacter;
    Skill *currentTrainingSkill;
    
    @private
    MainController *_mainController;
}

-(Character*) getCharacter;
-(void) setCharacter: (Character*) character;

-(void) attachMainController: (MainController*) mainController;

- (IBAction) openApplicationClicked: (id) sender;

@end
