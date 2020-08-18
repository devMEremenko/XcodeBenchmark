import Foundation
import CoreBluetooth

protocol UUIDIdentifiable {
    var uuid: CBUUID { get }
}

/// Filters an item list based on the provided UUID list. The items must conform to UUIDIdentifiable.
/// Only items returned whose UUID matches an item in the provided UUID list.
/// If requredAll is true, each UUID should have at least one item matching in the items list.
/// Otherwise the result is nil.
/// - uuids: a UUID list or nil
/// - items: items to be filtered
/// - requireAll: method will return nil if this param is true and uuids is not subset of items
/// - Returns: the filtered item list
func filterUUIDItems<T: UUIDIdentifiable>(uuids: [CBUUID]?, items: [T], requireAll: Bool) -> [T]? {
    guard let uuids = uuids, !uuids.isEmpty else { return items }

    let itemsUUIDs = items.map { $0.uuid }
    let uuidsSet = Set(uuids)
    guard !requireAll || uuidsSet.isSubset(of: Set(itemsUUIDs)) else { return nil }
    return items.filter { uuidsSet.contains($0.uuid) }
}
