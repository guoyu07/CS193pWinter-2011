//
//  KitchenSinkViewController.m
//  Kitchen Sink
//
//  Created by CS193p Instructor.
//  Copyright (c) 2011 Stanford University. All rights reserved.
//

#import "KitchenSinkViewController.h"
#import "AskerViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>

@interface KitchenSinkViewController() <AskerViewControllerDelegate, UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property (weak, nonatomic) IBOutlet UIView *kitchenSink;
@property (weak, nonatomic) NSTimer *drainTimer;
@property (weak, nonatomic) UIActionSheet *actionSheet;
@end

@implementation KitchenSinkViewController

@synthesize kitchenSink = _kitchenSink;
@synthesize drainTimer = _drainTimer;
@synthesize actionSheet = _actionSheet;

#pragma mark - Utility Methods

- (void)setRandomLocationForView:(UIView *)view
{
    CGRect sinkBounds = CGRectInset(self.kitchenSink.bounds, view.frame.size.width/2, view.frame.size.height/2);
    CGFloat x = arc4random() % (int)sinkBounds.size.width + view.frame.size.width/2;
    CGFloat y = arc4random() % (int)sinkBounds.size.height + view.frame.size.height/2;
    view.center = CGPointMake(x, y);
}

- (void)addLabel:(NSString *)text
{
    UILabel *label = [[UILabel alloc] init];
    static NSDictionary *colors = nil;
    if (!colors) colors = [NSDictionary dictionaryWithObjectsAndKeys:
                           [UIColor blueColor], @"Blue",
                           [UIColor greenColor], @"Green",
                           [UIColor orangeColor], @"Orange",
                           [UIColor redColor], @"Red",
                           [UIColor purpleColor], @"Purple",
                           [UIColor brownColor], @"Brown",
                           nil];
    if (![text length]) {
        NSString *color = [[colors allKeys] objectAtIndex:arc4random()%[colors count]];
        text = color;
        label.textColor = [colors objectForKey:color];
    }
    label.text = text;
    label.font = [UIFont systemFontOfSize:48.0];
    label.backgroundColor = [UIColor clearColor];
    [label sizeToFit];
    [self setRandomLocationForView:label];
    [self.kitchenSink addSubview:label];
}

#pragma mark - Modal View Controllers

// prepare for the modal view controller buttons in the toolbar 

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier hasPrefix:@"Create Label"]) {
        AskerViewController *asker = (AskerViewController *)segue.destinationViewController;
        asker.question = @"What do you want your label to say?";
        asker.answer = @"Label Text";
        asker.delegate = self;
    }
}

- (void)askerViewController:(AskerViewController *)sender didAskQuestion:(NSString *)question andGotAnswer:(NSString *)answer
{
    [self addLabel:answer];
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - View Animation

- (IBAction)tap:(UITapGestureRecognizer *)gesture
{
    CGPoint tapLocation = [gesture locationInView:self.kitchenSink];
    for (UIView *view in self.kitchenSink.subviews) {
        if (CGRectContainsPoint(view.frame, tapLocation)) {
            [UIView animateWithDuration:4.0 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                [self setRandomLocationForView:view];
                view.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.99, 0.99);
            } completion:^(BOOL finished) {
                view.transform = CGAffineTransformIdentity;
            }];
        }
    }
}

#define DRAIN_DURATION 3.0

