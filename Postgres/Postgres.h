//
//  Postgres.h
//  Postgres
//
//  Created by John Wang on 3/25/11.
//  Copyright 2011 Fresh Blocks LLC. All rights reserved.
//

#import <PreferencePanes/PreferencePanes.h>
#import <AppKit/AppKit.h>

@interface Postgres : NSPreferencePane {
@private
    NSString *_path;
    NSButton *_startButton;
    NSTextField *_statusLabel;
    NSButton *_autoStartCheckBox;
    NSTextField *_detailInformationText;
    NSProgressIndicator *_progressIndicator;
    
    NSString *_serverLog;
    NSString *_postgres;
    NSString *_pgctl;
    NSTextField *_startedSubtext;
    NSImageView *_statusImage;
    
    BOOL _isRunning;
    
}
@property(nonatomic, retain) NSString *path;
@property (assign) IBOutlet NSButton *startButton;
@property (assign) IBOutlet NSTextField *statusLabel;
@property (assign) IBOutlet NSButton *autoStartCheckBox;
@property (assign) IBOutlet NSTextField *detailInformationText;
@property (assign) IBOutlet NSProgressIndicator *progressIndicator;
@property (nonatomic, retain) NSString *serverLog;
@property (nonatomic, retain) NSString *postgres;
@property (nonatomic, retain) NSString *pgctl;
@property (assign) IBOutlet NSTextField *startedSubtext;
@property (assign) IBOutlet NSImageView *statusImage;

- (void)mainViewDidLoad;
- (IBAction)startStopServer:(id)sender;
- (IBAction)autoStartChanged:(id)sender;

@end
