/* 
 * Copyright (c) 2009 Keith Lazuka
 * License: http://www.opensource.org/licenses/mit-license.html
 */

#import "KalTileView.h"
#import "KalDate.h"
#import "KalPrivate.h"

extern const CGSize kTileSize;

@implementation KalTileView

@synthesize date;

- (id)initWithFrame:(CGRect)frame
{
  if ((self = [super initWithFrame:frame])) {
    self.opaque = NO;
    self.backgroundColor = [UIColor clearColor];
    self.clipsToBounds = NO;
    origin = frame.origin;
    [self setIsAccessibilityElement:YES];
    [self setAccessibilityTraits:UIAccessibilityTraitButton];
    [self resetState];
  }
  return self;
}

- (void)drawRect:(CGRect)rect
{
  CGContextRef ctx = UIGraphicsGetCurrentContext();
  CGFloat fontSize = 21.f;
  UIFont *font = [UIFont fontWithName:@"SourceSansPro-Semibold" size:fontSize];
  UIColor *textColor = nil;
  UIImage *markerImage = nil;
  UIImage *specialMarkerImage = nil;
  CGContextSelectFont(ctx, [font.fontName cStringUsingEncoding:NSUTF8StringEncoding], fontSize, kCGEncodingMacRoman);
      
  CGContextTranslateCTM(ctx, 0, kTileSize.height);
  CGContextScaleCTM(ctx, 1, -1);

  if ([self isToday] && self.selected) {
    [self drawBackgroundImage:[[UIImage imageNamed:@"Kal.bundle/kal_tile_today_selected.png"] stretchableImageWithLeftCapWidth:2 topCapHeight:2]];
    textColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"Kal.bundle/kal_tile_text_fill.png"]];
    markerImage = [UIImage imageNamed:@"Kal.bundle/kal_marker_today.png"];
    specialMarkerImage = [UIImage imageNamed:@"Kal.bundle/pink_kal_marker_today.png"];
  } else if ([self isToday] && !self.selected) {
    [self drawBackgroundImage:[[UIImage imageNamed:@"Kal.bundle/kal_tile_today.png"] stretchableImageWithLeftCapWidth:2 topCapHeight:2]];
    textColor = [UIColor colorWithRed:0.271 green:0.655 blue:0.616 alpha:1];
    markerImage = [UIImage imageNamed:@"Kal.bundle/kal_marker_today.png"];
    specialMarkerImage = [UIImage imageNamed:@"Kal.bundle/pink_kal_marker_today.png"];
  } else if (self.selected) {
    [self drawBackgroundImage:[[UIImage imageNamed:@"Kal.bundle/kal_tile_selected.png"] stretchableImageWithLeftCapWidth:2 topCapHeight:2]];
    textColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"Kal.bundle/kal_tile_text_fill.png"]];
    markerImage = [UIImage imageNamed:@"Kal.bundle/kal_marker_selected.png"];
    specialMarkerImage = [UIImage imageNamed:@"Kal.bundle/pink_kal_marker_selected.png"];
  } else if (self.belongsToAdjacentMonth) {
    textColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"Kal.bundle/kal_tile_dim_text_fill.png"]];
    markerImage = [UIImage imageNamed:@"Kal.bundle/kal_marker_dim.png"];
    specialMarkerImage = [UIImage imageNamed:@"Kal.bundle/pink_kal_marker_dim.png"];
  } else {
    textColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"Kal.bundle/kal_tile_text_fill.png"]];
    markerImage = [UIImage imageNamed:@"Kal.bundle/kal_marker.png"];
    specialMarkerImage = [UIImage imageNamed:@"Kal.bundle/pink_kal_marker.png"];
  }

  // We need to offset tile content to compensate for the workaround used in setSelected: (see below)
  BOOL horizontalOffset = 1.0f;
  if (![self isToday] && !self.selected) {
    horizontalOffset = 0.0f;
  }

  if (flags.marked) {
    if (flags.speciallyMarked) {
      [markerImage drawInRect:CGRectMake(16.f + horizontalOffset, 5.f, 6.f, 7.f)];
      [specialMarkerImage drawInRect:CGRectMake(24.f + horizontalOffset, 5.f, 6.f, 7.f)];
    }
    else {
      [markerImage drawInRect:CGRectMake(20.f + horizontalOffset, 5.f, 6.f, 7.f)];
    }
  }
  else if (flags.speciallyMarked) {
    [specialMarkerImage drawInRect:CGRectMake(20.f + horizontalOffset, 5.f, 6.f, 7.f)];
  }
  
  NSUInteger n = [self.date day];
  NSString *dayText = [NSString stringWithFormat:@"%lu", (unsigned long)n];
  const char *day = [dayText cStringUsingEncoding:NSUTF8StringEncoding];
  CGSize textSize = [dayText sizeWithFont:font];
  CGFloat textX, textY;
  textX = roundf(0.5f * (kTileSize.width - textSize.width)) + horizontalOffset;
  textY = 10.f + roundf(0.5f * (kTileSize.height - textSize.height));
  [textColor setFill];
  CGContextShowTextAtPoint(ctx, textX, textY, day, n >= 10 ? 2 : 1);
  
  if (self.highlighted) {
    [[UIColor colorWithWhite:0.25f alpha:0.3f] setFill];
    CGContextFillRect(ctx, CGRectMake(0.f, 0.f, kTileSize.width, kTileSize.height));
  }
}

