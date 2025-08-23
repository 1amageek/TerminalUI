# TerminalUI 実装計画

## 概要
TerminalUIを10フェーズに分けて段階的に実装します。各フェーズは独立してテスト可能で、前のフェーズの成果物に依存します。

---

## Phase 1: Core Foundation (基盤システム)
**目標**: DSLとノードシステムの確立

### ファイル構成
```
Sources/TerminalUI/
├── Core/
│   ├── ConsoleView.swift        # プロトコルと基本DSL
│   ├── Node.swift               # ノード定義
│   ├── RenderContext.swift      # レンダリングコンテキスト
│   ├── ConsoleBuilder.swift     # @resultBuilder
│   ├── AnyCodable.swift        # 汎用Codable
│   └── Identifiable.swift      # NodeID生成
```

### 実装内容
- `ConsoleView` プロトコル
- `Node` / `NodeID` / `NodeKind` 
- `RenderContext` (幅、テーマ、capability情報を保持)
- `ConsoleBuilder` @resultBuilder
- `AnyCodable` for props storage
- 基本的なモディファイア拡張

### テスト
- Node生成が正しいか
- ConsoleBuilder の各buildメソッド
- IDの安定性

---

## Phase 2: Rendering Infrastructure (レンダリング基盤)
**目標**: ランタイムとレンダラーの実装

### ファイル構成
```
Sources/TerminalUI/
├── Runtime/
│   ├── TerminalRuntime.swift    # Actor本体
│   ├── DiffEngine.swift         # 差分計算
│   ├── LayoutEngine.swift       # レイアウト計算
│   └── RenderCommand.swift      # コマンド定義
├── Renderers/
│   ├── Renderer.swift           # プロトコル
│   ├── ANSIRenderer.swift       # TTY出力
│   ├── JSONRenderer.swift       # 構造化出力
│   └── Capabilities.swift       # 能力検出
├── Colors/
│   ├── ANSIColor.swift          # 色定義
│   ├── ColorFallback.swift      # 自動劣化
│   └── Theme.swift              # テーマ定義
```

### 実装内容
- `TerminalRuntime` actor
- 差分エンジン (前フレームとの比較)
- ANSI エスケープシーケンス生成
- 端末能力検出 (COLORTERM, TERM, NO_COLOR)
- 色の自動フォールバック
- 基本的なANSIRenderer (移動、色、消去)

### テスト
- ANSI出力の正確性
- 色のフォールバック
- 端末幅での折り返し

---

## Phase 3: Session Management (セッション管理)
**目標**: Tracing統合とセッションAPI

### ファイル構成
```
Sources/TerminalUI/
├── Session/
│   ├── Console.swift            # エントリポイント
│   ├── ConsoleSession.swift     # セッション管理
│   ├── SessionOptions.swift     # 設定
│   └── TracingIntegration.swift # span連携
```

### 実装内容
- `Console.start(on: span)` API
- ConsoleSession の render/log メソッド
- Span へのイベント送信
- Headless モード対応
- セッションライフサイクル管理

### 依存追加 (Package.swift)
```swift
dependencies: [
    .package(url: "https://github.com/apple/swift-distributed-tracing.git", from: "1.1.0")
]
```

### テスト
- Span との連携
- Headless モードでのイベント記録
- 複数セッションの並行実行

---

## Phase 4: Basic Components (基本コンポーネント)
**目標**: テキストとレイアウトの基本要素

### ファイル構成
```
Sources/TerminalUI/
├── Components/
│   ├── Text/
│   │   ├── Text.swift           # 基本テキスト
│   │   ├── Badge.swift          # バッジ
│   │   ├── Tag.swift            # タグ
│   │   └── Note.swift           # 通知メッセージ
│   ├── Layout/
│   │   ├── VStack.swift         # 垂直配置
│   │   ├── HStack.swift         # 水平配置
│   │   ├── Group.swift          # グループ化
│   │   ├── Panel.swift          # パネル
│   │   └── Divider.swift        # 区切り線
│   └── Modifiers/
│       ├── ColorModifier.swift  # 色設定
│       ├── StyleModifier.swift  # bold/italic等
│       └── LayoutModifier.swift # padding/border
```

