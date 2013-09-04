Pod::Spec.new do |s|
  s.name = 'LXReorderableCollectionViewFlowLayout-Velosys'
  s.version = '0.1.0.velosys'
  s.summary = 'Extends UICollectionViewFlowLayout to support reordering of cells. Similar to long press and pan on books in iBook.'
  s.homepage = 'https://github.com/Velosys/LXReorderableCollectionViewFlowLayout-Velosys'
  s.license = {
    :type => 'MIT',
    :file => 'LICENSE'
  }
  s.author = 'Stan Chang Khin Boon'
  s.source = {
    :git => 'https://github.com/Velosys/LXReorderableCollectionViewFlowLayout-Velosys.git',
    :tag => '0.1.0.velosys'
  }
  s.platform = :ios, '4.3'
  s.source_files = 'LXReorderableCollectionViewFlowLayout/'
  s.public_header_files = 'LXReorderableCollectionViewFlowLayout/'
  s.frameworks = 'UIKit', 'CoreGraphics'
  s.requires_arc = true
end
