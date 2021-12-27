import React from "react";
import styled from "styled-components";
import {
  BREAKPOINTS,
  TYPEUNITS,
  TYPESTYLES,
  TYPEFACES,
  COLORS
} from "../utils/css-variables";
import getFontSize from "../utils/typography/font-size";

/* prettier-ignore */
export const OpticalAdjustment = styled.span`
  margin-top: calc((var(--computedLineHeight) - var(--fontSize)) / 2 * -1 - (var(--distanceTop) / 2 * 1em));
  margin-bottom: calc((var(--computedLineHeight) - var(--fontSize)) / 2 * -1 - (var(--distanceBottom) / 2 * 1em));
  z-index: 0;
`;

const Largest = styled.h1`
  display: flex;
  width: 100%;
  justify-content: ${props => (props.center ? "center" : "")};
  text-align: ${props => (props.center ? "center" : "")};
`;

const Default = styled.p`
  display: flex;
  width: 100%;
  justify-content: ${props => (props.center ? "center" : "")};
  text-align: ${props => (props.center ? "center" : "")};

  ${props => (props.inline ? `--line-height: var(--line-height-normal);` : ``)};

  color: ${props => (props.color ? props.color : ``)};

  ${TYPESTYLES.base}
`;

export const Cheee = styled.span`
  ${TYPESTYLES.small}
  font-size: inherit;
`;

export const H1 = ({ center, children, color, element, id, inline, size, typeface }) => (
  <Largest center={center} id={id}>
    <OpticalAdjustment>{children}</OpticalAdjustment>
  </Largest>
);

export const P = ({ center, children, color, element, id, inline, size, typeface }) => (
  <Default 
    typeface={typeface} 
    center={center} 
    id={id} 
    size={size} 
    color={color} 
    inline={inline}>
      <OpticalAdjustment>{children}</OpticalAdjustment>
  </Default>
);

export const NoWrap = styled.span`
  white-space: nowrap;
`;

