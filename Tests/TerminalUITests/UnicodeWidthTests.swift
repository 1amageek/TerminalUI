import Testing
import Foundation
@testable import TerminalUI

@Test("ASCII character width")
func testASCIIWidth() {
    #expect(CharacterWidth.width(of: "A") == 1)
    #expect(CharacterWidth.width(of: " ") == 1)
    #expect(CharacterWidth.width(of: "1") == 1)
    #expect(CharacterWidth.width(of: "!") == 1)
}

@Test("Japanese character width")
func testJapaneseWidth() {
    // Hiragana
    #expect(CharacterWidth.width(of: "あ") == 2)
    #expect(CharacterWidth.width(of: "ん") == 2)
    
    // Katakana
    #expect(CharacterWidth.width(of: "ア") == 2)
    #expect(CharacterWidth.width(of: "ン") == 2)
    
    // Kanji
    #expect(CharacterWidth.width(of: "漢") == 2)
    #expect(CharacterWidth.width(of: "字") == 2)
}

@Test("Emoji width")
func testEmojiWidth() {
    #expect(CharacterWidth.width(of: "😀") == 2)
    #expect(CharacterWidth.width(of: "🌍") == 2)
    #expect(CharacterWidth.width(of: "👍") == 2)
}

@Test("Combining characters")
func testCombiningCharacters() {
    // Combining diacritical marks should have width 0
    let aWithAccent: Character = "\u{0061}\u{0301}" // a + combining acute accent
    #expect(CharacterWidth.width(of: aWithAccent) == 1) // Base character width only
}

@Test("String width calculation")
func testStringWidth() {
    #expect(CharacterWidth.cellWidth(of: "Hello") == 5)
    #expect(CharacterWidth.cellWidth(of: "こんにちは") == 10) // 5 characters × 2 width
    #expect(CharacterWidth.cellWidth(of: "Hello世界") == 9) // 5 + 2×2
    #expect(CharacterWidth.cellWidth(of: "👨‍👩‍👧‍👦") == 2) // Family emoji (single grapheme cluster)
}

@Test("Substring fitting width")
func testSubstringFitting() {
    let (result1, remaining1) = CharacterWidth.substring("Hello", fitting: 3)
    #expect(result1 == "Hel")
    #expect(remaining1 == 0)
    
    let (result2, remaining2) = CharacterWidth.substring("こんにちは", fitting: 6)
    #expect(result2 == "こんに") // 3 characters × 2 width = 6
    #expect(remaining2 == 0)
    
    let (result3, remaining3) = CharacterWidth.substring("Hello世界", fitting: 7)
    #expect(result3 == "Hello世") // 5 + 2 = 7
    #expect(remaining3 == 0)
}

@Test("String padding")
func testStringPadding() {
    #expect("Hello".padded(to: 10) == "Hello     ")
    #expect("Hello".padded(to: 10).terminalWidth == 10)
    
    #expect("こんにちは".padded(to: 15) == "こんにちは     ")
    #expect("こんにちは".padded(to: 15).terminalWidth == 15)
}

@Test("String truncation")
func testStringTruncation() {
    #expect("Hello".truncated(to: 10) == "Hello")
    #expect("Hello World".truncated(to: 8) == "Hello...")
    #expect("こんにちは世界".truncated(to: 10) == "こんに...")
}

@Test("Fullwidth and halfwidth forms")
func testFullwidthHalfwidth() {
    // Fullwidth forms
    #expect(CharacterWidth.width(of: "Ａ") == 2) // Fullwidth A
    #expect(CharacterWidth.width(of: "１") == 2) // Fullwidth 1
    
    // Halfwidth katakana
    #expect(CharacterWidth.width(of: "ｱ") == 1) // Halfwidth ア
    #expect(CharacterWidth.width(of: "ｶ") == 1) // Halfwidth カ
}

@Test("Mixed content width")
func testMixedContent() {
    let mixed = "Status: 完了"
    let width = CharacterWidth.cellWidth(of: mixed)
    #expect(width == 12) // "Status: " (8) + "完了" (4)
    
    // Test checkmark separately as its width can vary
    let checkWidth = CharacterWidth.width(of: "✓")
    #expect(checkWidth >= 1 && checkWidth <= 2) // Can be 1 or 2 depending on font
}

@Test("Zero-width characters")
func testZeroWidthCharacters() {
    // Standalone ZWJ typically shows as nothing or a placeholder
    // But when it's part of an emoji sequence, it has special handling
    let zwj = "\u{200D}"
    // ZWJ alone might display as 2 cells in some terminals (as a placeholder)
    let zwjWidth = CharacterWidth.cellWidth(of: zwj)
    #expect(zwjWidth == 0 || zwjWidth == 2) // Can vary by terminal
    
    // Variation selector should be zero width
    let vs16 = "\u{FE0F}"
    #expect(CharacterWidth.cellWidth(of: vs16) == 0)
}