- (void)drain
{
    for (UIView *view in self.kitchenSink.subviews) {
        CGAffineTransform transform = view.transform;
        if (CGAffineTransformIsIdentity(transform)) {
            UIViewAnimationOptions options = UIViewAnimationOptionCurveLinear;
            [UIView animateWithDuration:DRAIN_DURATION/3 delay:0 options:options animations:^{
                view.transform = CGAffineTransformRotate(CGAffineTransformScale(transform, 0.7, 0.7), 2*M_PI/3);
            } completion:^(BOOL finished) {
                if (finished) {
                    [UIView animateWithDuration:DRAIN_DURATION/3 delay:0 options:options animations:^{
                        view.transform = CGAffineTransformRotate(CGAffineTransformScale(transform, 0.4, 0.4), -2*M_PI/3);
                    } completion:^(BOOL finished) {
                        if (finished) {
                            [UIView animateWithDuration:DRAIN_DURATION/3 delay:0 options:options animations:^{
                                view.transform = CGAffineTransformScale(transform, 0.1, 0.1);
                            } completion:^(BOOL finished) {
                                if (finished) [view removeFromSuperview];
                            }];
                        }
                    }];
                }
            }];
        }
    }
}

- (void)drain:(NSTimer *)timer
{
    [self drain];
}

- (void)startDraining
{
    self.drainTimer = [NSTimer scheduledTimerWithTimeInterval:DRAIN_DURATION/3
                                                       target:self
                                                     selector:@selector(drain:)
                                                     userInfo:nil
                                                      repeats:YES];
}

- (void)stopDraining
{
    [self.drainTimer invalidate];
}

#define STOP_DRAIN @"Stopper Drain"
#define UNSTOP_DRAIN @"Unstopper Drain"

#pragma mark - Control Sink Action Sheet

- (IBAction)controlSink:(UIBarButtonItem *)sender
{
    if (self.actionSheet) {
        // do nothing
    } else {
        NSString *drainButton = self.drainTimer ? STOP_DRAIN : UNSTOP_DRAIN;
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Sink Controls" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Empty Sink" otherButtonTitles:drainButton, nil];
        [actionSheet showFromBarButtonItem:sender animated:YES];
        self.actionSheet = actionSheet;
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *choice = [actionSheet buttonTitleAtIndex:buttonIndex];
    if (buttonIndex == [actionSheet destructiveButtonIndex]) {
        [self.kitchenSink.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    } else if ([choice isEqualToString:STOP_DRAIN]) {
        [self stopDraining];
    } else if ([choice isEqualToString:UNSTOP_DRAIN]) {
        [self startDraining];
    }
}

#pragma mark - Dripping Faucet

#define FAUCET_INTERVAL 2.0

- (void)drip
{
    if (self.kitchenSink.window) {
        [self addLabel:nil];
        [self performSelector:@selector(drip) withObject:nil afterDelay:FAUCET_INTERVAL];
    }
}

#pragma mark - UIImagePickerController

- (IBAction)addImage:(UIBarButtonItem *)sender
{
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        NSArray *mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera];
        if ([mediaTypes containsObject:(NSString *)kUTTypeImage]) {
            UIImagePickerController *picker = [[UIImagePickerController alloc] init];
            picker.delegate = self;
            picker.sourceType = UIImagePickerControllerSourceTypeCamera;
            picker.mediaTypes = [NSArray arrayWithObject:(NSString *)kUTTypeImage];
            picker.allowsEditing = YES;
            [self presentModalViewController:picker animated:YES];
        }
    }
}

- (void)dismissImagePicker
{
    [self dismissModalViewControllerAnimated:YES];
}

#define MAX_IMAGE_WIDTH 200

- (void)imagePickerController:(UIImagePickerController *)picker
didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = [info objectForKey:UIImagePickerControllerEditedImage];
    if (!image) image = [info objectForKey:UIImagePickerControllerOriginalImage];
    if (image) {
        UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
        CGRect frame = imageView.frame;
        while (frame.size.width > MAX_IMAGE_WIDTH) {
            frame.size.width /= 2;
            frame.size.height /= 2;
        }
        imageView.frame = frame;
        [self setRandomLocationForView:imageView];
        [self.kitchenSink addSubview:imageView];
    }
    [self dismissImagePicker];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissImagePicker];
}

#pragma mark - View Controller Lifecycle

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self startDraining];
    [self drip];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self stopDraining];
    [super viewWillDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

@end
