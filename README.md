LXReorderableCollectionViewFlowLayout
=====================================

Extends `UICollectionViewFlowLayout` to support reordering of cells. Similar to long press and pan on books in iBook.

Features
========

The goal of LXReorderableCollectionViewFlowLayout is to provides capability for reordering of cell, similar to iBook.

 - Long press on cell invoke reordering capability.
 - When reordering capability is invoked, fade the selected cell from highlighted to normal state.
 - Drag around the selected cell to move it to the desired location, other cells adjust accordingly. Callback in the form of delegate methods are invoked.
 - Drag selected cell to the edges, depending on scroll direction, autoscroll in the desired direction.
 - Release to stop reordering.

Getting Started
===============

1. Drag the `LXReorderableCollectionViewFlowLayout` folder into your project.
2. Initialize/Setup your collection view to use `LXReorderableCollectionViewFlowLayout`.
3. If you setup your collection view programmatically, make sure you call `[LXReorderableCollectionViewFlowLayout setUpGestureRecognizersOnCollectionView]` instance method after the collection view is setup.

    [theReorderableCollectionViewFlowLayout setUpGestureRecognizersOnCollectionView];

4. The collection view controller that is to support reordering capability must conforms to `LXReorderableCollectionViewDelegateFlowLayout` protocol. For example,

    #pragma mark - LXReorderableCollectionViewDelegateFlowLayout methods

    - (void)itemAtIndexPath:(NSIndexPath *)theFromIndexPath willMoveToIndexPath:(NSIndexPath *)theToIndexPath {
        id theFromItem = [self.deck objectAtIndex:theFromIndexPath.item];
        [self.deck removeObjectAtIndex:theFromIndexPath.item];
        [self.deck insertObject:theFromItem atIndex:theToIndexPath.item];
    }

5. Setup your collection view accordingly to your need and run it!

Requirements
============

 - ARC
 - iOS 6
 - Xcode 4.5 and above

Credits
=======

LXReorderableCollectionViewFlowLayout is created by [Stan Chang Khin Boon](https://github.com/lxcid) as part of a project under [buUuk](http://www.buuuk.com/).

Many thanks to __MaximilianL__ in the [Apple Developer Forums for sharing his implementation](https://devforums.apple.com/message/682764) which lead me to this project.

The playing cards in the demo are downloaded from [http://www.jfitz.com/cards/](http://www.jfitz.com/cards/).

README.md structure is heavily referenced from [AFNetworking](https://github.com/AFNetworking/AFNetworking).

### Creators

[Stan Chang Khin Boon](http://github.com/lxcid)  
[@lxcid](https://twitter.com/lxcid)

License
=======

LXReorderableCollectionViewFlowLayout is available under the MIT license.