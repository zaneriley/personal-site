/* Requires fontSize in REM */
import pxToRem from "../px-to-rem.js";

const variables = require("../css-variables.js");

export default function getLineHeight(fontSize) {
  const baseFontSize = variables.TYPEUNITS.bodyFont.small;
  const baseLineHeight = variables.TYPEUNITS.bodyFont.lineHeight;

  // @parameters "quarter" or "half"
  const roundToNearestLine = "quarter";
  const minLinePadding = 1;

  const fontSizeInPx = fontSize * 16;

  let line = baseLineHeight - fontSizeInPx;

  /* @TODO Figure out line-height so it mathematically resembles sketch files */
  if (line <= 0.5) {
  } else if (line * baseLineHeight - baseFontSize < minLinePadding * 2) {
    if (roundToNearestLine === "quarter") {
      line += 0.25;
    } else if (roundToNearestLine === "half") {
      line += 0.5;
    } else {
      line += 1;
    }
  }

  const length = line * baseLineHeight;
  const rhythmLength = Math.round(length) / fontSizeInPx;
  const rhythmLengthRounded = Math.floor(rhythmLength * 100) / 1000;

  return rhythmLengthRounded;
}
