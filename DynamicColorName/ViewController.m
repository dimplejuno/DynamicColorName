//
//  ViewController.m
//  DynamicColorName
//
//  Created by Steve Park on 2013. 7. 11..
//  Copyright (c) 2013년 Steve Park. All rights reserved.
//

#define CRAYON_NAME(CRAYON)	[[CRAYON componentsSeparatedByString:@"#"] objectAtIndex:0]
#define CRAYON_COLOR(CRAYON) [self colorFromHexString:[[CRAYON componentsSeparatedByString:@"#"] lastObject]]
#define BARBUTTON(TITLE, SELECTOR) 	[[UIBarButtonItem alloc] initWithTitle:TITLE style:UIBarButtonItemStylePlain target:self action:SELECTOR]

#import "ViewController.h"

@interface ViewController ()< UIDynamicAnimatorDelegate, UICollisionBehaviorDelegate >
{
    
    UIDynamicAnimator* animator;
    
    UIGravityBehavior* gravityBeahvior;
    UICollisionBehavior* collisionBehavior;
    UIAttachmentBehavior* attachmentBehavior;
    UIPushBehavior* pushBehavior;
    UISnapBehavior* snapBehavior;
    UIDynamicItemBehavior* propertiesBehavior;
    
    
    NSArray *rawColors;
    NSMutableArray *letters;
    NSMutableArray *letterPositions;
    UIColor *selectedColor;
    NSString *selectedColorName;
    NSMutableString *answerString;
    
    NSInteger selectedIndex;
    
    UISlider *pageSlider;
    NSTimer *hiderTimer;
}

@end

@implementation ViewController

- (void)reset {
    for(UIView *v in letters) {
        [v removeFromSuperview];
    }
    
    [letters removeAllObjects];
    
    [self makeCharArrayOfWord];
    [self applyDynamics];
    
    selectedIndex = 0;
    [answerString setString:@""];
}

- (void) rightAction: (id) sender
{
    [self reset];
    self.navigationItem.rightBarButtonItem.enabled = NO;

}


- (UIColor *) colorFromHexString: (NSString *) hexColor
{
	unsigned int red, green, blue;
    
	NSRange range = NSMakeRange(0, 2);
	[[NSScanner scannerWithString:[hexColor substringWithRange:range]] scanHexInt:&red];
	range.location += 2;
	[[NSScanner scannerWithString:[hexColor substringWithRange:range]] scanHexInt:&green];
	range.location += 2;
	[[NSScanner scannerWithString:[hexColor substringWithRange:range]] scanHexInt:&blue];
	
	return [UIColor colorWithRed:(float)(red/255.0f)
                           green:(float)(green/255.0f)
                            blue:(float)(blue/255.0f)
                           alpha:1.0f];
}

-(void)loadView {
    [super loadView];
    
    // Load colors and create first view controller
    NSString *pathname = [[NSBundle mainBundle]  pathForResource:@"crayons" ofType:@"txt" inDirectory:@"/"];
	rawColors = [[NSString stringWithContentsOfFile:pathname encoding:NSUTF8StringEncoding error:nil]
                 componentsSeparatedByString:@"\n"];
    
    letters = [[NSMutableArray alloc] init];
    letterPositions = [[NSMutableArray alloc]init];
    
    self.navigationItem.rightBarButtonItem = BARBUTTON(@"New", @selector (rightAction:));

    
    self.navigationItem.rightBarButtonItem.enabled = NO;
    answerString = [[NSMutableString alloc] init];
    selectedIndex = 0;
    
}



- (void)applyDynamicToView:(UIView *)view {
    
    animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
    
    /*
     We want to show collisions between views and boundaries with different elasticities, we thus associate the two views to gravity and collision behaviors. We will only change the restitution parameter for one of these views.
     */
    // 중력을 적용...
    gravityBeahvior = [[UIGravityBehavior alloc] initWithItems:@[view]];
    
    // 충돌 속성을 적용...
    collisionBehavior = [[UICollisionBehavior alloc] initWithItems:@[view]];
    collisionBehavior.translatesReferenceBoundsIntoBoundary = YES;
    
    /*
     A dynamic item behavior gives access to low-level properties of an item in Dynamics, here we change restitution on collisions only for square2, and keep square1 with its default value.
     */
    propertiesBehavior = [[UIDynamicItemBehavior alloc] initWithItems:@[view]];
    // 탄성...
    propertiesBehavior.elasticity = 0.6;
    
    [animator addBehavior:propertiesBehavior];
    [animator addBehavior:gravityBeahvior];
    [animator addBehavior:collisionBehavior];
    
    
}




