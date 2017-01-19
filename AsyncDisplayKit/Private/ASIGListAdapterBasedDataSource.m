//
//  ASIGListAdapterBasedDataSource.m
//  AsyncDisplayKit
//
//  Created by Adlai Holler on 1/19/17.
//  Copyright © 2017 Facebook. All rights reserved.
//

#if IG_LIST_KIT

#import "ASIGListAdapterBasedDataSource.h"
#import <AsyncDisplayKit/AsyncDisplayKit.h>
#import <objc/runtime.h>

typedef IGListSectionController<IGListSectionType, ASSectionController> ASIGSectionController;

@protocol ASIGSupplementaryNodeSource <IGListSupplementaryViewSource, ASSupplementaryNodeSource>
@end

@interface ASIGListAdapterBasedDataSource () <UICollectionViewDelegateFlowLayout>
@property (nonatomic, weak, readonly) IGListAdapter *listAdapter;
@property (nonatomic, readonly) id<UICollectionViewDelegateFlowLayout> delegate;
@property (nonatomic, readonly) id<UICollectionViewDataSource> dataSource;
@end

@implementation ASIGListAdapterBasedDataSource

- (instancetype)initWithListAdapter:(IGListAdapter *)listAdapter
{
  if (self = [super init]) {
    [ASIGListAdapterBasedDataSource setASCollectionViewSuperclass];
    [ASIGListAdapterBasedDataSource configureUpdater:listAdapter.updater];

    ASDisplayNodeAssert([listAdapter conformsToProtocol:@protocol(UICollectionViewDataSource)], @"Expected IGListAdapter to conform to UICollectionViewDataSource.");
    ASDisplayNodeAssert([listAdapter conformsToProtocol:@protocol(UICollectionViewDelegateFlowLayout)], @"Expected IGListAdapter to conform to UICollectionViewDelegateFlowLayout.");
    _listAdapter = listAdapter;
  }
  return self;
}

- (id<UICollectionViewDataSource>)dataSource
{
  return (id<UICollectionViewDataSource>)_listAdapter;
}

- (id<UICollectionViewDelegateFlowLayout>)delegate
{
  return (id<UICollectionViewDelegateFlowLayout>)_listAdapter;
}

#pragma mark - ASCollectionDelegate

- (void)collectionNode:(ASCollectionNode *)collectionNode didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
  [self.delegate collectionView:collectionNode.view didSelectItemAtIndexPath:indexPath];
}

- (void)collectionNode:(ASCollectionNode *)collectionNode willDisplayItemWithNode:(ASCellNode *)node
{
  UICollectionViewCell *cell = ASDynamicCast(node.view.superview.superview, UICollectionViewCell);
  ASDisplayNodeAssertNotNil(cell, @"Expected cell node to be hosted in a cell!");
  ASCollectionView *collectionView = collectionNode.view;
  NSIndexPath *indexPath = [collectionView indexPathForNode:node];
  if (cell && indexPath) {
    [self.delegate collectionView:collectionView willDisplayCell:cell forItemAtIndexPath:indexPath];
  }
}

- (void)collectionNode:(ASCollectionNode *)collectionNode didEndDisplayingItemWithNode:(ASCellNode *)node
{
  UICollectionViewCell *cell = ASDynamicCast(node.view.superview.superview, UICollectionViewCell);
  ASDisplayNodeAssertNotNil(cell, @"Expected cell node to be hosted in a cell!");
  ASCollectionView *collectionView = collectionNode.view;
  NSIndexPath *indexPath = [collectionView indexPathForNode:node];
  if (cell && indexPath) {
    [self.delegate collectionView:collectionView didEndDisplayingCell:cell forItemAtIndexPath:indexPath];
  }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
  [self.delegate scrollViewDidScroll:scrollView];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
  [self.delegate scrollViewWillBeginDragging:scrollView];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
  [self.delegate scrollViewDidEndDragging:scrollView willDecelerate:decelerate];
}

- (BOOL)shouldBatchFetchForCollectionNode:(ASCollectionNode *)collectionNode
{
  NSInteger sectionCount = [self numberOfSectionsInCollectionNode:collectionNode];
  if (sectionCount == 0) {
    return NO;
  }
  return [[self sectionControllerForSection:sectionCount - 1] shouldBatchFetch];
}

