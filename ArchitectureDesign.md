# TerminalUI アーキテクチャ改善設計書

## 概要
本設計書は、TerminalUIプロジェクトにおけるSendability問題を根本的に解決し、Swift 6の並行性要件に完全準拠するための包括的な設計を提示します。

## 現状の問題分析

### 根本原因
1. **型システムの不整合**: SwiftUIのAPIを模倣しているが、Swift 6のSendability要件を考慮していない
2. **状態管理の曖昧さ**: BindingやStateの実装が並行アクセスを考慮していない
3. **同期プリミティブの不統一**: Mutex、Actor、クラスが混在し、一貫性がない
4. **型消去の過度な使用**: Any型やAnyKeyPathの使用によるSendability違反

## 提案する新アーキテクチャ

### 1. レイヤード・アーキテクチャ

```
┌─────────────────────────────────────┐
│         Application Layer           │
│    (ConsoleSession, Console)        │
├─────────────────────────────────────┤
│         View Layer                  │
│  (ConsoleView, ForEach, Binding)   │
├─────────────────────────────────────┤
│       State Management Layer        │
│  (ObservableState, PropertyStore)   │
├─────────────────────────────────────┤
│        Rendering Layer              │
│  (RenderingPipeline, Renderers)    │
├─────────────────────────────────────┤
│       Platform Abstraction          │
│    (TTYManager, FileHandle)        │
└─────────────────────────────────────┘
```

### 2. 核心的な設計変更

#### 2.1 SendableKeyPathシステム

```swift
// 新しいSendableKeyPathラッパー
public struct SendableKeyPath<Root, Value>: Sendable {
    private let id: String
    private let getter: @Sendable (Root) -> Value
    private let setter: (@Sendable (inout Root, Value) -> Void)?
    
    public init<K: KeyPath<Root, Value>>(_ keyPath: K) where Root: Sendable, Value: Sendable {
        self.id = String(describing: keyPath)
        self.getter = { root in root[keyPath: keyPath] }
        self.setter = nil
    }
    
    public init<K: WritableKeyPath<Root, Value>>(_ keyPath: K) where Root: Sendable, Value: Sendable {
        self.id = String(describing: keyPath)
        self.getter = { root in root[keyPath: keyPath] }
        self.setter = { root, value in root[keyPath: keyPath] = value }
    }
}
```

#### 2.2 改善されたBindingシステム

```swift
// Actor-basedの状態管理
@MainActor
public final class ObservableState<Value: Sendable>: @unchecked Sendable {
    private var value: Value
    private var observers: [(Value) -> Void] = []
    
    public init(_ value: Value) {
        self.value = value
    }
    
    public func get() -> Value { value }
    
    public func set(_ newValue: Value) {
        value = newValue
        observers.forEach { $0(newValue) }
    }
    
    public func binding() -> Binding<Value> {
        Binding(
            get: { [weak self] in self?.value ?? value },
            set: { [weak self] in self?.set($0) }
        )
    }
}

// 改善されたBinding
public struct Binding<Value: Sendable>: Sendable {
    private let getter: @Sendable () -> Value
    private let setter: @Sendable (Value) -> Void
    
    public init(
        get: @escaping @Sendable () -> Value,
        set: @escaping @Sendable (Value) -> Void
    ) {
        self.getter = get
        self.setter = set
    }
}
```

#### 2.3 型安全なプロパティコンテナ

```swift
// 型安全でSendableなプロパティコンテナ
public struct PropertyContainer: Sendable {
    private let storage: [String: any Sendable]
    
    public init(_ properties: [String: any Sendable] = [:]) {
        self.storage = properties
    }
    
    public func get<T: Sendable>(_ key: String, as type: T.Type) -> T? {
        storage[key] as? T
    }
    
    public func with<T: Sendable>(_ key: String, value: T) -> PropertyContainer {
        var newStorage = storage
        newStorage[key] = value
        return PropertyContainer(newStorage)
    }
}
```

### 3. ForEachの再設計

```swift
public struct ForEach<Data, ID, Content>: ConsoleView 
where Data: RandomAccessCollection & Sendable, 
      ID: Hashable & Sendable, 
      Content: ConsoleView {
    
    private let data: Data
    private let identifier: Identifier<Data.Element, ID>
    private let content: @Sendable (Data.Element) -> Content
    
    // 識別子の抽象化
    private enum Identifier<Element, ID: Hashable>: Sendable {
        case keyPath(SendableKeyPath<Element, ID>)
        case function(@Sendable (Element) -> ID)
        case identity // Element自体がIDの場合
    }
    
    // KeyPath版（SendableKeyPathを使用）
    public init(
        _ data: Data,
        id: SendableKeyPath<Data.Element, ID>,
        @ConsoleBuilder content: @escaping @Sendable (Data.Element) -> Content
    ) {
        self.data = data
        self.identifier = .keyPath(id)
        self.content = content
    }
    
    // Identifiable版
    public init(
        _ data: Data,
        @ConsoleBuilder content: @escaping @Sendable (Data.Element) -> Content
    ) where Data.Element: Identifiable, ID == Data.Element.ID {
        self.data = data
        self.identifier = .function { $0.id }
        self.content = content
    }
}
```