-(void)handleTapGesture:(UITapGestureRecognizer*)gesture
{
    UIView *touchedView = gesture.view;
    
    if(touchedView.center.y < 160) {
        NSRange range = {.location = selectedIndex-1, .length = 1};
        [answerString replaceCharactersInRange:range withString:@""];
        selectedIndex--;
        [self applyDynamicToView:touchedView];
        
        return;
    }
    
    
    [animator removeAllBehaviors];
    
    CGPoint point = [[letterPositions objectAtIndex:selectedIndex] CGPointValue];
    

    snapBehavior = [[UISnapBehavior alloc] initWithItem:touchedView snapToPoint:point];
    snapBehavior.damping = 0.5f;
    
    [animator addBehavior:snapBehavior];
    UILabel *label = (UILabel*)[touchedView viewWithTag:100];
    [answerString appendString:label.text];
    
    selectedIndex++;
    
    if(selectedIndex == selectedColorName.length) {
        NSLog(@"Check!!");
        if([selectedColorName isEqualToString:answerString]) {
            NSLog(@"Correct!!");
            
            UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"Dynamic Color" message:@"Correct!!" delegate:self cancelButtonTitle:@"New" otherButtonTitles:@"Cancel", nil];
            [alert show];
        } else {
            NSLog(@"Wrong!!");
            UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"Dynamic Color" message:@"Wrong!!" delegate:self cancelButtonTitle:@"New" otherButtonTitles:@"Cancel", nil];
            [alert show];
        }
        
    }
    
}

//경고창의 버튼 이벤트를 감지하는 델리게이트.
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    //경고창의 타이틀을 비교해서 경고창을 구별한다.
    if ( [[alertView title] isEqualToString:@"Dynamic Color"])
	{
        if(buttonIndex == 0){
            
            [self reset];
            
        } else {
			
            self.navigationItem.rightBarButtonItem.enabled = YES;
        }
        
	}
	
}

- (void)makeCharArrayOfWord {
    
    NSInteger randWord = arc4random()%[rawColors count];
    NSString *word = [rawColors objectAtIndex:randWord];
    
    selectedColor = [self colorFromHexString:[[word componentsSeparatedByString:@"#"] lastObject]];
    
    selectedColorName = [[word componentsSeparatedByString:@" #"] objectAtIndex:0];
    
    NSInteger deltaX = ((int)self.view.frame.size.height) / (selectedColorName.length + 1);
    
    for(int i=0; i<selectedColorName.length; i++) {
        
        NSRange range = {i,1};
        range.location = i;
        range.length = 1;
        
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(arc4random()%(int)(self.view.frame.size.width - 60) + 30 + arc4random()%30, 60, 30, 30)];
        view.backgroundColor = selectedColor;
        
        // 이미지를 원형으로...
        view.layer.borderWidth = 1;
        view.layer.borderColor = [UIColor blackColor].CGColor;
        view.layer.cornerRadius = CGRectGetHeight(view.bounds) / 2;
        view.clipsToBounds = YES;
        
        
        UILabel *label = [[UILabel alloc]initWithFrame:view.bounds];
        label.backgroundColor = [UIColor clearColor];
        label.text = [selectedColorName substringWithRange:range];
        label.font = [UIFont fontWithName:@"Avenir-Black" size:20.0f];
        label.textColor = [UIColor whiteColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.tag = 100;
        
        [view addSubview:label];
        
        // 탭 제스쳐 처리...
        UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
        view.gestureRecognizers = @[tapRecognizer];

        
        
        [self.view addSubview:view];

        
        NSLog(@"%@", [selectedColorName substringWithRange:range] );
        [letters addObject:view];
        
        [letterPositions addObject:[NSValue valueWithCGPoint:CGPointMake(deltaX + deltaX*i, 100)]];
    }
}


- (void)applyDynamics {
    
    animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
    
    /*
     We want to show collisions between views and boundaries with different elasticities, we thus associate the two views to gravity and collision behaviors. We will only change the restitution parameter for one of these views.
     */
    // 중력을 적용...
    gravityBeahvior = [[UIGravityBehavior alloc] initWithItems:letters];
    
    // 충돌 속성을 적용...
    collisionBehavior = [[UICollisionBehavior alloc] initWithItems:letters];
    collisionBehavior.translatesReferenceBoundsIntoBoundary = YES;
    
    /*
     A dynamic item behavior gives access to low-level properties of an item in Dynamics, here we change restitution on collisions only for square2, and keep square1 with its default value.
     */
    propertiesBehavior = [[UIDynamicItemBehavior alloc] initWithItems:letters];
    // 탄성...
    propertiesBehavior.elasticity = 0.6;
    
    // 푸쉬 속성...모드는 한번만? 계속? 두가지로 나뉨...
    pushBehavior = [[UIPushBehavior alloc] initWithItems:letters mode:UIPushBehaviorModeInstantaneous];
    
    // 각도와 크기...힘이니 벡터값으로...앵글, 즉 각도는 라디안값...
    pushBehavior.angle = 0.0;
    pushBehavior.magnitude = 0.0;
    
    
    [animator addBehavior:pushBehavior];
    [animator addBehavior:propertiesBehavior];
    [animator addBehavior:gravityBeahvior];
    [animator addBehavior:collisionBehavior];
    

}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [self makeCharArrayOfWord];
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self applyDynamics];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
