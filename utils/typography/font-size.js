import pxToRem from "../px-to-rem";
import getModularScale from "./modular-scale";
import getLineHeight from "./line-height";
import getFluidType from "./fluid-type";
import { TYPEFACES, BREAKPOINTS } from "../css-variables";

export default function getFontSize(int, typeface) {
  if (!typeface) typeface = TYPEFACES.sourceSansPro;

  const CAPITAL_HEIGHT_SMALL = getModularScale(
    "typography",
    "small",
    int,
    "px"
  );
  const CAPITAL_HEIGHT_LARGE = getModularScale(
    "typography",
    "large",
    int,
    "px"
  );
  const CAPITAL_HEIGHT_FLUID = getFluidType(
    pxToRem(CAPITAL_HEIGHT_SMALL),
    pxToRem(CAPITAL_HEIGHT_LARGE)
  );

  /* compute font-size to get capital height equal desired font-size 
   * (e.g. 12 * 0.66 = 18)
   */
  const calculatedFontSize = capitalHeight =>
    capitalHeight / typeface.fmCapitalHeight;

  /* The font-size converted into REM. 
   * (18 / 16 * 1rem = 1.125rem)
   */
  const FONT_SIZE_SMALL = pxToRem(calculatedFontSize(CAPITAL_HEIGHT_SMALL));
  const FONT_SIZE_LARGE = pxToRem(calculatedFontSize(CAPITAL_HEIGHT_LARGE));
  const FONT_SIZE_FLUID = getFluidType(FONT_SIZE_SMALL, FONT_SIZE_LARGE);

  const DISTANCE_TOP = typeface.fmAscender - typeface.fmCapitalHeight;
  const DISTANCE_BOTTOM = typeface.fmDescender;

  return `   
    font-size: var(--fontSize);

    /* The specified line-height, but splits the 
     * line-height equally above and below the text. 
     */
    line-height: var(--computedLineHeight);

    /* Units for both this element and the element's inner span
     * to substract the invisible space caused by 
     * the line-height in a text container. 
     */
    --capitalHeight:  ${CAPITAL_HEIGHT_SMALL};
    --fontSize:       ${FONT_SIZE_SMALL}rem;
    --computedLineHeight: calc((var(--line-height) * var(--capitalHeight)) * 1px);
    --distanceBottom: ${DISTANCE_BOTTOM};
    --distanceTop:    ${DISTANCE_TOP};
    
    ${
      FONT_SIZE_SMALL >= 1
        ? `
    @media screen and (min-width: ${BREAKPOINTS.medium}px) {
      --fontSize: ${FONT_SIZE_FLUID};
      --capitalHeight: ${CAPITAL_HEIGHT_FLUID};
      --computedLineHeight: calc((var(--line-height) * var(--capitalHeight)) * 1);
    }

    @media screen and (min-width: ${BREAKPOINTS.larger}px) {
      --capitalHeight:  ${CAPITAL_HEIGHT_LARGE};
      --fontSize: ${FONT_SIZE_LARGE}rem;
      --computedLineHeight: calc((var(--line-height) * var(--capitalHeight)) * 1px);
    }`
        : ``
    }
  `;
}
