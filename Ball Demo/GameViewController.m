#import "GameViewController.h"
#import "Quaternion.h"
#import "Vector.h"

#define TABLE_WIDTH  3.5
#define TABLE_LENGTH 5.3
#define BALL_RADIUS  0.5

@implementation GameViewController {
    NSTimeInterval _lastUpdate;
    SCNNode *_ball;

    Quaternion quat;
    
    struct {
        float x,y,z;
        float dx,dy,dz;
    } ballPosVel;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // create a new scene
    SCNScene *scene = [SCNScene sceneNamed:@"art.scnassets/table.scn"];

    // create and add a camera to the scene
    SCNNode *cameraNode = [SCNNode node];
    cameraNode.camera = [SCNCamera camera];
    [scene.rootNode addChildNode:cameraNode];
    
    // place the camera
    SCNNode *centerNode = [SCNNode node];
    [scene.rootNode addChildNode:centerNode];

    SCNLookAtConstraint *lookAt = [SCNLookAtConstraint lookAtConstraintWithTarget:centerNode];
    
    cameraNode.position = SCNVector3Make(0, 8, 12);
    cameraNode.constraints = @[ lookAt ];
    
    // create and add a light to the scene
    SCNNode *lightNode = [SCNNode node];
    lightNode.light = [SCNLight light];
    lightNode.light.type = SCNLightTypeOmni;
    lightNode.position = SCNVector3Make(0, 10, 10);
    [scene.rootNode addChildNode:lightNode];
    
    // create and add an ambient light to the scene
    SCNNode *ambientLightNode = [SCNNode node];
    ambientLightNode.light = [SCNLight light];
    ambientLightNode.light.type = SCNLightTypeAmbient;
    ambientLightNode.light.color = [UIColor darkGrayColor];
    [scene.rootNode addChildNode:ambientLightNode];
    
    // retrieve the ball node
    _ball = [scene.rootNode childNodeWithName:@"ball" recursively:YES];
    
    // retrieve the SCNView
    SCNView *scnView = (SCNView *)self.view;
    
    // set the scene to the view
    scnView.scene = scene;
    
    // configure the view
    scnView.backgroundColor = [UIColor blackColor];

    scnView.delegate = self;
    scnView.playing = YES;
    
    Quaternion_loadIdentity(&quat);
    
    ballPosVel.x = 0;
    ballPosVel.y = 0;
    ballPosVel.z = 0;
    ballPosVel.dx = 0.02;
    ballPosVel.dy = 0.0;
    ballPosVel.dz = 0.025;

#if 1
    // allows the user to manipulate the camera
    scnView.allowsCameraControl = YES;
        
    // show statistics such as fps and timing information
    scnView.showsStatistics = YES;
#endif
}

- (void)renderer:(id<SCNSceneRenderer>)renderer updateAtTime:(NSTimeInterval)time
{
    // Add the movement (velocity)
    ballPosVel.x += ballPosVel.dx;
    ballPosVel.y += ballPosVel.dy;
    ballPosVel.z += ballPosVel.dz;
    
    // Bounce at the walls
    if (ballPosVel.x > TABLE_WIDTH-BALL_RADIUS) {
        ballPosVel.x = 2.0*(TABLE_WIDTH-BALL_RADIUS) - ballPosVel.x;
        ballPosVel.dx = -ballPosVel.dx;
    }
    if (ballPosVel.x < -(TABLE_WIDTH-BALL_RADIUS)) {
        ballPosVel.x = -2.0*(TABLE_WIDTH-BALL_RADIUS) - ballPosVel.x;
        ballPosVel.dx = -ballPosVel.dx;
    }
    if (ballPosVel.z > TABLE_LENGTH-BALL_RADIUS) {
        ballPosVel.z = 2.0*(TABLE_LENGTH-BALL_RADIUS) - ballPosVel.z;
        ballPosVel.dz = -ballPosVel.dz;
    }
    if (ballPosVel.z < -(TABLE_LENGTH-BALL_RADIUS)) {
        ballPosVel.z = -2.0*(TABLE_LENGTH-BALL_RADIUS) - ballPosVel.z;
        ballPosVel.dz = -ballPosVel.dz;
    }
    
    // Calculate rotation direction and angle
    Vector axis;
    float angle;
    
    axis.x = ballPosVel.dz;
    axis.y = 0.0;
    axis.z = -ballPosVel.dx;

    // Formula is angle = 2*pi*dist/(2*pi*r) which is reduced to below calculation
    angle = sqrt(ballPosVel.dx*ballPosVel.dx+ballPosVel.dz*ballPosVel.dz)/BALL_RADIUS;
    
    // Apply to rotation Quaternion (globally)
    Quaternion tmpQ;
    tmpQ = Quaternion_fromAxisAngle(axis, angle);
    quat = Quaternion_multiplied(tmpQ, quat);
    
    // Get the rotation in a usable format for SceneKit
    Quaternion_toAxisAngle(quat, &axis, &angle);
    
    _ball.position = SCNVector3Make(ballPosVel.x, ballPosVel.y, ballPosVel.z);
    _ball.rotation = SCNVector4Make(axis.x, axis.y, axis.z, angle);
    
    _lastUpdate = time;
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return UIInterfaceOrientationMaskAllButUpsideDown;
    } else {
        return UIInterfaceOrientationMaskAll;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