- (void)drawBackgroundImage:(UIImage*)image {
  if ([UIScreen mainScreen].scale == 2.0) {
    [image drawInRect:CGRectMake(0.5, -0.5, kTileSize.width+0.5, kTileSize.height+0.5)];
  }
  else {
    [image drawInRect:CGRectMake(0, -1, kTileSize.width+1, kTileSize.height+1)];
  }
}

- (void)resetState
{
  // realign to the grid
  CGRect frame = self.frame;
  frame.origin = origin;
  frame.size = kTileSize;
  self.frame = frame;
  
  [date release];
  date = nil;
  flags.type = KalTileTypeRegular;
  flags.highlighted = NO;
  flags.selected = NO;
  flags.marked = NO;
}

- (void)setDate:(KalDate *)aDate
{
  if (date == aDate)
    return;

  [date release];
  date = [aDate retain];

  [self setNeedsDisplay];
}

- (BOOL)isSelected { return flags.selected; }

- (void)setSelected:(BOOL)selected
{
  if (flags.selected == selected)
    return;

  // workaround since I cannot draw outside of the frame in drawRect:
  if (![self isToday]) {
    CGRect rect = self.frame;
    if (selected) {
      rect.origin.x--;
      rect.size.width++;
      rect.size.height++;
    } else {
      rect.origin.x++;
      rect.size.width--;
      rect.size.height--;
    }
    self.frame = rect;
  }
  
  flags.selected = selected;
  [self setNeedsDisplay];
}

- (BOOL)isHighlighted { return flags.highlighted; }

- (void)setHighlighted:(BOOL)highlighted
{
  if (flags.highlighted == highlighted)
    return;
  
  flags.highlighted = highlighted;
  [self setNeedsDisplay];
}

- (BOOL)isMarked { return flags.marked; }

- (void)setMarked:(BOOL)marked
{
  if (flags.marked == marked)
    return;
  
  flags.marked = marked;
  [self setNeedsDisplay];
}

- (BOOL)isSpeciallyMarked { return flags.speciallyMarked; }

- (void)setSpeciallyMarked:(BOOL)speciallyMarked
{
  if (flags.speciallyMarked == speciallyMarked)
    return;

  flags.speciallyMarked = speciallyMarked;
  [self setNeedsDisplay];
}

- (KalTileType)type { return flags.type; }

- (void)setType:(KalTileType)tileType
{
  if (flags.type == tileType)
    return;
  
  // workaround since I cannot draw outside of the frame in drawRect:
  CGRect rect = self.frame;
  if (tileType == KalTileTypeToday) {
    rect.origin.x--;
    rect.size.width++;
    rect.size.height++;
  } else if (flags.type == KalTileTypeToday) {
    rect.origin.x++;
    rect.size.width--;
    rect.size.height--;
  }
  self.frame = rect;
  
  flags.type = tileType;
  [self setNeedsDisplay];
}

- (BOOL)isToday { return flags.type == KalTileTypeToday; }

- (BOOL)belongsToAdjacentMonth { return flags.type == KalTileTypeAdjacent; }

- (void)dealloc
{
  [date release];
  [super dealloc];
}

@end
