---
title: "Test note. Emoji: 🚀 Numbers: 0123456789 Japanese: こんにちは世界 Arabic: مرحبا بالعالم ！＂＃＄％＆＇（）＊＋，－．／０１２３４５６７８９：；＜＝＞？＠ＡＢＣＤＥＦＧＨＩＪＫＬＭＮＯＰＱ｀ａｂｃｄｅｆｇｈｉｊｋｌｍｎｏｐｑｒｓｔｕｖｗｘｙｚ｛｜｝～ WOOHOO!"
url: "testing-note"
content: "This is the main content of the note."
introduction: "This is a comprehensive test note to ensure proper rendering and parsing of various Markdown elements in the context of a note content type."
read_time: 10
file_path: "priv/content/note/en/testing-note.md"
locale: "en"
published_at: "2024-07-27T14:30:00Z"
is_draft: false
---


# Heading Level 1

## Heading Level 2

### Heading Level 3

#### Heading Level 4

*Emphasis* and **bold** are correctly applied. _How about combinations?_

1. Ordered List Item
2. Another Item
   * Nested unordered item

* Unordered List Item
* Another Item

1. Ordered List Item
   1.  A nested ordered item
2. Another Item
   * Nested unordered item
      * Deeper nesting
   * More nesting  

* Unordered List Item
      * Unordered with lots of indentation
* Another Item


This is an inline link: [Example Website](https://www.example.com/)

This is a reference link [Example Website 2][example-ref] with a title.

[example-ref]: https://www.example.com/ "Website Title"

![Image Alt Text](path/to/your/image.jpg)

> This is a blockquote. 
> It could span multiple lines.

Inline code: `let x = 10;`

```c
#include <stdio.h>

int main() {
    printf("Hello, world!\n");
    return 0;
}
```

Markdown table test:

| Header 1 | Header 2 | Header 3 |
| -------- | -------- | -------- |
| Cell 1   | Cell 2   | Cell 3   |
| Cell 4   | Cell 5   | Cell 6   |

Character escape test:

\*Emphasis\* and \**bold\** are correctly applied. \*How about combinations?\*
And \`code\` is also correctly applied.

Let's not forget special characters: < > & © ¡™£¢∞§¶•ªº–≠

Stress testing:
```c
#include <stdio.h>

int main() {
    printf("Hello, world!\n"); 
    // Will this comment with **bold** break?
    return 0;
}
```