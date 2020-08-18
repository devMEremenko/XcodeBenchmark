import Foundation
import RxSwift

func unimplementedFunction(file: String = #file, function: String = #function, line: Int = #line) {
    fatalError("Unimplemented function \(function) in \(file):\(line)")
}

extension Observable {
    static func unimplemented(file: String = #file, function: String = #function, line: Int = #line)
        -> Observable<Element> {
        unimplementedFunction(file: file, function: function, line: line)
        return Observable<Element>.empty()
    }
}
