import RxSwift

extension ObservableType {
    /// Absorbes all of events from a and b observables into result observable.
    ///
    /// - parameter a: First observable
    /// - parameter b: Second observable
    /// - returns: New `Observable` which emits all of events from a and b `Observable`s.
    /// If error or complete is received on any of the `Observable`s, it's propagates immediately to result `Observable`
    static func absorb(_ a: Observable<Element>, _ b: Observable<Element>) -> Observable<Element> {
        return .create { observer in
            let disposable = CompositeDisposable()
            let innerObserver: AnyObserver<Element> = AnyObserver { event in
                observer.on(event)
                if event.isStopEvent {
                    disposable.dispose()
                }
            }
            _ = disposable.insert(a.subscribe(innerObserver))
            if !disposable.isDisposed {
                _ = disposable.insert(b.subscribe(innerObserver))
            }

            return disposable
        }
    }
}
