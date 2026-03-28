//
//  UICollectionView+ReuseIdentifierProtocol.swift
//  R.swift Library
//
//  Created by Mathijs Kadijk on 06-12-15.
//  From: https://github.com/mac-cain13/R.swift.Library
//  License: MIT License
//

#if !os(watchOS)
import Foundation
import UIKit

public extension UICollectionView {
  /**
   Returns a typed reusable cell object located by its identifier
   
   - parameter identifier: The R.reuseIdentifier.* value for the specified cell.
   - parameter indexPath: The index path specifying the location of the cell. The data source receives this information when it is asked for the cell and should just pass it along. This method uses the index path to perform additional configuration based on the cell’s position in the collection view.
   
   - returns: A subclass of UICollectionReusableView or nil if the cast fails.
  */
  func dequeueReusableCell<Identifier: ReuseIdentifierType>(withReuseIdentifier identifier: Identifier, for indexPath: IndexPath) -> Identifier.ReusableType?
    where Identifier.ReusableType: UICollectionReusableView
  {
    return dequeueReusableCell(withReuseIdentifier: identifier.identifier, for: indexPath) as? Identifier.ReusableType
  }

  /**
   Returns a typed reusable supplementary view located by its identifier and kind.
   
   - parameter elementKind: The kind of supplementary view to retrieve. This value is defined by the layout object.
   - parameter identifier: The R.reuseIdentifier.* value for the specified view.
   - parameter indexPath: The index path specifying the location of the cell. The data source receives this information when it is asked for the cell and should just pass it along. This method uses the index path to perform additional configuration based on the cell’s position in the collection view.
   
   - returns: A subclass of UICollectionReusableView or nil if the cast fails.
  */
  func dequeueReusableSupplementaryView<Identifier: ReuseIdentifierType>(ofKind elementKind: String, withReuseIdentifier identifier: Identifier, for indexPath: IndexPath) -> Identifier.ReusableType?
    where Identifier.ReusableType: UICollectionReusableView
  {
    return dequeueReusableSupplementaryView(ofKind: elementKind, withReuseIdentifier: identifier.identifier, for: indexPath) as? Identifier.ReusableType
  }

  /**
   Register a R.nib.* for use in creating new collection view cells.

   - parameter nibResource: A nib resource (R.nib.*) containing a object of type UICollectionViewCell that has a reuse identifier
   */
  func register<Resource: NibResourceType & ReuseIdentifierType>(_ nibResource: Resource)
    where Resource.ReusableType: UICollectionViewCell
  {
    register(UINib(resource: nibResource), forCellWithReuseIdentifier: nibResource.identifier)
  }

  /**
   Register a R.nib.* for use in creating supplementary views for the collection view.

   - parameter nibResource: A nib resource (R.nib.*) containing a object of type UICollectionReusableView. that has a reuse identifier
   */
  func register<Resource: NibResourceType & ReuseIdentifierType>(_ nibResource: Resource, forSupplementaryViewOfKind kind: String)
    where Resource.ReusableType: UICollectionReusableView
  {
    register(UINib(resource: nibResource), forSupplementaryViewOfKind: kind, withReuseIdentifier: nibResource.identifier)
  }
}
#endif
