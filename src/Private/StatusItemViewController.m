#import "StatusItemViewController.h"

#import "GlobalData.h"
#import "Character.h"
#import "Helpers.h"
#import "SkillPlan.h"

#import "MainController.h"

@interface StatusItemViewController ()

@end

@implementation StatusItemViewController

-(void) awakeFromNib {
	NSNumberFormatter *iskFormatter = [[NSNumberFormatter alloc] init];
	[iskFormatter setFormatterBehavior: NSNumberFormatterBehavior10_4];
	[iskFormatter setDecimalSeparator: @"."];
	[iskFormatter setMinimumFractionDigits: 2];
	[iskFormatter setGeneratesDecimalNumbers: YES];
	[iskFormatter setNumberStyle: NSNumberFormatterDecimalStyle];
	[iskFormatter setPositiveSuffix: @" ISK"];
	[iskFormatter setNegativeSuffix: @" ISK"];
	[characterBalance setFormatter: iskFormatter];
	[iskFormatter release];
    
    [skillQueueHeader setWarn:NO];

    [self clearCharacter];
    [self updateCharacterDetails];
}

- (Character*) getCharacter
{
	return currentCharacter;
}

- (void) setCharacter: (Character*) character;
{
	if(character == nil || currentCharacter == character) {
		return;
	}
	
	if(currentCharacter != nil) {
		[currentCharacter release];
	}
	
	[self clearCharacter];

	currentCharacter = [character retain];
	    
	[self updateCharacterDetails];
}

- (void) attachMainController: (MainController*) mainController {
    _mainController = mainController;
}

- (void) clearCharacter {
    [characterPortrait setObjectValue: nil];
    [characterName setObjectValue: nil];
    [characterBalance setObjectValue: nil];
    
    [skillTraining setObjectValue: nil];
    
	[skillQueueHeader setSkillPlan: nil];
	[skillQueueHeader setCharacter: nil];
	[skillQueueHeader setNeedsDisplay: YES];
}

- (IBAction) openApplicationClicked: (id) sender {
    [_mainController showWindow: nil];
}

- (void) updateCharacterDetails {
    [characterPortrait setImage: [currentCharacter portrait]];
    
    [characterName setStringValue: [currentCharacter stringForKey: CHAR_NAME]];
    [characterName sizeToFit];
    
    [characterBalance setObjectValue: [NSDecimalNumber decimalNumberWithString: [currentCharacter stringForKey: CHAR_BALANCE]]];
    [characterBalance sizeToFit];
    
    NSInteger isTraining = [currentCharacter integerForKey:CHAR_TRAINING_SKILLTRAINING];
    
    if (isTraining == 0) {
        [skillTraining setStringValue: @"Not Training"];
        [skillTraining sizeToFit];
        
        [skillQueueHeader setSkillPlan: nil];
        [skillQueueHeader setCharacter: nil];
        [skillQueueHeader setNeedsDisplay: YES];
        [skillQueueHeader setHidden: YES];
    } else {
		NSNumber *skillTrainingId = [NSNumber numberWithInteger: [[currentCharacter stringForKey: CHAR_TRAINING_TYPEID] integerValue]];
		Skill *skill = [[[GlobalData sharedInstance] skillTree] skillForId: skillTrainingId];
        
        NSString *trainingText = [NSString stringWithFormat:@"%@ %@", [skill skillName], romanForString([currentCharacter stringForKey: CHAR_TRAINING_LEVEL])];
        
        [skillTraining setStringValue: trainingText];
        [skillTraining sizeToFit];
        
        SkillPlan* trainingQueue = [currentCharacter trainingQueue];
        
        [skillQueueHeader setCharacter: currentCharacter];
        [skillQueueHeader setSkillPlan: trainingQueue];
        [skillQueueHeader setTimeRemaining: [trainingQueue trainingTimeOfSkillAtIndex: 0 fromDate: [NSDate date]]];
        [skillQueueHeader setNeedsDisplay: YES];
        [skillQueueHeader setHidden: NO];
    }
    
    [[self view] invalidateIntrinsicContentSize];
}

@end
