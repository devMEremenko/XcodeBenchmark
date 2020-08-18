//
//  UITableView+ReuseIdentifierProtocol.swift
//  R.swift Library
//
//  Created by Mathijs Kadijk on 06-12-15.
//  From: https://github.com/mac-cain13/R.swift.Library
//  License: MIT License
//

import Foundation
import UIKit

public extension UITableView {
  /**
   Returns a typed reusable table-view cell object for the specified reuse identifier and adds it to the table.
   
   - parameter identifier: A R.reuseIdentifier.* value identifying the cell object to be reused.
   - parameter indexPath: The index path specifying the location of the cell. The data source receives this information when it is asked for the cell and should just pass it along. This method uses the index path to perform additional configuration based on the cell’s position in the table view.
   
   - returns: The UITableViewCell subclass with the associated reuse identifier or nil if it couldn't be casted correctly.
   
   - precondition: You must register a class or nib file using the registerNib: or registerClass:forCellReuseIdentifier: method before calling this method.
  */
  func dequeueReusableCell<Identifier: ReuseIdentifierType>(withIdentifier identifier: Identifier, for indexPath: IndexPath) -> Identifier.ReusableType?
    where Identifier.ReusableType: UITableViewCell
  {
    return dequeueReusableCell(withIdentifier: identifier.identifier, for: indexPath) as? Identifier.ReusableType
  }

  @available(*, unavailable, message: "Use dequeueReusableCell(withIdentifier:for:) instead")
  func dequeueReusableCell<Identifier: ReuseIdentifierType>(withIdentifier identifier: Identifier) -> Identifier.ReusableType?
    where Identifier.ReusableType: UITableViewCell
  {
    fatalError()
  }

  /**
   Returns a typed reusable header or footer view located by its identifier.
   
   - parameter identifier: A R.reuseIdentifier.* value identifying the header or footer view to be reused.
   
   - returns: A UITableViewHeaderFooterView object with the associated identifier or nil if no such object exists in the reusable view queue or if it couldn't be cast correctly.
   */
  func dequeueReusableHeaderFooterView<Identifier: ReuseIdentifierType>(withIdentifier identifier: Identifier) -> Identifier.ReusableType?
    where Identifier.ReusableType: UITableViewHeaderFooterView
  {
    return dequeueReusableHeaderFooterView(withIdentifier: identifier.identifier) as? Identifier.ReusableType
  }

  /**
   Register a R.nib.* containing a cell with the table view under it's contained identifier.
   
   - parameter nibResource: A nib resource (R.nib.*) containing a table view cell that has a reuse identifier
  */
  func register<Resource: NibResourceType & ReuseIdentifierType>(_ nibResource: Resource) where Resource.ReusableType: UITableViewCell {
    register(UINib(resource: nibResource), forCellReuseIdentifier: nibResource.identifier)
  }

  /**
   Register a R.nib.* containing a header or footer with the table view under it's contained identifier.

   - parameter nibResource: A nib resource (R.nib.*) containing a view that has a reuse identifier
   */
  func registerHeaderFooterView<Resource: NibResourceType>(_ nibResource: Resource) where Resource: ReuseIdentifierType, Resource.ReusableType: UIView {
    register(UINib(resource: nibResource), forHeaderFooterViewReuseIdentifier: nibResource.identifier)
  }
}
