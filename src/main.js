/**
 * React Static Boilerplate
 * https://github.com/kriasoft/react-static-boilerplate
 *
 * Copyright © 2015-present Kriasoft, LLC. All rights reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE.txt file in the root directory of this source tree.
 */

import 'babel-polyfill';
import 'whatwg-fetch';

import React from 'react';
import ReactDOM from 'react-dom';
import FastClick from 'fastclick';
import { Provider } from 'react-redux';
import store from './store';
import router from './router';
import history from './history';
import * as OfflinePluginRuntime from 'offline-plugin/runtime';

import s from './main.css';

const FontFaceObserver = require('fontfaceobserver');

// Observe loading of Open Sans (to remove open sans, remove the <link> tag in
// the index.html file and this observer)
const maria = new FontFaceObserver('Maria', {});
const america = new FontFaceObserver('GT America', {});

// When Open Sans is loaded, add a font-family using Open Sans to the body
maria.load().then(() => {
  document.body.classList.add('wfLoadedMaria');
}, () => {
  document.body.classList.remove('wfLoadedMaria');
});

// When Open Sans is loaded, add a font-family using Open Sans to the body
america.load().then(() => {
  document.body.classList.add('wfLoadedAmerica');
}, () => {
  document.body.classList.remove('wfLoadedAmerica');;
});

let routes = require('./routes.json').default; // Loaded with utils/routes-loader.js
const container = document.getElementById('container');

function renderComponent(component) {
  ReactDOM.render(
    <Provider store={store}>{component}</Provider>, container
  );
  import('./analytics/base.js').then((analytics) => analytics.init());
}

// Find and render a web page matching the current URL path,
// if such page is not found then render an error page (see routes.json, core/router.js)
function render(location) {
  router.resolve(routes, location)
    .then(renderComponent)
    .catch(error => router.resolve(routes, { ...location, error }).then(renderComponent));
}

// Handle client-side navigation by using HTML5 History API
// For more information visit https://github.com/ReactJSTraining/history/tree/master/docs#readme
history.listen(render);
render(history.location);

// Eliminates the 300ms delay between a physical tap
// and the firing of a click event on mobile browsers
// https://github.com/ftlabs/fastclick
FastClick.attach(document.body);

// Enable Hot Module Replacement (HMR)
if (module.hot) {
  module.hot.accept('./routes.json', () => {
    routes = require('./routes.json').default; // eslint-disable-line global-require
    render(history.location);
  });
}

// Install ServiceWorker and AppCache in the end since
// it's not most important operation and if main code fails,
// we do not want it installed
require('offline-plugin/runtime').install();