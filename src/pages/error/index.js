/**
 * React Static Boilerplate
 * https://github.com/kriasoft/react-static-boilerplate
 *
 * Copyright © 2015-present Kriasoft, LLC. All rights reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE.txt file in the root directory of this source tree.
 */

import React from 'react';
import history from '../../history';
import Link from '../../../components/Link';
import Layout from '../../../components/Layout';
import s from './styles.css';
import g from '../../styles/grid.css';
import v from '../../styles/aesthetics.css';

class ErrorPage extends React.Component {

  static propTypes = {
    error: React.PropTypes.object,
  };

  componentDidMount() {
    document.title = this.props.error && this.props.error.status === 404 ?
      'Page Not Found' : 'Error';
  }

  goBack = event => {
    event.preventDefault();
    history.goBack();
  };

  render() {
    if (this.props.error) console.error(this.props.error); // eslint-disable-line no-console

    const [code, title] = this.props.error && this.props.error.status === 404 ?
      ['404', 'Page not found'] :
      ['Error', 'Oops, something went wrong'];

    return (
      <main className={` ${s.container} ${g.maxWidth}`}>
          <h1 className={s.code}>{code}</h1>
          <p className={s.title}>{title}</p>
          {code === '404' &&
            <p className={s.text}>
              The page you're looking for does not exist or an another error occurred.
            </p>
          }
          <p className={s.text}>
            <a href="/" onClick={this.goBack}>Go back</a>, or head over to the <Link to="/">home page</Link> to choose a new direction.
          </p>
      </main>
    );
  }

}

export default ErrorPage;
