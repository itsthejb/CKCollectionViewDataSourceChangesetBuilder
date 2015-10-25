#CKCollectionViewDataSourceChangesetBuilder

##What's This?

CKCollectionViewDataSourceChangesetBuilder is a DSL builder for [ComponentKit](http://componentkit.org/)'s `CKTransactionalComponentDataSourceChangeset`. It is heavily inspired by [Masonry](https://github.com/SnapKit/Masonry), and should allow you to write very readable code for building your changesets.

##How Do I Use It?

`CKCollectionViewDataSourceChangesetBuilder` uses verbs, nouns and prepositions in order to allow you to express your changeset builds in readable English, [with just a few exceptions](#helper-macros). A few examples will make this clearer:

		[CKCollectionViewDataSourceChangesetBuilder build:^(CKCollectionViewDataSourceChangesetBuilder *builder) {
		  builder.insert.section.at.index(0);
		  builder.insert.item(@"Foo").at.indexPath([NSIndexPath indexPathForItem:1 inSection:4]);
		  builder.remove.section.at.index(1);
		  builder.move.section.at.index(0).to.index(4);
		}];

Due to the limited number of keywords, the possible combinations should hopefully be fairly self-explanatory. The builder has been written to throw useful exceptions when the syntax is misused.

`CKCollectionViewDataSourceChangesetBuilderTests` provides examples of all of the syntax combinations, so please take a look there first.

###Helper Macros

* `ck_indexPath(ITEM, SECTION)` saves constant use of `[NSIndexPath indexPathForItem:inSection:]`.

The following two macros aim to compensate for the lack of default arguments in Objective-C; when moving or removing items we need to reuse the verb `item`. However, since we have no object to *insert* the argument must be `nil`. This wouldn't be nearly as readable. Instead you can use:

* `ck_removeItem` instead of `remove.item(nil)`.
* `ck_moveItem` instead of `move.item(nil)`.

## Why No Swift?

`ComponentKit` is written primarily in C++, which means you will usually be using it from within Obj-C++ contexts. Whilst it's possible you could create changesets from Swift contexts, I don't believe this is enough to justify another implementation at this time. Of course, if someone would like to implement it then I'd be happy to receive a PR!

---

**Have fun!**

jon.crooke@gmail.com
