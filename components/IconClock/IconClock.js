import React, { PropTypes } from 'react';
import cx from 'classnames';
import s from './IconClock.css'

class IconClock extends React.Component {

  static propTypes = {
    className: PropTypes.string,
  };


  render() {

    const d = new Date();
    const minutes = 6*d.getMinutes();
    const hours = 30*(d.getHours()%12);
    var minuteStyles = {
      transform: "rotate(" + minutes + "deg)",
      transformOrigin: "left bottom"
    }
    var hourStyles = {
      transform: "rotate(" + hours + "deg)",
      transformOrigin: "bottom center"
    }

    return (
  <svg version="1.1" width="23" height="22" xmlns="http://www.w3.org/2000/svg" className={`${s.icon} ${s.clock}`}>
  <title>Clock</title>
  <desc>
    Created with Sketch Beta.
  </desc>
  <g fill="none" fillRule="evenodd" id="archive" stroke="none" strokeWidth="1">
    <ellipse cx="13" cy="12" fill="#F7E0FC" id="Drop-Shadow" rx="10" ry="10"></ellipse>
    <path d="M10 19.3C15.1 19.3 19.3 15.1 19.3 10 19.3 4.9 15.1 0.7 10 0.7 4.9 0.7 0.7 4.9 0.7 10 0.7 15.1 4.9 19.3 10 19.3Z" id="Clock-Outline" stroke="#250E0E"></path>
    <path d="M10 10L10 3.8" id="Hour-Hand" stroke="#250E0E" strokeLinecap="square" style={hourStyles}></path>
    <path d="M16.2 10.8L10 10.8" id="Minute-Hand" stroke="#250E0E" strokeLinecap="square" style={minuteStyles}></path>
  </g>
  </svg>
    );
  }
  
}
export default IconClock;