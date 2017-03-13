import React, { PropTypes } from 'react';
import cx from 'classnames';
import s from './Gallery.css';


function GalleryItem() {
  return(
    <img src srcSet="" alt="" />
  );
}

class Gallery extends React.Component {

  static propTypes = {
    className: PropTypes.string,
  };

  render() {

    const { className, children, image } = this.props;

    return ( 

      <div className={cx(className) + ``}>

        {images.map((image, index) => (
            <GalleryItem key={index}> {children} </GalleryItem>
        ))}

      </div>
    );
  }
  
}
export default Gallery;