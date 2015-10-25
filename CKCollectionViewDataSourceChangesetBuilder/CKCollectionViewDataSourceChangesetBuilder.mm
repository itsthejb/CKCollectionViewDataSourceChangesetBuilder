//
//  CKCollectionViewDataSourceChangesetBuilder.mm
//  CKCollectionViewDataSourceChangesetBuilder
//
//  Created by Jonathan Crooke on 07/10/2015.
//  Copyright © 2015 Jonathan Crooke. All rights reserved.
//

#import "CKCollectionViewDataSourceChangesetBuilder.h"
#import "CKTransactionalComponentDataSourceChangesetInternal.h"

namespace CKChangesetBuilder {
  namespace Verb {
    enum Type { None, Update, Insert, Remove, Move };
  }
  namespace Element {
    enum Type { None, Section, Item };
  }
}

using namespace CKChangesetBuilder;

@interface CKCollectionViewDataSourceChangesetBuilder ()
@property (nonatomic, assign) Verb::Type verb;
@property (nonatomic, assign) Element::Type element;
@property (nonatomic, strong) id object;
@property (nonatomic, assign) NSNumber *sectionIndex;
@property (nonatomic, strong) NSIndexPath *itemIndexPath;
@property (nonatomic, assign) NSNumber *sectionMoveIndex;
@property (nonatomic, strong) NSIndexPath *itemMoveIndexPath;
- (void)storeIfExpressionComplete;
- (void)reset;
@end

@implementation CKCollectionViewDataSourceChangesetBuilder
{
  NSMutableDictionary *_updatedItems;
  NSMutableSet *_removedItems;
  NSMutableIndexSet *_removedSections;
  NSMutableDictionary *_movedItems;
  NSMutableDictionary *_movedSections;
  NSMutableIndexSet *_insertedSections;
  NSMutableDictionary *_insertedItems;
}

- (instancetype)init
{
  if ((self = [super init])) {
    _updatedItems = [NSMutableDictionary dictionary];
    _movedItems = [NSMutableDictionary dictionary];
    _movedSections = [NSMutableDictionary dictionary];
    _insertedItems = [NSMutableDictionary dictionary];
    _removedItems = [NSMutableSet set];
    _removedSections = [NSMutableIndexSet indexSet];
    _insertedSections = [NSMutableIndexSet indexSet];
  }
  return self;
}

+ (CKTransactionalComponentDataSourceChangeset*)build:(void(^)(CKCollectionViewDataSourceChangesetBuilder *builder))block
{
  CKCollectionViewDataSourceChangesetBuilder *builder = [[self alloc] init];
  [builder build:block];
  return builder.build;
}

- (instancetype)build:(void(^)(CKCollectionViewDataSourceChangesetBuilder *builder))block {
  block(self);
  return self;
}

- (CKCollectionViewDataSourceChangesetBuilder *)update {
  NSAssert(self.verb == Verb::None, @"Expression contains >1 verb");
  self.verb = Verb::Update;
  return self;
}

- (CKCollectionViewDataSourceChangesetBuilder *)insert {
  NSAssert(self.verb == Verb::None, @"Expression contains >1 verb");
  self.verb = Verb::Insert;
  return self;
}

- (CKCollectionViewDataSourceChangesetBuilder *)remove {
  NSAssert(self.verb == Verb::None, @"Expression contains >1 verb");
  self.verb = Verb::Remove;
  return self;
}

- (CKCollectionViewDataSourceChangesetBuilder *)move {
  NSAssert(self.verb == Verb::None, @"Expression contains >1 verb");
  self.verb = Verb::Move;
  return self;
}

- (CKCollectionViewDataSourceChangesetBuilder *)section {
  NSAssert(self.verb != Verb::None, @"Expression contains noun, but no verb");
  NSAssert(self.verb != Verb::Move, @"Section moving is not supported");
  NSAssert(self.element == Element::None, @"Expression contains >1 element");
  self.element = Element::Section;
  return self;
}

- (CKCollectionViewDataSourceChangesetBuilder *)at {
  NSAssert(self.verb != Verb::None, @"Expression contains no verb");
  NSAssert((self.element == Element::Section && !self.sectionIndex) ||
           (self.element == Element::Item && !self.itemIndexPath) ||
           (self.verb == Verb::Update),
           @"Expression already contains an index, or indexPath");
  return self;
}

- (CKCollectionViewDataSourceChangesetBuilder *)to {
  NSAssert(self.verb == Verb::Move, @"Preposition only valid for move operation");
  NSAssert((self.element == Element::Section && self.sectionIndex) ||
           (self.element == Element::Item && self.itemIndexPath),
           @"Expression contains no source index or indexPath for move");
  return self;
}

- (CKCollectionViewDataSourceChangesetBuilder *)with {
  NSAssert(self.verb == Verb::Update, @"Preposition only valid for update operation");
  NSAssert(self.itemIndexPath, @"Now indexPath for update operation");
  return self;
}

