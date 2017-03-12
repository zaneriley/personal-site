import React, { PropTypes } from 'react';
import cx from 'classnames';
import IconClock from '../IconClock';
import Button from '../Button';
import ReactCSSTransitionGroup from 'react-addons-css-transition-group';
import g from '../../src/styles/grid.css';
import v from '../../src/styles/aesthetics.css';

class About extends React.Component {

  static propTypes = {
    className: PropTypes.string,
    title: PropTypes.string,
    about: PropTypes.string,
    role: PropTypes.string,
    result: PropTypes.string,
    readingLength: PropTypes.string,
  };

  render() {
    const { title, about, role, result } = this.props;
    
    const readingLength = this.props.readingLength || '3 Minute Read'

    return (
      <ReactCSSTransitionGroup
        component="div"
        className={`${g.maxWidth}`}
        transitionName={ {
          enter: v.enter,
          enterActive: v.enterActive,
          leave: v.leave,
          leaveActive: v.leaveActive,
          appear: v.appear,
          appearActive: v.appearActive
        } }
        transitionAppear={true}
        transitionAppearTimeout={300}
        transitionEnterTimeout={300}
        transitionLeaveTimeout={300}
      >

        <h1 dangerouslySetInnerHTML={{__html: title}} key={1}/>

        <div className={`${g.gFlexContainer}`} key={2}>
          <div className={` ${g.g12m} ${g.g6l} `}>
            <h2>Project</h2>
            <p>{about}</p>
          </div>

          <div className={` ${g.g6m} ${g.g3l} ${g.gMarginLeftL} ${g.gNoMarginTopL}`} key={3}>
            <h2>Role</h2>
            <p>{role}</p>
          </div>

          <div className={` ${g.g6m} ${g.g3l} ${g.gMarginLeftM} ${g.gNoMarginTopL}`} key={4}>
            <h2>Results</h2>
            <p dangerouslySetInnerHTML={{__html: result}}></p>
          </div>
        </div>
  
        <div>
          <span><IconClock /> {readingLength}</span> <button className={` ${g.gMarginLeftSmall} ${g.gNoMarginTop}`} href="#">View Gallery</button>
        </div>

        </ReactCSSTransitionGroup>
    );
  }
  
}
export default About;