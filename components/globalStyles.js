import { createGlobalStyle } from "styled-components";
import pxToRem from "../utils/px-to-rem";
import { BREAKPOINTS, TYPEUNITS, COLORS } from "../utils/css-variables";
import getModularScale from "../utils/typography/modular-scale";
import getFluidType from "../utils/typography/fluid-type";

const BASE_LINE_UNIT = pxToRem(TYPEUNITS.bodyFont.lineHeight);

const GlobalStyle = createGlobalStyle`
  @font-face {
    font-family: 'GT Flexa';
    src: url('fonts/GT-Flexa-Standard-Regular.woff2') format('woff2');
    font-weight: 400;
    font-style: normal;
  }
  @font-face {
    font-family: 'GT Flexa Extended';
    src: url('fonts/GT-Flexa-Extended-Medium.woff2') format('woff2');
    font-weight: 800;
    font-style: normal;
  }
  @font-face {
    font-family: 'GT Flexa Condensed';
    src: url('fonts/GT-Flexa-Extended-Medium.woff2') format('woff2');
    font-weight: 800;
    font-style: normal;
  }
  @font-face {
    font-family: 'Cheee';
    src: url('fonts/Cheee-Small.woff2') format('woff2');
    font-weight: 800;
    font-style: normal;
  }
  @font-face {
    font-family: 'Temairaire';
    src: url('fonts/Temeraire-Italic.woff2') format('woff2');
    font-weight: 400;
    font-style: normal;
  }

  :root {
    --font-body-small:        ${pxToRem(TYPEUNITS.bodyFont.small)}rem;
    --font-body-large:        ${pxToRem(TYPEUNITS.bodyFont.large)}rem;
    --font-family-fallback:   -apple-system, system-ui, blinkmacsystemfont, 'Segoe UI', 'Roboto', 'Oxygen', 'Ubuntu', 'Cantarell', 'Fira Sans';
    --font-family-serif:      'Temairaire', 'Georgia', 'Times New Roman';
    --font-family-sans:       'GT Flexa Regular', 'Helvetica Neue', Helvetica, Arial, sans-serif;
    --font-family-mono:       'Cheee', Apercu, 'Fira Mono', Courier, monospace;
    --font-weight-bold:       800;
  
    --color-neutral-lightest: ${COLORS.neutral.lightest};
    --color-neutral-lighter:  ${COLORS.neutral.lighter};
    --color-neutral-light:    ${COLORS.neutral.light};
    --color-neutral-base:     ${COLORS.neutral.base};
    --color-neutral-dark:     ${COLORS.neutral.dark};
    --color-neutral-darker:   ${COLORS.neutral.darker};
    --color-neutral-darkest:  ${COLORS.neutral.darkest};

    --color-primary-light:    ${COLORS.primary.light};
    --color-primary-base:     ${COLORS.primary.base};

    --color-success-base:     ${COLORS.success.base};

    --color-accent-lighter:   ${COLORS.accent.lighter};
    --color-accent-light:     ${COLORS.accent.light};
    --color-accent-base:      ${COLORS.accent.base};
    --color-accent-dark:      ${COLORS.accent.dark};
    --border-radius-base:     4px;
    --letter-spacing:         0.05em;
    --spacing-smallest: ${BASE_LINE_UNIT / 8}rem;
    --spacing-smaller:  ${BASE_LINE_UNIT / 4}rem;
    --spacing-small:    ${BASE_LINE_UNIT / 2}rem;
    --spacing-base:     ${BASE_LINE_UNIT}rem;
    --spacing-large:    ${getModularScale("spacing", "small", 1)}rem;
    --spacing-larger:   ${getModularScale("spacing", "small", 2)}rem;
    --column-gap-small: var(--spacing-smaller);
    --column-gap-base:  var(--spacing-small);
    --max-width-prose: calc(593px + var(--column-gap-base) * 2);
    --z-bottom: -1;
    --z-base: 0;
    --z-top: 1;
  }
  @media screen and (min-width: ${BREAKPOINTS.medium}px) {
    :root {
      --spacing-base:   ${getFluidType(
        getModularScale("spacing", "small", 0),
        getModularScale("spacing", "large", 0)
      )};
      --spacing-large:  ${getFluidType(
        getModularScale("spacing", "small", 1),
        getModularScale("spacing", "large", 1)
      )};
      --spacing-larger: ${getFluidType(
        getModularScale("spacing", "small", 2),
        getModularScale("spacing", "large", 2)
      )};
      --column-gap-small: var(--spacing-base);
      --column-gap-base:  var(--spacing-large);
    }
  }

  @media screen and (min-width: ${BREAKPOINTS.large}px) {
    :root {
      --spacing-base:   ${getModularScale("spacing", "large", 0)}rem;
      --spacing-large:  ${getModularScale("spacing", "large", 1)}rem;
      --spacing-larger: ${getModularScale("spacing", "large", 2)}rem;
    }
  }

  * {
    margin: 0;
    box-sizing: border-box;
  }

  p + p {
    margin-top: var(--spacing-base);
  }

  *:focus {
    outline: 4px solid #00defd;
  }

  html,
  body {
    width: 100%;
    min-height: 100vh;
    margin: 0;
  }

  html {
    font-size: 100%;
    font-kerning: normal;
    -webkit-font-smoothing: antialiased;
  }

  body {
    font-family: var(--font-family-fallback);
  }

  *::selection {
    background-color: #fff3e2;
  }

  .wfLoadedGTFlexa {
    font-family: var(--font-family-flexa);
  }
`;

export default GlobalStyle;
