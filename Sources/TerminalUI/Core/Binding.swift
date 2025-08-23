import Foundation

@propertyWrapper
public struct Binding<Value: Sendable>: Sendable {
    private let getter: @MainActor @Sendable () -> Value
    private let setter: @MainActor @Sendable (Value) -> Void
    
    @MainActor
    public var wrappedValue: Value {
        get { getter() }
        nonmutating set { setter(newValue) }
    }
    
    public var projectedValue: Binding<Value> {
        self
    }
    
    public init(
        get: @escaping @MainActor @Sendable () -> Value,
        set: @escaping @MainActor @Sendable (Value) -> Void
    ) {
        self.getter = get
        self.setter = set
    }
    

    public init(wrappedValue: Value) {
        self.getter = { @MainActor in wrappedValue }
        self.setter = { @MainActor _ in  }
    }
    

    public static func constant(_ value: Value) -> Binding<Value> {
        Binding(
            get: { @MainActor in value },
            set: { @MainActor _ in }
        )
    }
    

    public subscript<Subject: Sendable>(
        dynamicMember keyPath: WritableKeyPath<Value, Subject>
    ) -> Binding<Subject> {

        nonisolated(unsafe) let unsafeKeyPath = keyPath
        return Binding<Subject>(
            get: { @MainActor in self.wrappedValue[keyPath: unsafeKeyPath] },
            set: { @MainActor newValue in self.wrappedValue[keyPath: unsafeKeyPath] = newValue }
        )
    }
}

public extension Binding {

    func map<T: Sendable>(
        get transform: @escaping @Sendable (Value) -> T,
        set transformBack: @escaping @Sendable (T, Value) -> Value
    ) -> Binding<T> {
        Binding<T>(
            get: { @MainActor in transform(self.wrappedValue) },
            set: { @MainActor newValue in
                self.wrappedValue = transformBack(newValue, self.wrappedValue)
            }
        )
    }
    

    func unwrap<T: Sendable>(default defaultValue: T) -> Binding<T> where Value == T? {
        Binding<T>(
            get: { @MainActor in self.wrappedValue ?? defaultValue },
            set: { @MainActor newValue in self.wrappedValue = newValue }
        )
    }
}

@MainActor
public final class ObservableState<Value: Sendable>: Sendable {
    private var value: Value
    private var observers: [UUID: @Sendable (Value) -> Void] = [:]
    
    nonisolated public init(_ value: Value) {
        self.value = value
    }
    
    public func get() -> Value { 
        value 
    }
    
    public func set(_ newValue: Value) {
        let oldValue = value
        value = newValue
        
        if !areEqual(oldValue, newValue) {
            let currentObservers = observers
            Task { @MainActor in
                for observer in currentObservers.values {
                    observer(newValue)
                }
            }
        }
    }
    
    public nonisolated func binding() -> Binding<Value> {
        Binding(
            get: { @MainActor in self.value },
            set: { @MainActor newValue in self.set(newValue) }
        )
    }
    
    public func observe(_ observer: @escaping @Sendable (Value) -> Void) -> UUID {
        let id = UUID()
        observers[id] = observer
        return id
    }
    
    public func removeObserver(id: UUID) {
        observers.removeValue(forKey: id)
    }
    
    public func removeAllObservers() {
        observers.removeAll()
    }
    
    private func areEqual(_ lhs: Value, _ rhs: Value) -> Bool {

        if let lhs = lhs as? any Equatable,
           let rhs = rhs as? any Equatable {
            return areEquatable(lhs, rhs)
        }
        return false
    }
    
    private func areEquatable(_ lhs: any Equatable, _ rhs: any Equatable) -> Bool {
        guard type(of: lhs) == type(of: rhs) else { return false }
        
        func isEqual<T: Equatable>(_ lhs: T, _ rhs: any Equatable) -> Bool {
            (rhs as? T).map { $0 == lhs } ?? false
        }
        
        return isEqual(lhs, rhs)
    }
}

@propertyWrapper
@MainActor
public final class State<Value: Sendable>: Sendable {
    private let observableState: ObservableState<Value>
    
    public var wrappedValue: Value {
        get { observableState.get() }
        set { observableState.set(newValue) }
    }
    
    public var projectedValue: Binding<Value> {
        observableState.binding()
    }
    
    nonisolated public init(wrappedValue: Value) {
        self.observableState = ObservableState(wrappedValue)
    }
    

    public func observe(_ observer: @escaping @Sendable (Value) -> Void) -> UUID {
        observableState.observe(observer)
    }
    

    public func removeObserver(id: UUID) {
        observableState.removeObserver(id: id)
    }
}

@MainActor
public protocol ObservableObject: AnyObject, Sendable {

    func objectWillChange()
}

public extension ObservableObject {
    func objectWillChange() {

    }
}