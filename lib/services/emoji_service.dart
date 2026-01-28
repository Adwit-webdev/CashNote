class EmojiService {
  static String addEmoji(String text) {
    String lower = text.toLowerCase();
    if (lower.contains('milk')) return '🥛 $text';
    if (lower.contains('bread')) return '🍞 $text';
    if (lower.contains('egg')) return '🥚 $text';
    if (lower.contains('coffee')) return '☕ $text';
    if (lower.contains('pizza')) return '🍕 $text';
    if (lower.contains('burger')) return '🍔 $text';
    if (lower.contains('fruit')) return '🍎 $text';
    if (lower.contains('veg')) return '🥦 $text';
    if (lower.contains('cake')) return '🍰 $text';
    if (lower.contains('water')) return '💧 $text';
    if (lower.contains('gym')) return '💪 $text';
    if (lower.contains('work')) return '💼 $text';
    if (lower.contains('study')) return '📚 $text';
    if (lower.contains('code')) return '💻 $text';
    return text; 
  }
}