### 実装内容
- Text with属性 (色、スタイル)
- VStack/HStack のレイアウトアルゴリズム
- Panel のボーダー描画
- モディファイアチェーン
- 基本的な整形とパディング

### テスト
- レイアウトの正確性
- ネストしたスタックの動作
- モディファイアの適用順序

---

## Phase 4.5: Input Foundation (入力基盤)
**目標**: TextField実装の前提となるUnicode処理とキー入力

### ファイル構成
```
Sources/TerminalUI/
├── Input/
│   ├── UnicodeWidth.swift       # 文字幅計算（UAX#11）
│   ├── EditorState.swift        # 編集状態管理
│   ├── KeyDecoder.swift         # キー入力デコード
│   ├── BracketedPaste.swift     # ペースト検出
│   └── Binding.swift            # 軽量バインディング
```

### 実装内容
- UAX #11 East_Asian_Width準拠の文字幅計算
- 結合文字・絵文字・ZWJシーケンス対応
- CSI/SS3エスケープシーケンス解析
- Bracketed Paste Mode対応
- 編集状態の管理とカーソル位置計算

### テスト
- 日本語・絵文字の幅計算
- 各種端末キーシーケンスのデコード
- 編集操作の正確性

---

## Phase 5: Live Updates (ライブ更新)
**目標**: プログレスバーとスピナー

### ファイル構成
```
Sources/TerminalUI/
├── Live/
│   ├── LiveHandle.swift         # ハンドルプロトコル
│   ├── ProgressHandle.swift     # 進捗ハンドル
│   ├── SpinnerHandle.swift      # スピナーハンドル
│   └── UpdateScheduler.swift    # FPS制御
├── Components/Progress/
│   ├── ProgressView.swift       # プログレスビュー
│   ├── Spinner.swift            # スピナー
│   ├── SpinnerStyles.swift      # dots/line/arc等
│   ├── Meter.swift              # メーター
│   └── Gauge.swift              # ゲージ
```

### 実装内容
- ProgressHandle の update() 実装
- SpinnerHandle のアニメーション
- FPS制限 (15fps上限)
- プログレスバーのレンダリング
- 事前定義スピナーパターン

### テスト
- 進捗更新の冪等性
- FPS制限の動作
- 完了時の状態遷移

---

## Phase 5.5: TextField Component (テキスト入力)
**目標**: 日本語IME対応のTextFieldコンポーネント

### ファイル構成
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

### 実装内容
- TextField DSL とバインディング
- システムIME（既定）とインラインIME（実験的）
- 検証とエラー表示
- セキュアモード（パスワード）
- 日本語・絵文字の正しい表示とカーソル位置
- Bracketed Pasteでの安全な貼り付け

### テスト
- 日本語入力の確定処理
- 文字幅とスクロールの整合性
- IMEモードの自動フォールバック
- 各種端末での互換性

---

## Phase 6: Visual Effects (視覚効果)
**目標**: Shimmer、Blink、Pulseエフェクト

### ファイル構成
```
Sources/TerminalUI/
├── Effects/
│   ├── Effect.swift             # エフェクトプロトコル
│   ├── Shimmer/
│   │   ├── ShimmerEffect.swift  # 実装
│   │   ├── ShimmerStyle.swift   # スタイル定義
│   │   └── HSVColor.swift       # HSV計算
│   ├── Blink/
│   │   ├── BlinkEffect.swift    # 実装
│   │   └── BlinkStyle.swift     # スタイル定義
│   └── Pulse/
│       ├── PulseEffect.swift    # 実装
│       └── PulseStyle.swift     # スタイル定義
```

### 実装内容
- Shimmer の位相計算アルゴリズム
- HSV → RGB 変換
- Blink の duty cycle 制御
- Pulse のサイズ/明度変調
- エフェクトのライフサイクル管理

### テスト
- エフェクトの視覚的検証
- パフォーマンス測定
- 停止条件の確認

---

## Phase 7: Data Components (データ表示)
**目標**: テーブル、リスト、ツリー表示

### ファイル構成
```
Sources/TerminalUI/
├── Components/Data/
│   ├── Table.swift              # テーブル
│   ├── List.swift               # リスト
│   ├── Tree.swift               # ツリー
│   ├── Grid.swift               # グリッド
│   ├── KeyValue.swift           # キー値ペア
│   └── Code.swift               # コード表示
```

