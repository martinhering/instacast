//
//  PopoverSlidesViewController.m
//  Instacast
//
//  Created by Martin Hering on 29.08.12.
//
//

#import "PopoverSlidesViewController.h"
#import "PopoverSlidesCollectionViewLayout.h"
#import "PopoverSlidesCollectionViewCell.h"

static NSString* reuseIdentifier = @"PopoverSlidesCell";

@interface PopoverSlidesViewController ()
@property (nonatomic, strong) UITapGestureRecognizer* tapRecognizer;
@end

@implementation PopoverSlidesViewController

+ (id) viewController
{
    PopoverSlidesCollectionViewLayout* flowLayout = [[PopoverSlidesCollectionViewLayout alloc] init];
    flowLayout.itemSize = CGSizeMake(500, 500);
    flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    flowLayout.minimumLineSpacing = 80;
    flowLayout.minimumInteritemSpacing = 200;
    return [[PopoverSlidesViewController alloc] initWithCollectionViewLayout:flowLayout];
}

- (id)initWithCollectionViewLayout:(UICollectionViewLayout *)layout
{
    self = [super initWithCollectionViewLayout:layout];
    if (self) {
        // Custom initialization
        [self.collectionView registerClass:[PopoverSlidesCollectionViewCell class] forCellWithReuseIdentifier:reuseIdentifier];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.collectionView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.3];
    self.collectionView.scrollEnabled = NO;
    
    self.tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    [self.collectionView addGestureRecognizer:self.tapRecognizer];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
  
    self.tapRecognizer = nil;
}

#pragma mark -

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return 10;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell* cell = (UICollectionViewCell*)[collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    
    cell.backgroundColor = (indexPath.row % 2 == 0) ? [UIColor redColor] : [UIColor blueColor];
    
    return cell;
}

- (void) handleTap:(UITapGestureRecognizer*)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateRecognized)
    {
        CGPoint location = [recognizer locationInView:self.collectionView];
        NSIndexPath* cellPath = [self.collectionView indexPathForItemAtPoint:location];
        
        if (cellPath)
        {
            PopoverSlidesCollectionViewLayout* layout = (PopoverSlidesCollectionViewLayout*)self.collectionView.collectionViewLayout;
            layout.scrolledIndexPath = cellPath;
            [self.collectionView scrollToItemAtIndexPath:cellPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
        }
        DebugLog(@"%@", cellPath);
    }
}
@end
