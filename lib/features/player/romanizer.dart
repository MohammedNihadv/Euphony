/// Pure Dart lightweight romanizer for Korean Hangul and Japanese Kana.
///
/// Enables users to read and sing along with K-Pop, J-Pop, and Anime songs.
class Romanizer {
  static const _cho = [
    'g', 'kk', 'n', 'd', 'tt', 'r', 'm', 'b', 'bb',
    's', 'ss', '', 'j', 'jj', 'ch', 'k', 't', 'p', 'h'
  ];

  static const _jung = [
    'a', 'ae', 'ya', 'yae', 'eo', 'e', 'yeo', 'ye', 'o',
    'wa', 'wae', 'oe', 'yo', 'u', 'wo', 'we', 'wi',
    'yu', 'eu', 'ui', 'i'
  ];

  static const _jong = [
    '', 'k', 'k', 'ks', 'n', 'nj', 'nh', 't', 'l', 'lg',
    'lm', 'lb', 'ls', 'lt', 'lp', 'lh', 'm', 'p', 'ps',
    's', 'ss', 'ng', 'j', 'ch', 'k', 't', 'p', 'h'
  ];

  static const Map<String, String> _kanaMap = {
    'あ': 'a', 'い': 'i', 'う': 'u', 'え': 'e', 'お': 'o',
    'か': 'ka', 'き': 'ki', 'く': 'ku', 'け': 'ke', 'こ': 'ko',
    'さ': 'sa', 'し': 'shi', 'す': 'su', 'せ': 'se', 'そ': 'so',
    'た': 'ta', 'ち': 'chi', 'つ': 'tsu', 'て': 'te', 'と': 'to',
    'な': 'na', 'に': 'ni', 'ぬ': 'nu', 'ね': 'ne', 'の': 'no',
    'は': 'ha', 'ひ': 'hi', 'ふ': 'fu', 'へ': 'he', 'ほ': 'ho',
    'ま': 'ma', 'み': 'mi', 'む': 'mu', 'め': 'me', 'も': 'mo',
    'や': 'ya', 'ゆ': 'yu', 'よ': 'yo',
    'ら': 'ra', 'り': 'ri', 'る': 'ru', 'れ': 're', 'ろ': 'ro',
    'わ': 'wa', 'を': 'wo', 'ん': 'n',
    'が': 'ga', 'ぎ': 'gi', 'ぐ': 'gu', 'げ': 'ge', 'ご': 'go',
    'ざ': 'za', 'じ': 'ji', 'ず': 'zu', 'ぜ': 'ze', 'ぞ': 'zo',
    'だ': 'da', 'ぢ': 'ji', 'づ': 'zu', 'で': 'de', 'ど': 'do',
    'ば': 'ba', 'び': 'bi', 'ぶ': 'bu', 'べ': 'be', 'ぼ': 'bo',
    'ぱ': 'pa', 'ぴ': 'pi', 'ぷ': 'pu', 'ぺ': 'pe', 'ぽ': 'po',
    'きゃ': 'kya', 'きゅ': 'kyu', 'きょ': 'kyo',
    'しゃ': 'sha', 'しゅ': 'shu', 'しょ': 'sho',
    'ちゃ': 'cha', 'ちゅ': 'chu', 'ちょ': 'cho',
    'にゃ': 'nya', 'にゅ': 'nyu', 'にょ': 'nyo',
    'ひゃ': 'hya', 'ひゅ': 'hyu', 'ひょ': 'hyo',
    'みゃ': 'mya', 'みゅ': 'myu', 'みょ': 'myo',
    'りゃ': 'rya', 'りゅ': 'ryu', 'りょ': 'ryo',
    'ぎゃ': 'gya', 'ぎゅ': 'gyu', 'ぎょ': 'gyo',
    'じゃ': 'ja', 'じゅ': 'ju', 'じょ': 'jo',
    'びゃ': 'bya', 'びゅ': 'byu', 'びょ': 'byo',
    'ぴゃ': 'pya', 'ぴゅ': 'pyu', 'ぴょ': 'pyo',
    // Katakana
    'ア': 'a', 'イ': 'i', 'ウ': 'u', 'エ': 'e', 'オ': 'o',
    'カ': 'ka', 'キ': 'ki', 'ク': 'ku', 'ケ': 'ke', 'コ': 'ko',
    'サ': 'sa', 'シ': 'shi', 'ス': 'su', 'セ': 'se', 'ソ': 'so',
    'タ': 'ta', 'チ': 'chi', 'ツ': 'tsu', 'テ': 'te', 'ト': 'to',
    'ナ': 'na', 'ニ': 'ni', 'ヌ': 'nu', 'ネ': 'ne', 'ノ': 'no',
    'ハ': 'ha', 'ヒ': 'hi', 'フ': 'fu', 'ヘ': 'he', 'ホ': 'ho',
    'マ': 'ma', 'ミ': 'mi', 'ム': 'mu', 'メ': 'me', 'モ': 'mo',
    'ヤ': 'ya', 'ユ': 'yu', 'ヨ': 'yo',
    'ラ': 'ra', 'リ': 'ri', 'ル': 'ru', 'レ': 're', 'ロ': 'ro',
    'ワ': 'wa', 'ヲ': 'wo', 'ン': 'n',
    'ガ': 'ga', 'ギ': 'gi', 'グ': 'gu', 'ゲ': 'ge', 'ゴ': 'go',
    'ザ': 'za', 'ジ': 'ji', 'ズ': 'zu', 'ゼ': 'ze', 'ゾ': 'zo',
    'ダ': 'da', 'ヂ': 'ji', 'ヅ': 'zu', 'デ': 'de', 'ド': 'do',
    'バ': 'ba', 'ビ': 'bi', 'ブ': 'bu', 'ベ': 'be', 'ボ': 'bo',
    'パ': 'pa', 'ピ': 'pi', 'プ': 'pu', 'ペ': 'pe', 'ポ': 'po',
    'キャ': 'kya', 'キュ': 'kyu', 'キョ': 'kyo',
    'シャ': 'sha', 'シュ': 'shu', 'ショ': 'sho',
    'チャ': 'cha', 'チュ': 'chu', 'チョ': 'cho',
    'ニャ': 'nya', 'ニュ': 'nyu', 'ニョ': 'nyo',
    'ヒャ': 'hya', 'ヒュ': 'hyu', 'ヒョ': 'hyo',
    'ミャ': 'mya', 'ミュ': 'myu', 'ミョ': 'myo',
    'リャ': 'rya', 'リュ': 'ryu', 'リョ': 'ryo',
    'ギャ': 'gya', 'ギュ': 'gyu', 'ギョ': 'gyo',
    'ジャ': 'ja', 'ジュ': 'ju', 'ジョ': 'jo',
    'ビャ': 'bya', 'ビュ': 'byu', 'ビョ': 'byo',
    'ピャ': 'pya', 'ピュ': 'pyu', 'ピョ': 'pyo',
    'ー': '-',
  };

