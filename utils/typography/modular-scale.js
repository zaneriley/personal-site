import pxToRem from "../px-to-rem";
import { TYPEUNITS } from "../css-variables";

/* PARAMETERS

 * typeOfScale: variable (typography || spacing)
 * sizeOfScale: variable (small || large)
 * direction:   integer  (-1, 0, 3)
 * unit:        string   ("px" || "rem")
 */
export default function getModularScale(
  typeOfScale,
  sizeOfScale,
  direction,
  unit
) {
  if (!typeOfScale) typeOfScale = "typography";
  if (!sizeOfScale) sizeOfScale = "small";
  if (!unit) unit = "rem";

  let modularSize = modularSize;
  let baseSize = baseSize;
  let scale = scale;

  if (typeOfScale === "typography") {
    if (sizeOfScale === "small") {
      baseSize = TYPEUNITS.bodyFont.small;
      scale = TYPEUNITS.typographyScale.small;
    } else {
      baseSize = TYPEUNITS.bodyFont.large;
      scale = TYPEUNITS.typographyScale.large;
    }
  } else if (typeOfScale === "spacing") {
    baseSize = TYPEUNITS.bodyFont.lineHeight;
    if (sizeOfScale === "small") {
      scale = TYPEUNITS.spacingScale.small;
    } else {
      scale = TYPEUNITS.spacingScale.large;
    }
  }

  if (direction < 0) {
    modularSize = baseSize / (scale * direction) * -1;
  } else if (direction === 0) {
    modularSize = baseSize;
  } else if (direction > 0) {
    modularSize = Math.pow(scale, direction) * baseSize;
  }

  const valueInPX = Math.round(modularSize);
  const valueInREM = pxToRem(valueInPX);

  if (unit === "px") {
    return valueInPX;
  }

  return valueInREM;
}
