import React from 'react';
import recommendedPages from '../../relatedPages.json';
import Layout from '../../../components/Layout';
import Link from '../../../components/Link';
import LinkExternal from '../../../components/LinkExternal';
import About from '../../../components/About';
import IconChromeBar from '../../../components/IconChromeBar';
import HorizontalScroll from '../../../components/HorizontalScroll';
import Code from '../../../components/Code';
import LazyLoader from '../../../components/LazyLoader';
import g from '../../styles/grid.css';
import v from '../../styles/aesthetics.css';
import s from './styles.css';

/* Images for this Page */
import styleguide from '../../assets/images/styleguide-1680w.png';
import SketchLapseWebm from '../../assets/images/sketch-time-lapse.webm';
import SketchLapseMp4 from '../../assets/images/sketch-time-lapse.mp4';
import SketchLapsePoster from '../../assets/images/sketch-time-lapse-3360w.jpg';
import textInSketch from '../../assets/images/sketch-text-sizes-2560w.jpg'

class BuildingADesignSystem extends React.Component {

  componentDidMount() {
    document.title = recommendedPages[1].title + ' | Zane Riley';
  }

  render() {
    const {title, about, role, result, readingLength} = recommendedPages[1];

    return (
      <Layout className={`${g.gPaddingTopLarge}`} breadCrumbs="Case Study" recommendedPageFirst={recommendedPages[2]} recommendedPageSecond={recommendedPages[3]}>

        <About title={title} about={about} role={role} result={result} readingLength={readingLength}/>

        <figure className={`${g.maxWidth} ${g.gMarginTopLarge} `}>
          <div className={`${v.shadow1} ${v.borderRadiusTop}`}>
              <IconChromeBar />
              <LazyLoader height="50%" className={`${g.gNoMarginTop} ${g.center}`} >
                <video autoPlay loop muted playsInline poster={SketchLapsePoster}>
                  <source src={SketchLapseWebm} type="video/webm" />
                  <source src={SketchLapseMp4} type="video/mp4" />
                </video>
              </LazyLoader>
          </div>
          <figcaption>Using the design system in Sketch</figcaption>
        </figure>

        <div className={`${g.maxWidth} ${g.gMarginTopLarge}`}>

          <p className={`${g.g6l} ${g.center} ${v.dropCap}`}>The Brit + Co design system is a collection of reusable design patterns and visual styles. These help us create a better product by allowing us to focus on higher-level thinking.</p>

          <p className={`${g.g6l} ${g.center}`}>Projects often revolve around integral user interface elements. As these elements popped up the product team would standardized them. Instead of stopping other projects so we could build our design system in one go, we built new patterns on a per-project basis.
          </p>
        </div>

        <figure className={`${g.maxWidth} $`}>
          <div className={`${v.shadow1} ${v.borderRadiusTop}`}>
            <IconChromeBar />
            <LazyLoader height="56.4%" className={`${g.gNoMarginTop} ${g.center}`} >
              <img src={styleguide} />
            </LazyLoader>
          </div>
          <figcaption>Online styleguide showing color palettes.</figcaption>
        </figure>

        <div className={`${g.maxWidth} $`}>
          <h2 className={`${g.g6l} ${g.center}`}>Defining What's Needed</h2>

          <p className={`${g.g6l} ${g.center}`}>Brit + Co has a diverse set of design needs. User behavior often varies between articles and classes. People browse articles while casually surfing social media. On the other hand, when taking online classes, they are much more focused and task-driven.</p>

          <p className={`${g.g6l} ${g.center}`}>To solve for these design needs, I performed an audit to look for patterns across the site.</p>

          <h3 className={`${g.g6l} ${g.center}`}>Example: Patterns in Typography</h3>

          <p className={`${g.g6l} ${g.center}`}>To quote iA.net, <LinkExternal href="https://ia.net/topics/the-web-is-all-about-typography-period/">“Web Design is 95% Typography”</LinkExternal>, so it isn’t a surprise that so much of our design system is typography related.</p>

          <p className={`${g.g6l} ${g.center}`}>Throughout the audit, I noticed there were 17 different fontSizes (50 if you count unique values in the <abbr title='cascading style sheets'>CSS</abbr>). All were hardcoded pixel values.</p>
        </div>

        <figure className={`${s.beforeScale}`}>
          <HorizontalScroll>
            <svg xmlns="http://www.w3.org/2000/svg" width="1059" height="101" viewBox="0 19 1059 101" version="1.1">
              <title>Previous font sizes.</title>
              <desc>This image shows Brit + Co's existing font sizes laid out on a scale.</desc>
              <g stroke="none" strokeWidth="1" fill="none" fillRule="evenodd">
                  <path d="M8 75L1047 75" stroke="#DCE8FA" strokeWidth="2" strokeLinecap="square"/>
              </g>
              <g>
                  <text>
                      <tspan x="7" y="45" fontSize="12">a</tspan>
                      <tspan x="0" y="116">12</tspan>
                  </text>
                  <ellipse fill="#008EFE" fillRule="nonzero" cx="10.4" cy="74.5" rx="6.4" ry="6.5"/>
              </g>
              <g>
                  <text>
                      <tspan x="75" y="45" fontSize="14">a</tspan>
                      <tspan x="69" y="116">14</tspan>
                  </text>
                  <ellipse fill="#008EFE" fillRule="nonzero" cx="79.4" cy="74.5" rx="6.4" ry="6.5"/>
              </g>
              <g>
                  <text>
                      <tspan x="110" y="45" fontSize="15">a</tspan>
                      <tspan x="104" y="116">15</tspan>
                  </text>
                  <ellipse fill="#008EFE" fillRule="nonzero" cx="114.4" cy="74.5" rx="6.4" ry="6.5"/>
              </g>
              <g>
                  <text>
                      <tspan x="144" y="45" fontSize="16">a</tspan>
                      <tspan x="138" y="116">16</tspan>
                  </text>
                  <ellipse fill="#008EFE" fillRule="nonzero" cx="149.4" cy="74.5" rx="6.4" ry="6.5"/>
              </g>
              <g>
                  <text>
                      <tspan x="179" y="45" fontSize="17">a</tspan>
                      <tspan x="173" y="116">17</tspan>
                  </text>
                  <ellipse fill="#008EFE" fillRule="nonzero" cx="183.4" cy="74.5" rx="6.4" ry="6.5"/>
              </g>
              <g>
                  <text>
                      <tspan x="212" y="45" fontSize="18">a</tspan>
                      <tspan x="206" y="116">18</tspan>
                  </text>
                  <ellipse fill="#008EFE" fillRule="nonzero" cx="217.4" cy="74.5" rx="6.4" ry="6.5"/>
              </g>
              <g>
                  <text>
                      <tspan x="285" y="45" fontSize="20">a</tspan>
                      <tspan x="277" y="116">20</tspan>
                  </text>
                  <ellipse fill="#008EFE" fillRule="nonzero" cx="290.4" cy="74.5" rx="6.4" ry="6.5"/>
              </g>
              <g>
                  <text>
                      <tspan x="355" y="45" fontSize="22">a</tspan>
                      <tspan x="350" y="116">22</tspan>
                  </text>
                  <ellipse fill="#008EFE" fillRule="nonzero" cx="361.4" cy="74.5" rx="6.4" ry="6.5"/>
              </g>
              <g>
                  <text>
                      <tspan x="432" y="45" fontSize="24">a</tspan>
                      <tspan x="426" y="116">24</tspan>
                  </text>
                  <ellipse fill="#008EFE" fillRule="nonzero" cx="438.4" cy="74.5" rx="6.4" ry="6.5"/>
              </g>
              <g>
                  <text>
                      <tspan x="508" y="45" fontSize="26">a</tspan>
                      <tspan x="502" y="116">26</tspan>
                  </text>
                  <ellipse fill="#008EFE" fillRule="nonzero" cx="514.4" cy="74.5" rx="6.4" ry="6.5"/>
              </g>
              <g>
                  <text>
                      <tspan x="544" y="45" fontSize="27">a</tspan>
                      <tspan x="540" y="116">27</tspan>
                  </text>
                  <ellipse fill="#008EFE" fillRule="nonzero" cx="551.4" cy="74.5" rx="6.4" ry="6.5"/>
              </g>
              <g>
                  <text>
                      <tspan x="732" y="45" fontSize="32">a</tspan>
                      <tspan x="728" y="116">32</tspan>
                  </text>
                  <ellipse fill="#008EFE" fillRule="nonzero" cx="740.4" cy="74.5" rx="6.4" ry="6.5"/>
              </g>
              <g>
                  <text>
                      <tspan x="808" y="44" fontSize="34">a</tspan>
                      <tspan x="805" y="116">34</tspan>
                  </text>
                  <ellipse fill="#008EFE" fillRule="nonzero" cx="817.4" cy="74.5" rx="6.4" ry="6.5"/>
              </g>
              <g>
                  <text>
                      <tspan x="1037" y="40" fontSize="40">a</tspan>
                      <tspan x="1034" y="116">40</tspan>
                  </text>
                  <ellipse fill="#008EFE" fillRule="nonzero" cx="1047.4" cy="74.5" rx="6.4" ry="6.5"/>
              </g>
          </svg>
          </HorizontalScroll>
            <figcaption className={`${g.maxWidth}`}>The number of existing font sizes <span className={`${g.noWrap}`}>on Brit + Co.</span></figcaption>
        </figure>

        <div className={`${g.maxWidth} $`}>

          <p className={`${g.g6l} ${g.center}`}>I then chose an appropriate <LinkExternal href="http://www.modularscale.com/?18&px&1.2&web&text">modular scale</LinkExternal>. Each fontSize was simply multiplied by 1.2 to get the next size increase.</p>

          <p className={`${g.g6l} ${g.center}`}>Thus we reduced the site to just seven <span className={`${g.noWrap}`}>type sizes:</span></p>
        </div>
            
        <figure className={`${s.afterScale}`}>
          <HorizontalScroll>
            <svg xmlns="http://www.w3.org/2000/svg" width="1060" height="100" viewBox="0 15 1048 95" version="1.1">
              <title>Font sizes using a modular scale</title>
              <desc>This image shows Brit + Co's new font sizes laid out on a modular scale where each number is multipled by 1.2 to get the next fontSize.</desc>
              <path d="M15 61L1039.5 61" stroke="#DCE8FA" strokeWidth="2" strokeLinecap="square"/>
                <g>
                  <text fontFamily="inherit">
                    <tspan x="7" y="35" fontSize="12">a</tspan>
                    <tspan x="0" y="105">12</tspan>
                  </text>
                  <ellipse fill="#008EFE" fillRule="nonzero" cx="10.4" cy="60.5" rx="6.4" ry="6.5"/>
                </g>
                <g>
                  <text fontFamily="inherit">
                    <tspan x="114" y="35" fontSize="15">a</tspan>
                    <tspan x="108" y="105">15</tspan>
                  </text>
                  <ellipse fill="#008EFE" fillRule="nonzero" cx="118.4" cy="60.5" rx="6.4" ry="6.5"/>
                </g>
                <g>
                  <text fontFamily="inherit">
                    <tspan x="250" y="35" fontSize="18">a</tspan>
                    <tspan x="244" y="105">18</tspan>
                  </text>
                  <ellipse fill="#008EFE" fillRule="nonzero" cx="255.4" cy="60.5" rx="6.4" ry="6.5"/>
                </g>
                <g>
                  <text fontFamily="inherit" >
                    <tspan x="415" y="35" fontSize="22">a</tspan>
                    <tspan x="409" y="105">22</tspan>
                  </text>
                  <ellipse fill="#008EFE" fillRule="nonzero" cx="421.4" cy="60.5" rx="6.4" ry="6.5"/>
                </g>
                <g>
                  <text fontFamily="inherit" >
                    <tspan x="585" y="35" fontSize="26">a</tspan>
                    <tspan x="579" y="105" >26</tspan>
                  </text>
                  <ellipse fill="#008EFE" fillRule="nonzero" cx="591.4" cy="60.5" rx="6.4" ry="6.5"/>
                </g>
                <g>
                  <text fontFamily="inherit">
                    <tspan x="782" y="35" fontSize="31">a</tspan>
                    <tspan x="780" y="105" >31</tspan>
                  </text>
                  <ellipse fill="#008EFE" fillRule="nonzero" cx="791.4" cy="60.5" rx="6.4" ry="6.5"/>
                </g>
                <g>
                  <text fontFamily="inherit">
                    <tspan x="1025" y="35" fontSize="37">a</tspan>
                    <tspan x="1023" y="105">37</tspan>
                  </text>
                  <ellipse fill="#008EFE" fillRule="nonzero" cx="1035.4" cy="60.5" rx="6.4" ry="6.5"/>
                </g>
              </svg>
            </HorizontalScroll>
            <figcaption className={`${g.maxWidth}`}>Simplified font-sizes using a modular scale.</figcaption>
        </figure>

        <div className={`${g.maxWidth} ${g.gMarginTop}`}>
          <p className={`${g.g6l} ${g.center}`}>We applied this same approach with the grid, buttons, and other patterns. Now we just needed to simplify how we communicated without using verbose, time-intensive spec documents.</p>
        </div>

        <div className={`${g.maxWidth}`}>
          <h2 className={`${g.g6l} ${g.center}`}>Building a Shared Language</h2>

          <p className={`${g.g6l} ${g.center}`}>Using a combination of <abbr title='Also known as SASS (syntastically awesome style sheets)'>SCSS</abbr> mixins and Sketch symbols, we created a shared language to help designers and engineers communicate with less documentation.</p>

          <p className={`${g.g6l} ${g.center}`}>In code, you simply include type sizes <span className={`${g.noWrap}`}>like so</span>:
          </p>

          <Code language="CSS" filename="_typography.scss" className={`${g.g8l} ${g.center}`}>
<span><span className="token selector">{`.header-large`} </span><span className="token punctuation">{`{`}</span></span>
  <span><span className="token keyword">{`  @include`}</span> <span className="token function"> typography</span><span className="token punctuation">{`(`}</span>xxx-large<span className="token punctuation">{`)`}</span><span className="token punctuation">{`;`}</span></span>
<span><span className="token punctuation">{`{`}</span></span>
          </Code>

          <p className={`${g.g6l} ${g.center}`}>When designing, you’d simply choose a text style with the same name as the code convention.</p>

        </div>

        <figure className={`${g.maxWidth}`}>
          <div className={`${v.shadow1} ${v.borderRadiusTop}`}>
            <LazyLoader height="46.1%">
              <img src={textInSketch} alt="A screenshot of choosing text styles in Sketch. The text styles have the same naming as the code conventions."/>
            </LazyLoader>
          </div>
          <figcaption>Conventions are the same for both design and code.</figcaption>
        </figure>

        <div className={`${g.maxWidth}`}>
          <p className={`${g.g6l} ${g.center} $`}>This shared language compounds as design patterns get more complex:</p>

          <p className={`${g.g6l} ${g.center}`}>
            To ensure maintainability as the team grew, we knew we’d have to automate as many of our design decisions as possible.
          </p>

          <h2 className={`${g.g6l} ${g.center}`}>Building Tools to Enforce Standards</h2>

          <p className={`${g.g6l} ${g.center}`}>To enforce more rigorous coding standards, we introduced linting, continuous integration tooling, editor configs, Github pull request templates and more. Simple tools like opinionated linters further improved communication because IDE’s helped keep new code in check.</p>

          <Code language="YAML" filename="scsslint.yaml" className={`${g.g8l} ${g.center} `}>
<span><span className="token key atrule">PropertyUnits</span><span className="token punctuation">:</span></span>
<span><span className="token key atrule">  global</span><span className="token punctuation">:</span> <span className="token punctuation">{`[`}</span><span className="token string">'em'</span><span className="token punctuation">,</span> <span className="token string">'rem'</span><span className="token punctuation">,</span> <span className="token string">'%'</span><span className="token punctuation">,</span> <span className="token string">'vw'</span><span className="token punctuation">,</span> <span className="token string">'vh'</span><span className="token punctuation">,</span> <span className="token string">'vmin'</span><span className="token punctuation">,</span> <span className="token string">'vmax'</span><span className="token punctuation">{`]`}</span></span>
<span><span className="token key atrule">  properties</span><span className="token punctuation">:</span></span>
<span><span className="token key atrule">    color</span><span className="token punctuation">:</span>       <span className="token punctuation">{`      [`}</span><span className="token punctuation">{`]`}</span> // color(primary<span className="token punctuation">,</span> lighter);</span>
<span><span className="token key atrule">    font-size</span><span className="token punctuation">:</span>   <span className="token punctuation">{`  [`}</span><span className="token punctuation">{`]`}</span> // typography(large);</span>
<span><span className="token key atrule">    margin-top</span><span className="token punctuation">:</span>  <span className="token punctuation">{` [`}</span><span className="token punctuation">{`]`}</span> // spacing(large)</span>
          </Code>

          <p className={`${g.g6l} ${g.center}`}>When the system needed to be adjusted, everyone would know when they ran into that particular change via their IDE. You no longer had to read through release notes or ask a colleague. 
          </p>

          <p className={`${g.g6l} ${g.center}`}>The design system represents a large overhaul for both the product and the team. We reduced the complexity of working in the frontend, made our site faster, and improved communication.</p> 


          <h2 className={`${g.g9m} ${g.g6l} ${g.center}`}>Credits</h2>

          <p className={`${g.g9m} ${g.g6l} ${g.center}`}>
            <LinkExternal href="https://angel.co/mskrys">Krystle Cho</LinkExternal> – Product Designer <br />
            <LinkExternal href="http://www.emelynbaker.com/">Emelyn Baker</LinkExternal> – Product Designer<br />
            <LinkExternal href="https://twitter.com/threesided">Scott Gamble</LinkExternal> – Engineer
          </p>
        </div>
      </Layout>
    );
  }

}

export default BuildingADesignSystem;