  /// Returns true if the text contains Asian characters (Korean or Japanese Kana).
  static bool hasAsianScript(String text) {
    for (final char in text.runes) {
      if ((char >= 0x3040 && char <= 0x30FF) ||
          (char >= 0xAC00 && char <= 0xD7A3)) {
        return true;
      }
    }
    return false;
  }

  /// Converts Korean Hangul and Japanese Kana to Latin phonetic Romaji.
  static String romanize(String text) {
    if (!hasAsianScript(text)) return text;

    final runes = text.runes.toList();
    final sb = StringBuffer();

    var i = 0;
    while (i < runes.length) {
      final char = runes[i];

      // 1. Korean Hangul
      if (char >= 0xAC00 && char <= 0xD7A3) {
        final code = char - 0xAC00;
        final c = code ~/ (21 * 28);
        final j = (code % (21 * 28)) ~/ 28;
        final o = code % 28;
        sb.write('${_cho[c]}${_jung[j]}${_jong[o]}');
        i++;
        continue;
      }

      // 2. Japanese double-character kana (e.g. きゃ, キャ)
      if (i + 1 < runes.length) {
        final twoChar = String.fromCharCodes([char, runes[i + 1]]);
        if (_kanaMap.containsKey(twoChar)) {
          sb.write(_kanaMap[twoChar]);
          i += 2;
          continue;
        }
      }

      // Sokuon (small tsu っ / ッ) doubles next consonant
      if (char == 0x3063 || char == 0x30C3) {
        if (i + 1 < runes.length) {
          final nextChar = String.fromCharCode(runes[i + 1]);
          final nextRomaji = _kanaMap[nextChar] ?? '';
          if (nextRomaji.isNotEmpty) {
            sb.write(nextRomaji[0]);
            i++;
            continue;
          }
        }
      }

      // Single kana
      final singleChar = String.fromCharCode(char);
      if (_kanaMap.containsKey(singleChar)) {
        sb.write(_kanaMap[singleChar]);
        i++;
        continue;
      }

      // Default (Latin, numbers, punctuation, Kanji, etc.)
      sb.writeCharCode(char);
      i++;
    }

    return sb.toString();
  }
}

