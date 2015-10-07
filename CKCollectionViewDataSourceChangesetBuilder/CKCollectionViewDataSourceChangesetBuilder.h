//
//  Header.h
//  CKCollectionViewDataSourceChangesetBuilder
//
//  Created by Jonathan Crooke on 07/10/2015.
//  Copyright © 2015 Jonathan Crooke. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ComponentKit/CKTransactionalComponentDataSourceChangeset.h>

/**
 Block-based DSL changeset builder.
 */
@interface CKCollectionViewDataSourceChangesetBuilder : NSObject

/**
 Convenience method for one-off changeset creation.
 @see Instance method for more information.
 */
+ (CKTransactionalComponentDataSourceChangeset*)build:(void(^)(CKCollectionViewDataSourceChangesetBuilder *builder))block;

/**
 Instance method builder is intended to be used as a local variable.
 For example, it might be used within a loop to add various items.
 Expressions are natural language of the form(s):
 
 [CKCollectionViewDataSourceChangesetBuilder build:^(CKCollectionViewDataSourceChangesetBuilder *builder) {
   builder.insert.section.at.index(0);
   builder.insert.item(@"Foo").at.indexPath([NSIndexPath indexPathForItem:1 inSection:4]);
   builder.remove.section.at.index(1);
   builder.move.section.at.index(0).to.index(4);
 }];
 
 @note Prepositions are optional, but recommended.
 @see CKTransactionalComponentDataSourceChangesetBuilderTests for examples.
*/
- (instancetype)build:(void(^)(CKCollectionViewDataSourceChangesetBuilder *builder))block;

- (CKTransactionalComponentDataSourceChangeset *)build;

/** Verbs */
@property (nonatomic, strong, readonly) CKCollectionViewDataSourceChangesetBuilder *update;
@property (nonatomic, strong, readonly) CKCollectionViewDataSourceChangesetBuilder *insert;
@property (nonatomic, strong, readonly) CKCollectionViewDataSourceChangesetBuilder *remove;
@property (nonatomic, strong, readonly) CKCollectionViewDataSourceChangesetBuilder *move;

/** Nouns */
@property (nonatomic, strong, readonly) CKCollectionViewDataSourceChangesetBuilder *section;
@property (nonatomic, strong, readonly) CKCollectionViewDataSourceChangesetBuilder *(^item)(id item);
@property (nonatomic, strong, readonly) CKCollectionViewDataSourceChangesetBuilder *(^index)(NSUInteger index);
@property (nonatomic, strong, readonly) CKCollectionViewDataSourceChangesetBuilder *(^indexPath)(NSIndexPath *indexPath);

/** 
 Prepositions 
 @note Optional, but certainly aid natural language readibility
 */
@property (nonatomic, strong, readonly) CKCollectionViewDataSourceChangesetBuilder *at;
@property (nonatomic, strong, readonly) CKCollectionViewDataSourceChangesetBuilder *to;
@property (nonatomic, strong, readonly) CKCollectionViewDataSourceChangesetBuilder *with;

@end

/**
 Additional syntactic sugar
 */
#define ck_indexPath(ITEM, SECTION)	indexPath([NSIndexPath indexPathForItem:ITEM inSection:SECTION])
#define ck_removeItem 							remove.item(nil)
#define ck_moveItem 								move.item(nil)
