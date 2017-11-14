/* 
 * Copyright (c) 2009 Keith Lazuka
 * License: http://www.opensource.org/licenses/mit-license.html
 */

#import <CoreGraphics/CoreGraphics.h>
#import "KalMonthView.h"
#import "KalTileView.h"
#import "KalView.h"
#import "KalDate.h"
#import "KalPrivate.h"

@interface KalMonthView ()
@property(nonatomic,assign) CGSize tileSize;
@end

@implementation KalMonthView

@synthesize numWeeks;

- (instancetype)initWithFrame:(CGRect)frame tileSize:(CGSize)tileSize
{
  if ((self = [super initWithFrame:frame])) {
    tileAccessibilityFormatter = [[NSDateFormatter alloc] init];
    [tileAccessibilityFormatter setDateFormat:@"EEEE, MMMM d"];
    self.opaque = NO;
    self.clipsToBounds = YES;
    self.tileSize = tileSize;
    for (int i=0; i<6; i++) {
      for (int j=0; j<7; j++) {
        CGRect r = CGRectMake(j*tileSize.width, i*tileSize.height, tileSize.width, tileSize.height);
        [self addSubview:[[[KalTileView alloc] initWithFrame:r] autorelease]];
      }
    }
  }
  return self;
}

- (void)showDates:(NSArray *)mainDates leadingAdjacentDates:(NSArray *)leadingAdjacentDates trailingAdjacentDates:(NSArray *)trailingAdjacentDates
{
  int tileNum = 0;
  NSArray *dates[] = { leadingAdjacentDates, mainDates, trailingAdjacentDates };
  
  for (int i=0; i<3; i++) {
    for (KalDate *d in dates[i]) {
      KalTileView *tile = [self.subviews objectAtIndex:tileNum];
      [tile resetState];
      tile.date = d;
      tile.type = dates[i] != mainDates
                    ? KalTileTypeAdjacent
                    : [d isToday] ? KalTileTypeToday : KalTileTypeRegular;
      tile.hidden = NO;
      tileNum++;
    }
  }
  // hide remaining tiles if exist
  for (int i = tileNum; i < self.subviews.count; i++) {
    KalTileView *tile = [self.subviews objectAtIndex:i];
    tile.hidden = YES;
  }
  
  numWeeks = ceilf(tileNum / 7.f);
  [self sizeToFit];
  [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
  CGContextRef ctx = UIGraphicsGetCurrentContext();
  CGContextDrawTiledImage(ctx, (CGRect){CGPointZero,self.tileSize}, [[UIImage kal_imageNamed:@"kal_tile.png"] CGImage]);
}

- (KalTileView *)firstTileOfMonth
{
  KalTileView *tile = nil;
  for (KalTileView *t in self.subviews) {
    if (!t.belongsToAdjacentMonth) {
      tile = t;
      break;
    }
  }
  
  return tile;
}

- (KalTileView *)tileForDate:(KalDate *)date
{
  KalTileView *tile = nil;
  for (KalTileView *t in self.subviews) {
    if ([t.date isEqual:date]) {
      tile = t;
      break;
    }
  }
  NSAssert1(tile != nil, @"Failed to find corresponding tile for date %@", date);
  
  return tile;
}

- (void)sizeToFit
{
  self.height = 1.f + self.tileSize.height * numWeeks;
}

- (void)markTilesForDates:(NSSet *)dates specialDates:(NSSet *)specialDates
{
  for (KalTileView *tile in self.subviews)
  {
    NSDate *tileDate = [tile.date NSDate];
    tile.marked = [dates containsObject:tileDate];
    tile.speciallyMarked = [specialDates containsObject:tileDate];
    NSString *dayString = [tileAccessibilityFormatter stringFromDate:tileDate];
    if (dayString) {
      NSMutableString *helperText = [[[NSMutableString alloc] initWithCapacity:128] autorelease];
      if ([tile.date isToday])
        [helperText appendFormat:@"%@ ", NSLocalizedString(@"Today", @"Accessibility text for a day tile that represents today")];
      [helperText appendString:dayString];
      if (tile.marked)
        [helperText appendFormat:@". %@", NSLocalizedString(@"Marked", @"Accessibility text for a day tile which is marked with a small dot")];
      [tile setAccessibilityLabel:helperText];
    }
  }
}

#pragma mark -

- (void)dealloc
{
  [tileAccessibilityFormatter release];
  [super dealloc];
}

@end
