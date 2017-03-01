import React from 'react';
import recommendedPages from '../../relatedPages.json';
import Layout from '../../../components/Layout';
import Link from '../../../components/Link';
import LinkExternal from '../../../components/LinkExternal';
import About from '../../../components/About';
import IconChromeBar from '../../../components/IconChromeBar';
import HorizontalScroll from '../../../components/HorizontalScroll';
import Code from '../../../components/Code';
import g from '../../styles/grid.css';
import v from '../../styles/aesthetics.css';
import s from './styles.css';
import { title, html } from './index.md';

/* Images for this Page */
import styleguide from '../../assets/images/styleguide-1680w.png';
import SketchLapseWebm from '../../assets/images/sketch-time-lapse.webm';
import SketchLapseMp4 from '../../assets/images/sketch-time-lapse.mp4';
import scaleBefore from '../../assets/images/before-scale.svg';
import scaleAfter from '../../assets/images/after-scale.svg';

class BuildingADesignSystem extends React.Component {

  componentDidMount() {
    document.title = title;
  }

  render() {

    return (
      <Layout className={`${g.gPaddingTopLarge}`} breadCrumbs="Case Study" recommendedPageFirst={recommendedPages[2]} recommendedPageSecond={recommendedPages[3]}>

        <About title="Building a design system at Brit + Co." about="Built a design system for Brit + Co's media site, classroom platform and internal tools in order to improve communication, maintainability, and consistency." role="Led the creation of design system – visual design, code and documentation." result="<strong>Reduced <abbr title='cascading style sheets'>CSS</abbr> file size by 33%.</strong> Improved communication, increased velocity." readingLength="2 Minute Read"/>

        <figure className={`${g.maxWidth} ${g.gMarginTopLarge}`}>
          <div className={`${v.shadow1} ${v.borderRadiusTop}`}>
            <IconChromeBar />
            <video className={`${g.gNoMarginTop} ${g.center}`} autoPlay loop muted playsInline poster="http://placehold.it/20x20/">
              <source src={SketchLapseWebm} type="video/webm" />
              <source src={SketchLapseMp4} type="video/mp4" />
            </video>
          </div>
          <figcaption>Using the design system in Sketch</figcaption>
        </figure>

        <div className={`${g.maxWidth} ${g.gMarginTopLarge}`}>

          <p className={`${g.g6l} ${g.center} ${v.dropCap}`}>The Brit + Co design system is a collection of reusable design patterns and visual styles. These help us create a better product by allowing us to focus on higher-level thinking.</p>

          <p className={`${g.g6l} ${g.center}`}>Projects often revolve around integral user interface elements. As these elements popped up the product team would standardized them. Instead of stopping other projects so we could build our design system in one go, we built new patterns on a per-project basis.
          </p>
        </div>

        <figure className={`${g.maxWidth} ${g.gMarginTopLarge}`}>
          <div className={`${v.shadow1} ${v.borderRadiusTop}`}>
            <IconChromeBar />
            <img src={styleguide} className={`${g.gNoMarginTop} ${g.center}`} />
          </div>
          <figcaption>Online styleguide showing color palettes.</figcaption>
        </figure>

        <div className={`${g.maxWidth} ${g.gMarginTopLarge}`}>
          <h2 className={`${g.g6l} ${g.center}`}>Defining What's Needed</h2>

          <p className={`${g.g6l} ${g.center}`}>Brit + Co has a diverse set of design needs. User behavior often varies between articles and classes. People browse articles while casually surfing social media. On the other hand, when taking online classes, they are much more focused and task-driven.</p>

          <p className={`${g.g6l} ${g.center}`}>To solve for these design needs, I performed an audit to look for patterns across the site.</p>

          <h3 className={`${g.g6l} ${g.center}`}>Example: Patterns in Typography</h3>

          <p className={`${g.g6l} ${g.center}`}>To quote iA.net, <LinkExternal href="https://ia.net/topics/the-web-is-all-about-typography-period/">“Web Design is 95% Typography”</LinkExternal>, so it isn’t a surprise that so much of our design system is typography related.</p>

          <p className={`${g.g6l} ${g.center}`}>Throughout the audit, I noticed there were 17 different fontSizes (50 if you count unique values in the <abbr title='cascading style sheets'>CSS</abbr>). All were hardcoded pixel values.</p>

          <figure className={`${s.fontSizes} ${g.gJustifyCenter} ${g.gFlexEnd}`}>

            <div className={`${g.g6l}`}>
              <p style={{"fontSize" : "0.667em", "lineHeight" : "1.1rem"}}>Font-size 12px</p>
              <p style={{"fontSize" : "0.778em", "lineHeight" : "1.1rem"}}>Font-size 14px</p>
              <p style={{"fontSize" : "0.833em", "lineHeight" : "1.1rem"}}>Font-size 15px</p>
              <p style={{"fontSize" : "0.889em", "lineHeight" : "1.1rem"}}>Font-size 16px</p>
              <p style={{"fontSize" : "0.944em", "lineHeight" : "1.1rem"}}>Font-size 17px</p>
              <p style={{"fontSize" : "1em", "lineHeight" : "1.4rem"}}>Font-size 18px</p>
              <p style={{"fontSize" : "1.111em", "lineHeight" : "1.4rem"}}>Font-size 20px</p>
              <p style={{"fontSize" : "1.222em", "lineHeight" : "1.6rem"}}>Font-size 22px</p>
              <p style={{"fontSize" : "1.333em", "lineHeight" : "1.6rem"}}>Font-size 24px</p>
              <p style={{"fontSize" : "1.444em", "lineHeight" : "1.6rem"}}>Font-size 26px</p>
              <p style={{"fontSize" : "1.5em", "lineHeight" : "1.8rem"}}>Font-size 27px</p>
              <p style={{"fontSize" : "1.778em", "lineHeight" : "2rem"}}>Font-size 32px</p>
              <p style={{"fontSize" : "1.889em", "lineHeight" : "2rem"}}>Font-size 34px</p>
              <p style={{"fontSize" : "2.056em", "lineHeight" : "2rem"}}>Font-size 37px</p>
            </div>

          </figure>
        </div>

        <figure className={`${s.beforeScale}`}>
          <HorizontalScroll>
            <svg className={`${g.center}`} xmlns="http://www.w3.org/2000/svg" width="599" height="97" viewBox="0 7 599 97" version="1.1"><title>Previous font sizes.</title><desc>This image shows Brit + Co's existing font sizes laid out on a scale.</desc><g stroke="none" strokeWidth="1" fill="none" fillRule="evenodd"><path d="M0.3 59L597 59" stroke="#DCE8FA" strokeWidth="2" strokeLinecap="square"/><text fontFamily="inherit" fill="#202020"><tspan x="4.3" y="22">12</tspan></text><text fontFamily="inherit" fill="#202020"><tspan x="46.1" y="102">14</tspan></text><text fontFamily="inherit" fill="#202020"><tspan x="66" y="22">15</tspan></text><text fontFamily="inherit" fill="#202020"><tspan x="87.5" y="102">16</tspan></text><text fontFamily="inherit" fill="#202020"><tspan x="107.2" y="22">17</tspan></text><text fontFamily="inherit" fill="#202020"><tspan x="126.4" y="102">18</tspan></text><text fontFamily="inherit" fill="#202020"><tspan x="167.1" y="22">20</tspan></text><text fontFamily="inherit" fill="#202020"><tspan x="208.1" y="102">22</tspan></text><text fontFamily="inherit" fill="#202020"><tspan x="247.5" y="22">24</tspan></text><text fontFamily="inherit" fill="#202020"><tspan x="286.3" y="102">26</tspan></text><text fontFamily="inherit" fill="#202020"><tspan x="310.1" y="22">27</tspan></text><text fontFamily="inherit" fill="#202020"><tspan x="408.3" y="22">32</tspan></text><text fontFamily="inherit" fill="#202020"><tspan x="450.2" y="102">34</tspan></text><text fontFamily="inherit" fill="#202020"><tspan x="570.9" y="22">40</tspan></text><circle fill="#008EFE" cx="17" cy="58" r="6"/><circle fill="#008EFE" cx="57" cy="58" r="6"/><circle fill="#008EFE" cx="77" cy="58" r="6"/><circle fill="#008EFE" cx="98" cy="58" r="6"/><circle fill="#008EFE" cx="118" cy="58" r="6"/><circle fill="#008EFE" cx="138" cy="58" r="6"/><circle fill="#008EFE" cx="178" cy="58" r="6"/><circle fill="#008EFE" cx="219" cy="58" r="6"/><circle fill="#008EFE" cx="259" cy="58" r="6"/><circle fill="#008EFE" cx="299" cy="58" r="6"/><circle fill="#008EFE" cx="319" cy="58" r="6"/><circle fill="#008EFE" cx="420" cy="58" r="6"/><circle fill="#008EFE" cx="461" cy="58" r="6"/><circle fill="#008EFE" cx="583" cy="58" r="6"/></g></svg>
            </HorizontalScroll>
            <figcaption className={`${g.textCenter}`}>The number of existing font sizes <span className={`${g.noWrap}`}>on Brit + Co</span></figcaption>
        </figure>

        <div className={`${g.maxWidth} ${g.gMarginTopLarge}`}>

          <p className={`${g.g6l} ${g.center}`}>I then chose an appropriate <LinkExternal href="http://www.modularscale.com/?18&px&1.2&web&text">modular scale</LinkExternal>. Each fontSize was simply multiplied by 1.2 to get the next size increase.</p>

          <p className={`${g.g6l} ${g.center}`}>Thus we reduced the site to just seven <span className={`${g.noWrap}`}>type sizes:</span></p>

          <figure className={`${s.fontSizes} ${g.gJustifyCenter} ${g.gFlexEnd} ${g.gMarginTopLarge}`}>

            <div className={`${g.gMarginLeftL} ${g.g6l}`}>
              <p style={{"fontSize" : "12px", "lineHeight" : "1.1rem"}}>Font-size 12px</p>
              <p style={{"fontSize" : "15px", "lineHeight" : "1.1rem"}}>Font-size 15px</p>
              <p style={{"fontSize" : "18px", "lineHeight" : "1.4rem"}}>Font-size 18px</p>
              <p style={{"fontSize" : "22px", "lineHeight" : "1.6rem"}}>Font-size 22px</p>
              <p style={{"fontSize" : "26px", "lineHeight" : "1.6rem"}}>Font-size 26px</p>
              <p style={{"fontSize" : "32px", "lineHeight" : "2rem"}}>Font-size 31px</p>
              <p style={{"fontSize" : "37px", "lineHeight" : "2rem"}}>Font-size 37px</p>
            </div>
          </figure>
        </div>
            
        <figure className={`${s.afterScale}`}>
          <HorizontalScroll>
            <svg xmlns="http://www.w3.org/2000/svg" width="599" height="63" viewBox="0 6 599 63" version="1.1"><title>Font sizes using a modular scale</title><desc>This image shows Brit + Co's new font sizes laid out on a modular scale where each number is multipled by 1.2 to get the next fontSize.</desc><path d="M0.3 59L597 59" stroke="#DCE8FA" strokeWidth="2" strokeLinecap="square"/><text fontFamily="inherit" fill="#202020"><tspan x="11.3" y="22">12</tspan></text><text fontFamily="inherit" fill="#202020"><tspan x="72" y="22">15</tspan></text><text fontFamily="inherit" fill="#202020"><tspan x="133.4" y="22">18</tspan></text><text fontFamily="inherit" fill="#202020"><tspan x="210.1" y="22">22</tspan></text><text fontFamily="inherit" fill="#202020"><tspan x="293.3" y="22">26</tspan></text><text fontFamily="inherit" fill="#202020"><tspan x="394.5" y="22">31</tspan></text><text fontFamily="inherit" fill="#202020"><tspan x="510.3" y="22">37</tspan></text><circle fill="#008EFE" cx="21" cy="59" r="6"/><circle fill="#008EFE" cx="81" cy="59" r="6"/><circle fill="#008EFE" cx="143" cy="59" r="6"/><circle fill="#008EFE" cx="221" cy="59" r="6"/><circle fill="#008EFE" cx="305" cy="59" r="6"/><circle fill="#008EFE" cx="404" cy="59" r="6"/><circle fill="#008EFE" cx="521" cy="59" r="6"/></svg>
            </HorizontalScroll>
            <figcaption className={`${g.textCenter}`}>Simplified font-sizes using a modular scale.</figcaption>
        </figure>

        <div className={`${g.maxWidth} ${g.gMarginTopLarge}`}>
          <p className={`${g.g6l} ${g.center}`}>We applied this same approach with the grid, buttons, and other patterns. Now we just needed to simplify how we communicated without using verbose, time-intensive spec documents.</p>
        </div>

        <div className={`${g.maxWidth}`}>
          <h2 className={`${g.g6l} ${g.center}`}>Building a Shared Language</h2>

          <p className={`${g.g6l} ${g.center}`}>Using a combination of <abbr title='Also known as SASS (syntastically awesome style sheets)'>SCSS</abbr> mixins and Sketch symbols, we created a shared language to help designers and engineers communicate with less documentation.</p>

          <p className={`${g.g6l} ${g.center}`}>In code, you simply include type sizes <span className={`${g.noWrap}`}>like so</span>:
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
<span><span className="token key atrule">    font-size</span><span className="token punctuation">:</span>   <span className="token punctuation">{`   [`}</span><span className="token punctuation">{`]`}</span> // typography(large);</span>
<span><span className="token key atrule">    margin-top</span><span className="token punctuation">:</span>  <span className="token punctuation">{` [`}</span><span className="token punctuation">{`]`}</span> // spacing(large)</span>
          </Code>

          <h2 className={`${g.g9m} ${g.g6l} ${g.center}`}>Credits</h2>

          <p className={`${g.g9m} ${g.g6l} ${g.center}`}>
            <LinkExternal href="https://angel.co/mskrys" >Krystle Cho</LinkExternal> – Product Designer <br />
            <LinkExternal href="http://www.emelynbaker.com/">Emelyn Baker</LinkExternal> – Product Designer<br />
            <LinkExternal href="https://twitter.com/threesided">Scott Gamble</LinkExternal> – Engineer
          </p>
        </div>
      </Layout>
    );
  }

}

export default BuildingADesignSystem;
