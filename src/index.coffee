require './index.less'

import React from 'react'
import {render} from 'react-dom'


class App extends React.Component
  render: ->
    <p>Hello React!</p>


render <App/>, document.getElementById('app')
