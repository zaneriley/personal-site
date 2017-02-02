---
title: Case Study #1
---

# Case Study 3 ABOUT THIS PROJECT

***
{{TOC}}
***
## Metric:

**Speed of feature development**
**Load times**
**Team satisfaction**

## Result:

**Increased velocity** – Built and deployed [landing page](http://brit.co/teach/) in a single day without engineering resources.

**Reduced CSS filesize** by 33%. 

**Improved communication** by giving design and engineering a shared language and an objective frame of reference to build from.

## My Role:

I led the creation of our design system–the visual design, code conventions, sketch files, documentation and accessibility guidelines.


## A design system that improves communication, maintainability and consistency.

The Brit + Co design system is a collection of reusable design patterns and visual styles that help us create a better product, allowing us to focus on higher level thinking.

/styleguide.png

```
[gif of using sketch] and [gif of using code]
```

Instead of stopping other projects so we could build our design system, we built new patterns on a per-project basis. Projects often revolve around integral user interface elements, and as those elements came up the product team would standardized them. 

## Defining What’s Needed

Brit + Co has a diverse set of design needs. User behavior differs when reading articles, where people visit from social media throughout the day, and when taking an online class, where people are more task-driven and focused.  

To understand these needs, I performed an audit across the site looking for patterns.

### Example: Patterns in Typography
To quote iA.net, “[Web Design is 95% Typography](https://ia.net/topics/the-web-is-all-about-typography-period/)”, so it isn’t a surprise that so much of our design system is typography related. 

Throughout the audit, I noticed were 17 different font-sizes (50 if you count unique values in the CSS). All were hardcoded pixel values.

/Screen Shot 2017-01-23 at 2.43.02 PM copy.png

I then chose a [modular scale](http://www.modularscale.com/?18&px&1.2&web&text) that best matched what we had. A scale of 1.2 wa. Each font-size was simply multiplied by 1.2 to get the next size increase.

Thus we reduced the site to just seven typesizes:

/Screen Shot 2017-01-23 at 2.48.08 PM.png
_NOTE: not pictured in this rough image is 12px size._

We took this same approach with the grid, buttons and many other  patterns.  This simplifed what we had, now we needed to simplify how we communicated without using verbose, time-intensive spec documents.

## Building a Shared Language

We created a shared language using a combination of `SCSS` mixins and Sketch symbols so designers and engineers could communicate.

In code, you simply include type sizes like so:
```scss
.header-large {
  @include typography(xxx-large);
}
```

When designing, you’d simply choose a text style with the same name.

/Screen Shot 2017-01-23 at 3.49.54 PM.png

This shared language compounds as design patterns get more complex:

```
Timelapse video of UI building in Sketch
```

To ensure maintainability as the team grew, we knew we’d have to automate as many of our design decisions as possible.

## Building tools that enforce team standards

To enforce more rigorous coding standards, we introduced linting, editor configs, Github pull request templates and more. Tools like linting further cut down on communication, because our IDE’s would let us know if we broke a rule like below:

```yaml

  PropertyUnits:
    global: ['em', 'rem', '%', 'vw', 'vh', 'vmin', 'vmax'] # Allow relative units globally
    properties:
      animation-delay:      ['ms'] # Only miliseconds
      animation-duration:   ['ms']
      animation:            ['ms']
      background-size:      ['px', 'em', '%']
      border-bottom:        ['px']
      border-left:          ['px']
      border-right:         ['px']
      border-top:           ['px']
      border:               ['px']
      color:                [] # No units allowed, using sass color-map
      font-size:            [] # No units allowed, using modular scale.
      line-height:          [] # No units allowed, unitless integer.
      margin-top:           [] # No units allowed, using modular scale.
      margin-bottom:        [] # No units allowed, using modular scale.
      margin:               [] # No units allowed, using modular scale.
      padding-top:          [] # No units allowed, using modular scale.
      padding-bottom:       [] # No units allowed, using modular scale.
      padding:              [] # No units allowed, using modular scale.
      perspective:          ['px']
      text-shadow:          ['px']
      transition-delay:     ['ms']
      transition-duration:  ['ms']
      transition:           ['ms']
```

When the system needed to be adjusted, everyone would know the moment they ran into it. There is a change log for every release, but now you could trust you would be alerted to big changes.

*** 