- (CKCollectionViewDataSourceChangesetBuilder *(^)(id))item {
  NSAssert(self.verb != Verb::None, @"Expression contains no verb");
  NSAssert(self.element == Element::None, @"Expression already contains a noun");
  self.element = Element::Item;
  return ^(id item) {
    NSAssert(self.verb != Verb::Insert || item, @"Object required for insert operation");
    self.object = item;
    [self storeIfExpressionComplete];
    return self;
  };
}

- (CKCollectionViewDataSourceChangesetBuilder *(^)(NSUInteger))index {
  NSAssert(self.element == Element::Section, @"Index only valid for section operations");
  return ^(NSUInteger index) {
    switch (self.verb) {
      case Verb::Insert:
      case Verb::Remove:
        self.sectionIndex = @(index);
        break;
      case Verb::Move:
        self.sectionIndex ? self.sectionMoveIndex = @(index) : self.sectionIndex = @(index);
        break;
      default:
        NSAssert(NO, @"Not valid for Update");
        break;
    }
    [self storeIfExpressionComplete];
    return self;
  };
}

- (CKCollectionViewDataSourceChangesetBuilder *(^)(NSIndexPath *))indexPath {
  NSAssert(self.element == Element::Item || self.verb == Verb::Update, @"Expression contains no object");
  return ^(NSIndexPath *indexPath) {
    switch (self.verb) {
      case Verb::Insert:
      case Verb::Remove:
      case Verb::Update:
        self.itemIndexPath = indexPath;
        break;
      case Verb::Move:
        self.itemIndexPath ? self.itemMoveIndexPath = indexPath : self.itemIndexPath = indexPath;
        break;
      default:
        break;
    }
    [self storeIfExpressionComplete];
    return self;
  };
}

- (void)storeIfExpressionComplete
{
  NSAssert(self.verb != Verb::None, @"Expression contains no verb");
  NSAssert(self.element != Element::None || self.verb == Verb::Update, @"Expression contains no noun");
  switch (self.verb)
  {
    case Verb::Update:
      /** Update item */
      if (self.object && self.itemIndexPath) {
        NSAssert2(!_updatedItems[self.itemIndexPath],
                  @"Already object %@ for indexPath %@",
                  self.object, self.itemIndexPath);
        _updatedItems[self.itemIndexPath] = self.object;
        [self reset];
      }
      break;

    case Verb::Insert:
      /** Insert section */
      if (self.element == Element::Section && self.sectionIndex)
      {
        NSAssert1(![_insertedSections containsIndex:self.sectionMoveIndex.unsignedIntegerValue],
                  @"Inserted sections already contains index %@", self.sectionIndex);
        [_insertedSections addIndex:self.sectionMoveIndex.unsignedIntegerValue];
        [self reset];
      }

      /** Insert item */
      else if (self.element == Element::Item && self.object && self.itemIndexPath)
      {
        NSAssert2(!_insertedItems[self.itemIndexPath],
                  @"Inserted items already contains object %@ for indexPath %@",
                  self.object, self.itemIndexPath);
        _insertedItems[self.itemIndexPath] = self.object;
        [self reset];
      }
      break;

    case Verb::Move:
      /** Move section */
      if (self.element == Element::Section && self.sectionIndex && self.sectionMoveIndex)
      {
        NSAssert2(!_movedSections[self.sectionIndex],
                  @"Section move already exists from %@ to %@",
                  self.sectionIndex, self.sectionMoveIndex);
        _movedSections[self.sectionIndex] = self.sectionMoveIndex;
        [self reset];
      }

      /** Move item */
      else if (self.element == Element::Item && self.itemIndexPath && self.itemMoveIndexPath)
      {
        NSAssert2(!_movedItems[self.itemIndexPath],
                  @"Item move already exists from %@ to %@",
                  self.itemIndexPath, self.itemMoveIndexPath);
        _movedItems[self.itemIndexPath] = self.itemMoveIndexPath;
        [self reset];
      }
      break;

    case Verb::Remove:
      /** Remove section */
      if (self.element == Element::Section && self.sectionIndex)
      {
        NSAssert1(![_removedSections containsIndex:self.sectionIndex.unsignedIntegerValue],
                  @"Section %@ already stored for removal", self.sectionIndex);
        [_removedSections addIndex:self.sectionIndex.unsignedIntegerValue];
        [self reset];
      }

      /** Remove item */
      else if (self.element == Element::Item && self.itemIndexPath)
      {
        NSAssert1(![_removedItems member:self.itemIndexPath],
                  @"Item at indexPath %@ already stored for removal",
                  self.itemIndexPath);
        [_removedItems addObject:self.itemIndexPath];
        [self reset];
      }
      break;

    default:
      break;
  }
}

- (void)reset
{
  self.verb = Verb::None;
  self.element = Element::None;
  self.object = nil;
  self.sectionIndex = self.sectionMoveIndex = nil;
  self.itemIndexPath = self.itemMoveIndexPath = nil;
}

- (CKTransactionalComponentDataSourceChangeset *)build
{
  return [[CKTransactionalComponentDataSourceChangeset alloc] initWithUpdatedItems:_updatedItems
                                                                      removedItems:_removedItems
                                                                   removedSections:_removedSections
                                                                        movedItems:_movedItems
                                                                  insertedSections:_insertedSections
                                                                     insertedItems:_insertedItems];
}

@end
