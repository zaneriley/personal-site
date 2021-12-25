import React from "react";
import styled from "styled-components";
import {
  BREAKPOINTS,
  TYPEUNITS,
  TYPESTYLES,
  TYPEFACES,
  COLORS
} from "../utils/css-variables";

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
  ${TYPESTYLES.largest};
`;

const Larger = styled.h2`
  display: flex;
  width: 100%;
  justify-content: ${props => (props.center ? "center" : "")};
  text-align: ${props => (props.center ? "center" : "")};
  ${TYPESTYLES.larger};
`;

const Large = styled.h3`
  display: flex;
  width: 100%;
  justify-content: ${props => (props.center ? "center" : "")};
  text-align: ${props => (props.center ? "center" : "")};
  ${TYPESTYLES.large};
`;

const LargeLabel = styled.label`
  display: flex;
  width: 100%;
  justify-content: ${props => (props.center ? "center" : "")};
  text-align: ${props => (props.center ? "center" : "")};
  ${TYPESTYLES.large};
`;

const Default = styled.p`
  display: flex;
  width: 100%;
  justify-content: ${props => (props.center ? "center" : "")};
  text-align: ${props => (props.center ? "center" : "")};
  ${TYPESTYLES.base};

  ${props =>
    props.large
      ? `
    ${TYPESTYLES.large};
    font-weight: normal;
  `
      : ``};

  ${props => (props.inline ? `--line-height: var(--line-height-normal);` : ``)};

  color: ${props => (props.color ? props.color : ``)};
`;

const DefaultList = styled.li`
  display: flex;
  flex-direction: column;
  width: 100%;
  justify-content: ${props => (props.center ? "center" : "")};
  text-align: ${props => (props.center ? "center" : "")};
  ${TYPESTYLES.base};

  & + & {
    margin-top: var(--spacing-base);
  }
`;

const Small = styled.h4`
  display: flex;
  width: 100%;
  justify-content: ${props => (props.center ? "center" : "")};
  text-align: ${props => (props.center ? "center" : "")};
  ${TYPESTYLES.small};

  color: ${props => (props.color ? props.color : ``)};
`;

export const H1 = ({ center, children, id }) => (
  <Largest center={center} id={id}>
    <OpticalAdjustment>{children}</OpticalAdjustment>
  </Largest>
);

export const H2 = ({ center, children, id, font }) => (
  <Larger center={center} id={id} font={font}>
    <OpticalAdjustment>{children}</OpticalAdjustment>
  </Larger>
);

export const H3 = ({ center, children, id }) => (
  <Large center={center} id={id}>
    <OpticalAdjustment>{children}</OpticalAdjustment>
  </Large>
);

export const P = ({ center, children, id, large, color, inline }) => (
  <Default center={center} id={id} large={large} color={color} inline={inline}>
    <OpticalAdjustment>{children}</OpticalAdjustment>
  </Default>
);

export const H4 = ({ center, children, id, color }) => (
  <Small center={center} id={id} color={color}>
    <OpticalAdjustment>{children}</OpticalAdjustment>
  </Small>
);

export const Li = ({ center, children, id }) => (
  <DefaultList>
    <OpticalAdjustment>{children}</OpticalAdjustment>
  </DefaultList>
);
export const NoWrap = styled.span`
  white-space: nowrap;
`;

