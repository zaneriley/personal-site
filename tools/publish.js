/**
 * React Static Boilerplate
 * https://github.com/kriasoft/react-static-boilerplate
 *
 * Copyright © 2015-present Kriasoft, LLC. All rights reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE.txt file in the root directory of this source tree.
 */

const task = require('./task');
const s3 = require('s3');
const s3Options = require('../../personal-site-s3-creds.json');

// deploy the app to Amazon s3
global.DEBUG = process.argv.includes('--debug') || false;

module.exports = task('publish', () => new Promise((resolve, reject) => {
  const client = s3.createClient({
    s3Options: s3Options,
  });
  const uploader = client.uploadDir({
    localDir: 'public',
    deleteRemoved: true,
    s3Params: { Bucket: 'zaneriley' }, 
  });
  uploader.on('error', reject);
  uploader.on('end', resolve);
}));