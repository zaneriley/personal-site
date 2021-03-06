import React, { PropTypes } from 'react';
import cx from 'classnames';
import Link from '../Link';
import s from './Logo.css';


class Logo extends React.Component {

  static propTypes = {
    className: PropTypes.string,
  };

  render() {
    const { className } = this.props;

    return (
      <Link to="/" className={cx(s.logo, className) + ``} aria-label="Zane Riley, Product Designer">
        <svg width="100%" height="100%" version="1.1" x="0" y="0" viewBox="0 0 337.2 351.8" enableBackground="new 0 0 337.2 351.8">
          <path id="Logo" fill="#008EFE" d="M18.2 69.2 326.7 264.8c-7.3-7.3-15.6-9.5-25.5-10.5 -45.8-4.7-133.8-2.5-151.2-0.5 11.8-18.1 120.2-147.3 150.9-190C312 53.6 317.6 35.4 312 21.2c-4-10.4-13.5-18.5-24.3-21C269-4 111.4 61.5 57.3 75.6c-3.3 0.9-6.5 1.8-9.6 2.8l0.1 0.2c-15.4 5-26.5 18.6-26.5 34.6 0 20.3 17.8 36.7 39.7 36.7 1.4 0 2.7-0.1 4-0.2 0 0 10.2-2 15.2-4.2 10.8-4.6 108.5-41.9 108.5-41.9S21 259.2 1.5 309.3c-3.3 8.6-0.8 20.1 3.6 27.7 16.7 28.6 40.6 8.2 63.7 0.4 43-14.5 87-16 131.9-16.2 33.5-0.1 67.1 1.6 100.4 5 9 0.9 19.3-4.4 25.5-10.5 6.7-6.7 10.5-15.9 10.5-25.5C337.2 280.7 333.4 271.5 326.7 264.8z"/>
        </svg>
      </Link>
    );
  }
  
}
export default Logo;