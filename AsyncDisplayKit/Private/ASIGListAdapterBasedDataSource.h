//
//  ASIGListAdapterBasedDataSource.h
//  AsyncDisplayKit
//
//  Created by Adlai Holler on 1/19/17.
//  Copyright © 2017 Facebook. All rights reserved.
//

#if IG_LIST_KIT

#import <IGListKit/IGListKit.h>
#import <AsyncDisplayKit/AsyncDisplayKit.h>

AS_SUBCLASSING_RESTRICTED
@interface ASIGListAdapterBasedDataSource : NSObject <ASCollectionDataSource, ASCollectionDelegate>

- (instancetype)initWithListAdapter:(IGListAdapter *)listAdapter;

@end

#endif
