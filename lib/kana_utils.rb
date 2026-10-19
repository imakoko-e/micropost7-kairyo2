# frozen_string_literal: true
# 清音処理モジュール
#
# 目的:
#   - Excel VBA で作った「FNC清音処理」「FNC清音処理と連結」を Ruby で再現する
#   - ひらがな/カタカナ/半角カナを正規化し、濁点・半濁点を取り除いた「清音キー」を作る
#   - 半角⇔全角の完全一致はしないが、検索キー/ソートキーとして十分に実用的
# ポイント:
#   1) NFKC 正規化で「全角化 + 半角カナの全角化 + 記号の統一」
#   2) ひらがな→カタカナ
#   3) VBAの cst小 / cst大 による「拗音・促音・横棒・丸記号」等を大きい文字へ置換
#   4) NFD 分解後、結合文字の濁点(U+3099)・半濁点(U+309A)を削除して清音化
#   5) 半角スペースを除去（VBAの Replace(Chr(32), "") 相当）
#
# 使っている所: db/seeds.rb（サンプルデータの name_kana_seion を作る）

module KanaUtils
  module_function       # KanaUtils.seion(...) の形で呼べるようにする

  # VBA の cst小 / cst大 と同じ対応表（同じ位置の文字どうしを1対1で置き換える）
  C_SMALL = "ヂズァィゥェォッャュョー―‐ー～◯〇".freeze
  C_LARGE = "ジヅアイウエオツヤユヨ－－－－－○○".freeze
  C_SMALL_TO_LARGE = C_SMALL.chars.zip(C_LARGE.chars).to_h.freeze

  # ひらがな→カタカナ 変換（Unicodeレンジを tr でシンプルに）
  # ぁ(3041)~ゖ(3096) → ァ(30A1)~ヶ(30F6)
  def hiragana_to_katakana(str)
    return "" if str.nil? || str.empty?
    str.tr("ぁ-ゖ", "ァ-ヶ")
  end

  # cst小 → cst大 の1文字置換
  def small_to_large(str)
    str.each_char.map { |ch| C_SMALL_TO_LARGE.fetch(ch, ch) }.join
  end

  # 清音化のメイン処理（VBAの FNC清音処理 相当）
  # - 入力: 任意の日本語文字列
  # - 出力: 清音化済みの「検索キー」文字列（カタカナ主体、スペースなし）
  def seion(str_org)
    return "" if str_org.nil? || str_org.empty?

    # (A) NFKC 正規化で幅や互換文字をそろえる
    #     半角ｶﾅ → 全角カナ、全角英数字・全角スペース → 半角
    s = str_org.unicode_normalize(:nfkc)

    # (B) ひらがな→カタカナ
    s = hiragana_to_katakana(s)

    # (C) cst小 → cst大（拗音・促音・長音・○の統一）
    s = small_to_large(s)

    # (D) NFD で分解し、結合文字の濁点 U+3099・半濁点 U+309A を取り除いて清音にする。英字は小文字にする
    s = s.unicode_normalize(:nfd).gsub(/\u3099|\u309A/, "").unicode_normalize(:nfc).downcase

    # (E) 半角スペース除去（VBAの Replace(Chr(32), "") 相当）
    s.delete(" ")
  end

  # 清音化 + 連結（VBAの FNC清音処理と連結 相当）
  # 両方に値がある時のみ半角スペースで連結。なければ詰める。
  def seion_concat(str1, str2)
    a = seion(str1)
    b = seion(str2)
    if !a.empty? && !b.empty?
      "#{a} #{b}"
    else
      "#{a}#{b}"
    end
  end
end