### 実装内容
- Table の列幅計算
- Tree の折りたたみ状態管理
- Code のシンタックスハイライト (簡易)
- Grid のセル配置
- オーバーフロー時の省略表示

### テスト
- 大規模データでの性能
- 幅制約での表示
- ツリーの開閉動作

---

## Phase 8: Advanced Features (高度な機能)
**目標**: 画像、グラフ、高度なテーマ

### ファイル構成
```
Sources/TerminalUI/
├── Advanced/
│   ├── Image/
│   │   ├── Image.swift          # 画像表示
│   │   ├── SixelEncoder.swift   # Sixel形式
│   │   └── KittyProtocol.swift  # Kitty形式
│   ├── Charts/
│   │   └── Sparkline.swift      # スパークライン
│   └── Themes/
│       ├── ThemeManager.swift   # テーマ管理
│       └── PresetThemes.swift   # 事前定義テーマ
```

### 実装内容
- Sixel/Kitty プロトコル実装
- 画像のフォールバック (ASCII art)
- Sparkline の描画アルゴリズム
- カスタムテーマのロード
- ダークモード対応

### テスト
- 画像プロトコルの互換性
- グラフの精度
- テーマの切り替え

---

## Phase 9: Testing & Documentation (テスト・文書)
**目標**: 包括的なテストと使用例

### ファイル構成
```
Tests/TerminalUITests/
├── Golden/                      # ゴールデンテスト
├── Performance/                 # パフォーマンステスト
├── Integration/                 # 統合テスト
└── Examples/                    # 使用例

Examples/
├── BasicUsage/                  # 基本的な使い方
├── Dashboard/                   # ダッシュボード例
├── CLITool/                     # CLIツール例
└── TracingVisualization/        # トレース可視化例
```

### 実装内容
- Golden test suite
- パフォーマンスベンチマーク
- 実用的なサンプルアプリ
- API ドキュメント生成
- トラブルシューティングガイド

---

## Phase 10: SwiftAgent Adapter (SwiftAgent連携)
**目標**: 別モジュールでのSwiftAgent統合

### ファイル構成
```
Sources/TerminalUIAdapterSwiftAgent/
├── StepModifiers/
│   ├── SpanModifier.swift       # span追加
│   ├── RenderModifier.swift     # 描画追加
│   └── StatusModifier.swift     # ステータス表示
└── Extensions/
    └── Step+TerminalUI.swift    # Step拡張
```

### 実装内容
- StepModifier プロトコル実装
- Step 拡張メソッド
- 自動スピナー開始/終了
- エラー時の表示切り替え
- SwiftAgent との型安全な連携

### Package.swift 更新
```swift
products: [
    .library(name: "TerminalUI", targets: ["TerminalUI"]),
    .library(name: "TerminalUIAdapterSwiftAgent", 
             targets: ["TerminalUIAdapterSwiftAgent"])
]
```

---

## 実装順序の根拠

1. **Phase 1-3**: 基盤を固める。これがないと何も動かない
2. **Phase 4-5**: 実用最小限の機能。ここまでで基本的な使用が可能
3. **Phase 6-7**: 見た目と実用性の向上
4. **Phase 8**: Nice-to-have機能
5. **Phase 9**: 品質保証
6. **Phase 10**: 外部連携（独立性を保つため最後）

## 各フェーズの完了基準

- ✅ コンパイルが通る
- ✅ 単体テストがパス
- ✅ 基本的な使用例が動作
- ✅ パフォーマンス目標を満たす
- ✅ 次フェーズが開始可能

## リスクと対策

### リスク1: ANSI互換性
- 対策: 主要ターミナル (Terminal.app, iTerm2, VSCode, Linux) でテスト

### リスク2: パフォーマンス
- 対策: 早期にプロファイリング、FPS制限の厳守

### リスク3: Tracing統合の複雑さ
- 対策: Phase 3で早期に検証、必要なら簡略化

## 成功指標

- 宣言的な記述で美しいターミナルUIが作れる
- SwiftAgentから `.span { }.render { }` の簡潔な記法で使える
- パフォーマンスが良好（15fps以内、メモリ使用量が適切）
- トレーシングとの統合がシームレス