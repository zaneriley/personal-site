// Read-only inventory of source and generated fonts. Does not regenerate fonts.

import { createHash } from "node:crypto";
import fs from "node:fs/promises";
import path from "node:path";
import * as fontkit from "fontkit";

const records = [];
for (const [stage, directory] of [
  ["source", "fonts/src"],
  ["generated", "static/fonts"],
]) {
  for (const file of await fs.readdir(directory)) {
    if (!/\.(ttf|otf|woff2?)$/i.test(file)) continue;
    const bytes = await fs.readFile(path.join(directory, file));
    const record = {
      stage,
      file,
      sha256: createHash("sha256").update(bytes).digest("hex"),
      bytes: bytes.length,
    };
    try {
      const font = fontkit.create(bytes);
      record.metrics = Object.fromEntries(
        [
          "familyName",
          "subfamilyName",
          "postscriptName",
          "unitsPerEm",
          "ascent",
          "descent",
          "lineGap",
          "capHeight",
          "xHeight",
          "numGlyphs",
          "variationAxes",
        ].map((key) => [key, font[key]]),
      );
      record.coverage = Object.fromEntries(
        ["HAMBURG", "gjpqy", "24°C−100°F", "東京", "「」、。"].map((text) => [
          text,
          [...text].every((char) =>
            font.hasGlyphForCodePoint(char.codePointAt(0)),
          ),
        ]),
      );
    } catch (error) {
      record.error = error.message;
    }
    records.push(record);
  }
}
const output = "../.tmp/typography-bench/font-audit.json";
await fs.mkdir(path.dirname(output), { recursive: true });
await fs.writeFile(
  output,
  JSON.stringify(
    {
      createdAt: new Date().toISOString(),
      method:
        "fontkit file metadata at default instance; browser confirmation required",
      records,
    },
    null,
    2,
  ),
);
console.log(
  `Inventoried ${records.length} font artifacts; ${records.filter((r) => r.error).length} extraction failures. ${output}`,
);
