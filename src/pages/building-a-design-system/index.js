import React from 'react';
import Layout from '../../../components/Layout';
import About from '../../../components/About';
import Code from '../../../components/Code';
import s from './styles.css';
import g from '../../styles/grid.css';
import v from '../../styles/aesthetics.css';
import { title, html } from './index.md';

class BuildingADesignSystem extends React.Component {

  componentDidMount() {
    document.title = title;
  }

  render() {
    return (
      <Layout className={s.content}>

        <About title={title} about="Build a design system for Brit + Co's media site, classroom platform and internal dashboards in order to improve communication, maintainability, and consistency." role="Led the creation of our design system – visual design, documentation, and code." result="<strong>Reduced CSS file size by 33%.</strong> Improved communication, increased velocity."/>

        <div className={`${g.maxWidth} ${g.gMarginTopLarge}`}>

          <p className={`${g.g6l} ${g.center} ${v.dropCap}`}>The Brit + Co design system is a collection of reusable design patterns and visual styles. These help us create a better product by allowing us to focus on higher-level thinking.</p>

          <p className={`${g.g6l} ${g.center}`}>Projects often revolve around integral user interface elements. As these elements popped up the product team would standardized them. Instead of stopping other projects so we could build our design system in one go, we built new patterns on a per-project basis.
          </p>

          <h2 className={`${g.g6l} ${g.center}`}>Defining What's Needed</h2>

          <p className={`${g.g6l} ${g.center}`}>Brit + Co has a diverse set of design needs. User behavior often varies between articles and classes. People browse articles while casually surfing social media. On the other hand, when taking online classes, they are much more focused and task-driven.</p>

          <p className={`${g.g6l} ${g.center}`}>To solve for these design needs, I performed an audit to look for patterns across the site.</p>

          <h3 className={`${g.g6l} ${g.center}`}>Example: Patterns in Typography</h3>
          <p className={`${g.g6l} ${g.center}`}>To quote iA.net, <a href="https://ia.net/topics/the-web-is-all-about-typography-period/" target="_blank">“Web Design is 95% Typography”</a>, so it isn’t a surprise that so much of our design system is typography related.</p>

          <p className={`${g.g6l} ${g.center}`}>Throughout the audit, I noticed there were 17 different font-sizes (50 if you count unique values in the CSS). All were hardcoded pixel values.</p>

          <p className={`${g.g6l} ${g.center}`}>I then chose an appropriate <a href="http://www.modularscale.com/?18&px&1.2&web&text" target="_blank">modular scale</a>. Each font-size was simply multiplied by 1.2 to get the next size increase.</p>

          <p className={`${g.g6l} ${g.center}`}>Thus we reduced the site to just seven type sizes:</p>

          <p className={`${g.g6l} ${g.center}`}>We applied this same approach with the grid, buttons, and other patterns. Now we just needed to simplify how we communicated without using verbose, time-intensive spec documents.</p>

          <h2 className={`${g.g6l} ${g.center}`}>Building a Shared Language</h2>

          <p className={`${g.g6l} ${g.center}`}>Using a combination of SCSS mixins and Sketch symbols, we created a shared language to help designers and engineers communicate with less documentation.</p>

          <p className={`${g.g6l} ${g.center}`}>In code, you simply include type sizes like so:
          </p>

          <Code language="CSS" className={`${g.g8l} ${g.center}`}>
<span><span className="token selector">{`.header-large`} </span><span className="token punctuation">{`{`}</span></span>
  <span><span className="token keyword">{`  @include`}</span> <span className="token function"> typography</span><span className="token punctuation">{`(`}</span>xxx-large<span className="token punctuation">{`)`}</span><span className="token punctuation">{`;`}</span></span>
<span><span className="token punctuation">{`{`}</span></span>
          </Code>

          <p className={`${g.g6l} ${g.center}`}>When designing, you’d simply choose a text style with the same name.</p>

          <p className={`${g.g6l} ${g.center}`}>This shared language compounds as design patterns get more complex:</p>

          <Code language="YAML" className={`${g.g8l} ${g.center}`}>
<span><span className="token key atrule">PropertyUnits</span><span className="token punctuation">:</span></span>
<span><span className="token key atrule">  global</span><span className="token punctuation">:</span> <span className="token punctuation">{`[`}</span><span className="token string">'em'</span><span className="token punctuation">,</span> <span className="token string">'rem'</span><span className="token punctuation">,</span> <span className="token string">'%'</span><span className="token punctuation">,</span> <span className="token string">'vw'</span><span className="token punctuation">,</span> <span className="token string">'vh'</span><span className="token punctuation">,</span> <span className="token string">'vmin'</span><span className="token punctuation">,</span> <span className="token string">'vmax'</span><span className="token punctuation">{`]`}</span></span>
<span><span className="token key atrule">  properties</span><span className="token punctuation">:</span></span>
<span><span className="token key atrule">    color</span><span className="token punctuation">:</span>       <span className="token punctuation">{`      [`}</span><span className="token punctuation">{`]`}</span> // color(primary<span className="token punctuation">,</span> lighter);</span>
<span><span className="token key atrule">    font-size</span><span className="token punctuation">:</span>   <span className="token punctuation">{`  [`}</span><span className="token punctuation">{`]`}</span> // typography(large);</span>
<span><span className="token key atrule">    margin-top</span><span className="token punctuation">:</span>  <span className="token punctuation">{` [`}</span><span className="token punctuation">{`]`}</span> // spacing(large)</span>
          </Code>
        </div>
      </Layout>
    );
  }

}

export default BuildingADesignSystem;
