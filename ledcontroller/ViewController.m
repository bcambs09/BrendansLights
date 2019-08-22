//
//  ViewController.m
//  ledcontroller
//
//  Created by Brendan Campbell on 12/21/18.
//  Copyright © 2018 Wolverine Games LLC. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    lightsOn = false;
    [self connectToServer];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void) sendMessage: (const char*)str {
    
    NSString *response  = [NSString stringWithUTF8String:str];
    NSData *data = [[NSData alloc] initWithData:[response dataUsingEncoding:NSASCIIStringEncoding]];
    [outputStream write:[data bytes] maxLength:[data length]];
}

- (void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)streamEvent {
    
    NSLog(@"stream event %lu", streamEvent);
    
    switch (streamEvent) {
            
        case NSStreamEventOpenCompleted:
            NSLog(@"Stream opened");
            [_errorLabel setHidden:FALSE];
            [_errorLabel setTextColor:[UIColor colorWithRed:76.0/255 green:202.0/255 blue:50.0/255 alpha:1.0]];
            [_errorLabel setText:@"Connected"];
            break;
        case NSStreamEventHasBytesAvailable:
            
            if (theStream == inputStream)
            {
                uint8_t buffer[1024];
                NSInteger len;
                
                while ([inputStream hasBytesAvailable])
                {
                    len = [inputStream read:buffer maxLength:sizeof(buffer)];
                    if (len > 0)
                    {
                        NSString *output = [[NSString alloc] initWithBytes:buffer length:len encoding:NSASCIIStringEncoding];
                        
                        if (nil != output)
                        {
                            NSLog(@"server said: %@", output);
                        }
                    }
                }
            }
            break;
            
        case NSStreamEventHasSpaceAvailable:
            NSLog(@"Stream has space available now");
            break;
            
        case NSStreamEventErrorOccurred:
            NSLog(@"%@",[theStream streamError].localizedDescription);
            [_errorLabel setHidden:FALSE];
            [_errorLabel setTextColor:[UIColor colorWithRed:172.0/255 green:38.0/255 blue:2.0/255 alpha:1.0]];
            [_errorLabel setText:[theStream streamError].localizedDescription];
            break;
            
        case NSStreamEventEndEncountered:
            
            [theStream close];
            [theStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
            NSLog(@"close stream");
            break;
        default:
            NSLog(@"Unknown event");
    }
    
}

- (void)connectToServer {
    
    NSLog(@"Setting up connection to %s : %i", "localhost", 7500);
    CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault, (__bridge CFStringRef) [NSString stringWithUTF8String:"localhost"], 7500, &readStream, &writeStream);

    [self open];
}

- (void)disconnect {
    [self close];
}

- (void)open {
    
    NSLog(@"Opening streams.");
    
    outputStream = (__bridge NSOutputStream *)writeStream;
    inputStream = (__bridge NSInputStream *)readStream;
    
    [outputStream setDelegate:self];
    [inputStream setDelegate:self];
    
    [outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
    [outputStream open];
    [inputStream open];
}

- (void)close {
    NSLog(@"Closing streams.");
    [inputStream close];
    [outputStream close];
    [inputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [outputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [inputStream setDelegate:nil];
    [outputStream setDelegate:nil];
    inputStream = nil;
    outputStream = nil;
}

- (IBAction)toggleLights {
    if(lightsOn){
        lightsOn = false;
        [_toggle setImage:[UIImage imageNamed:@"redButtonUnpressed.png"] forState:UIControlStateNormal];
        [_toggle setImage:[UIImage imageNamed:@"redButtonPressed.png"] forState:UIControlStateHighlighted];
        _redSlider.value = 0;
        _redLabel.text = @"0";
        _greenSlider.value = 0;
        _greenLabel.text = @"0";
        _blueSlider.value = 0;
        _blueLabel.text = @"0";
        _colorBox.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:1.0];
        [self sendMessage:"w 0 0 0\n"];
    }else{
        lightsOn = true;
        [_toggle setImage:[UIImage imageNamed:@"greenButtonUnpressed.png"] forState:UIControlStateNormal];
        [_toggle setImage:[UIImage imageNamed:@"greenButtonPressed.png"] forState:UIControlStateHighlighted];
        _redSlider.value = 255;
        _redLabel.text = @"255";
        _greenSlider.value = 255;
        _greenLabel.text = @"255";
        _blueSlider.value = 255;
        _blueLabel.text = @"255";
        _colorBox.backgroundColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0];
        [self sendMessage:"w 255 255 255\n"];
    }
}

- (IBAction)colorChanged{
    float red = self.redSlider.value;
    float green = self.greenSlider.value;
    float blue = self.blueSlider.value;
    if(!lightsOn && (red || green || blue)){
        lightsOn = true;
        [_toggle setImage:[UIImage imageNamed:@"greenButtonUnpressed.png"] forState:UIControlStateNormal];
        [_toggle setImage:[UIImage imageNamed:@"greenButtonPressed.png"] forState:UIControlStateHighlighted];
    }else if(lightsOn && (!red && !green && !blue)){
        lightsOn = false;
        [_toggle setImage:[UIImage imageNamed:@"redButtonUnpressed.png"] forState:UIControlStateNormal];
        [_toggle setImage:[UIImage imageNamed:@"redButtonPressed.png"] forState:UIControlStateHighlighted];
    }
    _redLabel.text = [NSString stringWithFormat:@"%i", (int) red];
    _greenLabel.text = [NSString stringWithFormat:@"%i", (int) green];
    _blueLabel.text = [NSString stringWithFormat:@"%i", (int) blue];
    NSString* str = [NSString stringWithFormat:@"w %i %i %i\n",
                     (int)red, (int)green, (int)blue];
    _colorBox.backgroundColor = [UIColor colorWithRed:red/255.0 green:green/255.0 blue:blue/255.0 alpha:1.0];
    [self sendMessage:[str UTF8String]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
