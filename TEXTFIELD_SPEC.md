# TextField 仕様書 - 日本語IME対応

## 概要
TerminalUIにおける日本語入力対応TextFieldコンポーネントの詳細仕様。
端末の制約を考慮し、**確実に動く既定動作**と**対応端末でのリッチ機能**の二段構えで実装。

---

## 設計原則

1. **既定はシステムIME**: 多くの端末で動作する「確定文字列のみ受け取る」方式
2. **プログレッシブエンハンスメント**: 対応端末では自動的にリッチ機能を有効化
3. **Unicode完全対応**: 絵文字、結合文字、全角文字を正しく扱う
4. **非侵襲的**: TerminalUIの他コンポーネントと同じ設計思想を維持

---

## API仕様

### TextField本体

```swift
public struct TextField: ConsoleView {
    public init(
        _ label: String? = nil,
        text: Binding<String>,
        config: Config = .init()
    )
    
    // モディファイア
    public func onChange(_ f: @Sendable @escaping (String) -> Void) -> Self
    public func onSubmit(_ when: SubmitTrigger = .enter, 
                        _ f: @Sendable @escaping (String) -> Void) -> Self
    public func focused(_ isFocused: Binding<Bool>) -> Self
    public func placeholder(_ s: String) -> Self
    public func secure(_ flag: Bool = true) -> Self
}
```

### 設定構造体

```swift
public struct Config: Sendable {
    public var placeholder: String? = nil
    public var secure: Bool = false
    public var singleLine: Bool = true
    public var maxLength: Int? = nil
    public var imeMode: IMEMode = .system
    public var validate: ((String) -> ValidationResult)? = nil
    public var transformOnCommit: ((String) -> String)? = nil
    public var selectionEnabled: Bool = false  // 将来拡張
}

public enum IMEMode: Sendable {
    case system              // 端末/OSのIMEオーバーレイ（既定）
    case inlineExperimental  // kitty/wezterm等でのインライン表示
}

public enum ValidationResult: Sendable {
    case ok
    case warning(String)
    case error(String)
}
```

---

## 実装詳細

### Phase 4.5: Input Foundation

#### ファイル構成
```
Sources/TerminalUI/
├── Input/
│   ├── UnicodeWidth.swift       # 文字幅計算
│   ├── EditorState.swift        # 編集状態管理
│   ├── KeyDecoder.swift         # キー入力デコード
│   ├── BracketedPaste.swift     # ペースト検出
│   └── Binding.swift            # 軽量バインディング
```

#### UnicodeWidth.swift
```swift
public enum CharacterWidth {
    public static func width(of character: Character) -> Int {
        // UAX #11 East_Asian_Width + 結合文字対応
        // 0: 結合文字（濁点、VS16等）
        // 1: 半角（ASCII、半角カナ等）
        // 2: 全角（漢字、ひらがな、全角記号、絵文字等）
    }
    
    public static func cellWidth(of string: String) -> Int {
        string.reduce(0) { $0 + width(of: $1) }
    }
    
    public static func substring(
        _ string: String, 
        fitting width: Int
    ) -> (String, remainingWidth: Int)
}
```

#### EditorState.swift
```swift
public struct EditorState: Sendable {
    private var text: String
    private var caretIndex: String.Index  // Character境界
    private var displayOffset: Int        // 表示開始セル位置
    
    // 編集操作
    public mutating func insert(_ string: String)
    public mutating func deleteBackward()
    public mutating func deleteForward()
    public mutating func moveLeft()
    public mutating func moveRight()
    public mutating func moveWordLeft()
    public mutating func moveWordRight()
    public mutating func moveToBeginning()
    public mutating func moveToEnd()
    
    // 表示計算
    public func visibleText(width: Int) -> String
    public func caretColumn(width: Int) -> Int
    public mutating func scrollIfNeeded(width: Int)
}
```

