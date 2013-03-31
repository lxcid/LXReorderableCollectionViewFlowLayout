LXReorderableCollectionViewFlowLayout
=====================================

Extends `UICollectionViewFlowLayout` to support reordering of cells. Similar to long press and pan on books in iBook.

Features
========

The goal of LXReorderableCollectionViewFlowLayout is to provides capability for reordering of cell, similar to iBook.

 - Long press on cell invoke reordering capability.
 - When reordering capability is invoked, fade the selected cell from highlighted to normal state.
 - Drag around the selected cell to move it to the desired location, other cells adjust accordingly. Callback in the form of delegate methods are invoked.
 - Drag selected cell to the edges, depending on scroll direction, scroll in the desired direction.
 - Release to stop reordering.

Getting Started
===============

<img src="https://raw.github.com/lxcid/LXReorderableCollectionViewFlowLayout/master/Content/Screenshots/screenshot1.png" alt="Screenshot" title="Screenshot" style="display:block; margin: 10px auto 30px auto; width: 300px; height: 400px;" class="center">

 1. Drag the `LXReorderableCollectionViewFlowLayout` folder into your project.
 2. Initialize/Setup your collection view to use `LXReorderableCollectionViewFlowLayout`.

 3. The collection view controller that is to support reordering capability must conforms to `LXReorderableCollectionViewDelegateFlowLayout` protocol. For example,

        - (void)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)layout itemAtIndexPath:(NSIndexPath *)fromIndexPath willMoveToIndexPath:(NSIndexPath *)toIndexPath {
            id object = [mutableArray objectAtIndex:fromIndexPath.item];
            [mutableArray removeObjectAtIndex:FromIndexPath.item];
            [mutableArray insertObject:object atIndex:ToIndexPath.item];
        }

 4. Setup your collection view accordingly to your need, run and see it in action! :D

Changes
============

### Feb 24 2013 (Luke Scott)

- Removed setUpGestureRecognizersOnCollectionView
- Removed layout from delegate methods (can be accessed from collectionView)
- Renamed delegate methods and split between dataSource and delegate
- Added dataSource and delegate examples to sample project

### Feb 23 2013 (Luke Scott)

- Refactored everything to be more readable / maintainable
- Deprecated setUpGestureRecognizersOnCollectionView - no longer necessary

Requirements
============

 - ARC
 - iOS 6
 - Xcode 4.5 and above

Credits
=======

- Originally created by Stan Chang Khin Boon ([Github: @lxcid](http://github.com/lxcid), [Twitter: @lxcid](https://twitter.com/lxcid), [Google+: +Stan Chang Khin Boon](https://plus.google.com/118232095174296729296?rel=author)) for [buUuk](http://www.buuuk.com/), with reference to [MaximilianL's implementation on Apple Developer Forums](https://devforums.apple.com/message/682764).
- Refactored by [Luke Scott](https://github.com/lukescott), with some help from [mulle-nat's fork](https://github.com/mulle-nat/LXReorderableCollectionViewFlowLayout).
- Playing cards in the demo are downloaded from [http://www.jfitz.com/cards/](http://www.jfitz.com/cards/).

License
=======

LXReorderableCollectionViewFlowLayout is available under the MIT license.
