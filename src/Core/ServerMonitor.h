/*
 This file is part of Mac Eve Tools.
 
 Mac Eve Tools is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 Mac Eve Tools is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with Mac Eve Tools.  If not, see <http://www.gnu.org/licenses/>.
 
 Copyright Matt Tyson, 2009.
 */

#import <Cocoa/Cocoa.h>

#import "macros.h"

/**
 `ServerMonitor` is used to query the operating status and number of players logged in
 to the EVE Online server.
 
 When monitoring is started, `ServerMonitor` periodically polls the server and posts a
 notification to the default `NSNotificationCenter` after each poll.
 */

@interface ServerMonitor : NSObject {
	enum ServerStatus status;
	NSInteger numPlayers;
	
	NSMutableData *xmlData;
	NSTimer *timer;
}

@property (nonatomic,readonly) enum ServerStatus status;
@property (nonatomic,readonly) NSInteger numPlayers;

/**
 Poll the server. The results will become available in this object's properties once the
 poll returns; callers must subscribe to SERVER_STATUS_NOTIFICATION notifications to
 be informed of this function's completion.
 */
-(void) checkServerStatus;

/**
 Start monitoring the server's status. When monitoring, the server will be polled
 every 300 seconds.
 
 To retrieve the results of the poll, callers should subscribe to
 SERVER_STATUS_NOTIFICATION notifications and check this object's properties
 once that notification is received.
 */
-(void) startMonitoring;

/**
 Stop monitoring the server's status.
 */
-(void) stopMonitoring;

@end
