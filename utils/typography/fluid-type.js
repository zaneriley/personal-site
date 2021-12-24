import pxToRem from "../px-to-rem";
import { BREAKPOINTS, TYPEUNITS } from "../css-variables";

export default function getFluidType(
  minSize,
  maxSize,
  units,
  minScreen,
  maxScreen
) {
  // eslint-disable-next-line no-param-reassign
  if (!minSize) minSize = TYPEUNITS.bodyFont.small;
  // eslint-disable-next-line no-param-reassign
  if (!maxSize) maxSize = TYPEUNITS.bodyFont.larger;
  if (!units) {
    // eslint-disable-next-line no-param-reassign
    units = "rem";
    // eslint-disable-next-line no-param-reassign
    minScreen = pxToRem(BREAKPOINTS.medium);
    // eslint-disable-next-line no-param-reassign
    maxScreen = pxToRem(BREAKPOINTS.larger);
  } else {
    // eslint-disable-next-line no-param-reassign
    units = "px";
    // eslint-disable-next-line no-param-reassign
    minScreen = BREAKPOINTS.medium;
    // eslint-disable-next-line no-param-reassign
    maxScreen = BREAKPOINTS.larger;
  }

  return `
    calc(${minSize}${units} + (${maxSize} - ${minSize}) * ((100vw - ${minScreen}${units}) / (${maxScreen} - ${minScreen})))
  `;
}