### 4. Effectsシステムの再設計

```swift
// プロトコルベースのEffectシステム
public protocol Effect: Sendable {
    associatedtype Configuration: Sendable
    func apply(to node: Node, config: Configuration) async -> AnimationHandle
}

// Actor-basedアニメーションマネージャー
public actor AnimationManager {
    private var activeAnimations: [AnimationID: AnimationState] = [:]
    
    public func animate<E: Effect>(
        effect: E,
        on node: Node,
        config: E.Configuration
    ) async -> AnimationHandle {
        let handle = await effect.apply(to: node, config: config)
        let id = AnimationID()
        activeAnimations[id] = AnimationState(handle: handle)
        return handle
    }
}
```

### 5. TTYManagerのActor化

```swift
public actor TTYManager {
    private let input: FileHandle
    private let output: FileHandle
    private var originalTermios: termios?
    
    public init(input: FileHandle, output: FileHandle) {
        self.input = input
        self.output = output
    }
    
    public func enableRawMode() async throws {
        #if os(macOS) || os(Linux)
        var termios = Darwin.termios()
        if tcgetattr(input.fileDescriptor, &termios) != 0 {
            throw TTYError.failedToGetAttributes
        }
        originalTermios = termios
        
        // Raw mode設定
        termios.c_lflag &= ~(UInt(ECHO | ICANON | ISIG | IEXTEN))
        termios.c_iflag &= ~(UInt(IXON | ICRNL | BRKINT | INPCK | ISTRIP))
        termios.c_cflag |= UInt(CS8)
        termios.c_oflag &= ~UInt(OPOST)
        
        // Apply settings
        if tcsetattr(input.fileDescriptor, TCSAFLUSH, &termios) != 0 {
            throw TTYError.failedToSetAttributes
        }
        #endif
    }
}
```

## 実装計画

### フェーズ1: 基盤整備（1-2週間）
1. SendableKeyPathシステムの実装
2. 新しいBinding/ObservableStateシステムの実装
3. PropertyContainerの実装
4. 基本的なユニットテストの作成

### フェーズ2: コア機能の移行（2-3週間）
1. ForEachの新実装への移行
2. 既存のView componentsの更新
3. Effectsシステムのプロトコルベース化
4. TTYManagerのActor化

### フェーズ3: 統合とテスト（1-2週間）
1. レンダリングパイプラインの統合
2. セッション管理の改善
3. 包括的なテストスイートの作成
4. パフォーマンステスト

### フェーズ4: 既存コードの移行（1週間）
1. 非推奨警告の追加
2. マイグレーションガイドの作成
3. サンプルコードの更新

## 互換性戦略

### 後方互換性の維持
```swift
// 既存APIの維持（非推奨マーク付き）
@available(*, deprecated, renamed: "ForEach.init(_:id:content:)")
public extension ForEach {
    init(legacyData: Data, legacyId: KeyPath<Data.Element, ID>, content: @escaping (Data.Element) -> Content) {
        // 内部で新APIに変換
    }
}
```

### 段階的移行サポート
```swift
// 移行ヘルパー
public enum Migration {
    public static func convertKeyPath<Root, Value>(_ keyPath: KeyPath<Root, Value>) -> SendableKeyPath<Root, Value> 
    where Root: Sendable, Value: Sendable {
        SendableKeyPath(keyPath)
    }
}
```

## リスク管理

### 技術的リスク
1. **パフォーマンス劣化**: Actor使用によるオーバーヘッド
   - 対策: クリティカルパスのプロファイリングと最適化

2. **API破壊的変更**: 既存コードの非互換性
   - 対策: 段階的非推奨と移行期間の設定

3. **複雑性の増加**: 新しい抽象化レイヤー
   - 対策: 明確なドキュメントとサンプル提供

## 成功指標

1. **コンパイル成功率**: 100%のSendability準拠
2. **テストカバレッジ**: 90%以上
3. **パフォーマンス**: 既存実装と同等以上
4. **API互換性**: 80%の既存APIが動作継続

## まとめ

この設計により、TerminalUIは以下を実現します：

- ✅ Swift 6完全準拠
- ✅ 型安全性の向上
- ✅ 並行処理の安全性
- ✅ SwiftUIとの高い互換性
- ✅ 将来の拡張性

付け焼き刃ではない、根本的な改善により、TerminalUIは現代的で堅牢なライブラリとして進化します。