import styled from "styled-components";
import { BREAKPOINTS } from "../utils/css-variables";

export const Grid = styled.div`
  display: grid;
  grid-template-columns: repeat(12, 1fr);
  column-gap: var(--column-gap-base);
  ${(props: { prose: boolean; }) => (props.prose ? `max-width: var(--max-width-prose);` : ``)};
  padding: 0 var(--column-gap-base);
  margin-top: var(--spacing-larger);
  margin-right: auto;
  margin-left: auto;
  margin-bottom: var(--spacing-larger);
  width: 100%;
  margin-top: var(--spacing-large);
  }
  @media screen and (min-width: ${BREAKPOINTS.medium}px) {
    margin-top: var(--spacing-large);
    margin-bottom: var(--spacing-large);
  }
`;