- (void)collectionNode:(ASCollectionNode *)collectionNode willBeginBatchFetchWithContext:(ASBatchContext *)context
{
  NSInteger sectionCount = [self numberOfSectionsInCollectionNode:collectionNode];
  if (sectionCount == 0) {
    return;
  }
  return [[self sectionControllerForSection:sectionCount - 1] beginBatchFetchWithContext:context];
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
  return [self.delegate collectionView:collectionView layout:collectionViewLayout sizeForItemAtIndexPath:indexPath];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{
  return [self.delegate collectionView:collectionView layout:collectionViewLayout referenceSizeForHeaderInSection:section];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section
{
  return [self.delegate collectionView:collectionView layout:collectionViewLayout referenceSizeForFooterInSection:section];
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
  return [self.delegate collectionView:collectionView layout:collectionViewLayout insetForSectionAtIndex:section];
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
  return [self.delegate collectionView:collectionView layout:collectionViewLayout minimumLineSpacingForSectionAtIndex:section];
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
  return [self.delegate collectionView:collectionView layout:collectionViewLayout minimumInteritemSpacingForSectionAtIndex:section];
}

#pragma mark - ASCollectionDataSource

- (NSInteger)collectionNode:(ASCollectionNode *)collectionNode numberOfItemsInSection:(NSInteger)section
{
  return [self.dataSource collectionView:collectionNode.view numberOfItemsInSection:section];
}

- (NSInteger)numberOfSectionsInCollectionNode:(ASCollectionNode *)collectionNode
{
  return [self.dataSource numberOfSectionsInCollectionView:collectionNode.view];
}

- (ASCellNodeBlock)collectionNode:(ASCollectionNode *)collectionNode nodeBlockForItemAtIndexPath:(NSIndexPath *)indexPath
{
  return [[self sectionControllerForSection:indexPath.section] nodeBlockForItemAtIndex:indexPath.item];
}

- (ASSizeRange)collectionNode:(ASCollectionNode *)collectionNode constrainedSizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
  return [[self sectionControllerForSection:indexPath.section] constrainedSizeForItemAtIndex:indexPath.item];
}

- (ASCellNode *)collectionNode:(ASCollectionNode *)collectionNode nodeForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
  return [[self supplementaryElementSourceForSection:indexPath.section] nodeForSupplementaryElementOfKind:kind atIndex:indexPath.item];
}

#pragma mark - Helpers

- (id<ASIGSupplementaryNodeSource>)supplementaryElementSourceForSection:(NSInteger)section
{
  ASIGSectionController *ctrl = [self sectionControllerForSection:section];
  id<ASIGSupplementaryNodeSource> src = (id<ASIGSupplementaryNodeSource>)ctrl.supplementaryViewSource;
  ASDisplayNodeAssert(src == nil || [src conformsToProtocol:@protocol(ASIGSupplementaryNodeSource)], @"Supplementary view source should conform to %@", NSStringFromProtocol(@protocol(ASIGSupplementaryNodeSource)));
  return src;
}

- (ASIGSectionController *)sectionControllerForSection:(NSInteger)section
{
  id object = [_listAdapter objectAtSection:section];
  ASIGSectionController *ctrl = (ASIGSectionController *)[_listAdapter sectionControllerForObject:object];
  ASDisplayNodeAssert([ctrl conformsToProtocol:@protocol(ASSectionController)], @"Expected section controller to conform to %@. Controller: %@", NSStringFromProtocol(@protocol(ASSectionController)), ctrl);
  return ctrl;
}

/**
 * Set ASCollectionView's superclass to IGListCollectionView.
 * Scary! If IGListKit removed the subclassing restriction, we could
 * use #if in the @interface to choose the superclass based on
 * whether we have IGListKit available.
 */
+ (void)setASCollectionViewSuperclass
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    class_setSuperclass([self class], [IGListCollectionView class]);
  });
#pragma clang diagnostic pop
}

/// Ensure updater won't call reloadData on us.
+ (void)configureUpdater:(id<IGListUpdatingDelegate>)updater
{
  // Cast to NSObject will be removed after https://github.com/Instagram/IGListKit/pull/435
  if ([(id<NSObject>)updater isKindOfClass:[IGListAdapterUpdater class]]) {
    [(IGListAdapterUpdater *)updater setAllowsBackgroundReloading:NO];
  } else {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      NSLog(@"WARNING: Use of non-%@ updater with AsyncDisplayKit is discouraged. Updater: %@", NSStringFromClass([IGListAdapterUpdater class]), updater);
    });
  }
}

@end

#endif // IG_LIST_KIT