#### KeyDecoder.swift
```swift
public enum KeyEvent: Sendable {
    case character(Character)
    case control(ControlKey)
    case ime(IMEEvent)
    case paste(String)
    
    public enum ControlKey {
        case left, right, up, down
        case home, end
        case backspace, delete
        case enter, tab, escape
        case pageUp, pageDown
        case withModifier(ControlKey, Modifier)
    }
    
    public enum IMEEvent {
        case compositionStart
        case compositionUpdate(String)
        case compositionCommit(String)
        case compositionCancel
    }
}

public struct KeyDecoder {
    public func decode(_ bytes: [UInt8]) -> KeyEvent? {
        // CSI/SS3シーケンス解析
        // Bracketed Paste検出
        // kitty keyboard protocol対応（実験的）
    }
}
```

### Phase 5.5: TextField Component

#### ファイル構成
```
Sources/TerminalUI/
├── Components/Input/
│   ├── TextField.swift          # メインコンポーネント
│   ├── TextFieldNode.swift      # ノード実装
│   ├── TextFieldRenderer.swift  # 描画ロジック
│   ├── IMEAdapter.swift         # IME統合
│   ├── Validation.swift         # 検証表示
│   └── TextArea.swift           # 複数行版（将来）
```

#### TextField描画仕様

```swift
// ノード構造
Node(kind: .textfield, props: [
    "text": text,
    "placeholder": placeholder,
    "caretColumn": caretColumn,
    "focused": isFocused,
    "validation": validationResult,
    "secure": isSecure,
    "width": availableWidth,
    "preedit": preeditText  // IME未確定文字（実験的）
])

// レンダリング例（通常）
┌─ ユーザー名 ─────────────┐
│ 山田 太郎|               │  // |はカーソル
└──────────────────────────┘

// レンダリング例（IME inline実験モード）
┌─ コメント ───────────────┐
│ こんにちは、[せかい]     │  // []は未確定文字
└──────────────────────────┘

// レンダリング例（エラー）
┌─ パスワード ─────────────┐
│ ●●●●●●●                  │
└──────────────────────────┘
⚠️ 8文字以上入力してください
```

---

## 端末互換性マトリクス

| 機能 | Terminal.app | iTerm2 | VSCode | kitty | wezterm | Linux TTY |
|------|-------------|---------|---------|-------|---------|-----------|
| 基本入力 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| 日本語入力（確定） | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Bracketed Paste | ✅ | ✅ | ✅ | ✅ | ✅ | ⚠️ |
| IME Inline | ❌ | ❌ | ❌ | 🧪 | 🧪 | ❌ |
| 拡張キー | ⚠️ | ⚠️ | ✅ | ✅ | ✅ | ❌ |

凡例: ✅完全対応 ⚠️部分対応 🧪実験的 ❌非対応

---

## テスト計画

### ゴールデンテスト
```swift
// Tests/TerminalUITests/TextFieldTests.swift
@Test func japaneseInput() {
    // 入力: "こんにちは世界🌍"
    // 期待幅: 2+2+2+2+2+2+2 = 14セル
}

@Test func combinedCharacters() {
    // 入力: "が" (か + 濁点) vs "が" (単一文字)
    // 両方とも幅2として処理
}

@Test func emojiVariants() {
    // 入力: "👨‍👩‍👧‍👦" (ZWJ sequence)
    // 単一Characterとして扱い、幅2
}

@Test func mixedWidthScroll() {
    // 入力: "Hello世界ABC"
    // 狭い幅でのスクロール動作
}
```

### インテグレーションテスト
- macOS Terminal.appでの実機テスト
- Docker内Linuxでの自動テスト
- CI環境（GitHub Actions）での動作確認

---

## パフォーマンス目標

- 文字入力レスポンス: < 16ms（60fps）
- IME確定処理: < 50ms
- 1000文字のテキストで差分描画: < 10ms
- メモリ使用量: < 1MB per TextField

---

## セキュリティ考慮事項

1. **パスワード入力**: secure モードで内部値も定期的にクリア
2. **IME経由の入力**: サニタイズ不要（Swiftの文字列は安全）
3. **ペースト**: 制御文字の適切なフィルタリング
4. **トレーシング**: secure フィールドの値はイベントに含めない

---

## 将来の拡張

- **TextArea**: 複数行エディタ（スクロール、行番号）
- **Autocomplete**: 候補表示（ポップアップ or インライン）
- **Syntax Highlight**: コード入力用の色付け
- **Selection**: マウス/タッチパッドでの範囲選択
- **Undo/Redo**: 編集履歴の管理