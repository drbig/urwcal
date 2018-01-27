#
# Logic section
#

calendar_data = require '../data/calendar.json'
calendar_map = {}
for day, idx in calendar_data
  calendar_map[day.week] ||= {}
  calendar_map[day.week]["#{day.day}"] = idx


class UrwDate
  constructor: (@day_idx) ->

  day: ->
    calendar_data[@day_idx]

  move: (n) ->
    @day_idx = (@day_idx + n) % calendar_data.length

  next: ->
    this.move(1)

  prev: ->
    this.move(-1)

  to_s: ->
    day = this.day()
    "Day #{day.day} of #{day.week}, #{day.month} (#{day.sub_season})"


#
# Web section
#

require './index.less'
import React from 'react'
import {render} from 'react-dom'


class App extends React.Component
  constructor: (props) ->
    super props
    @urw_date = new UrwDate(0)
    this.state = {
      date: @urw_date.to_s()
    }

  handleMove: (n) ->
    @urw_date.move(n)
    this.setState({date: @urw_date.to_s()})

  render: ->
    <div>
      <span className="button" onClick={=> this.handleMove(-1)}>Prev</span>
      <span>{this.state.date}</span>
      <span className="button" onClick={=> this.handleMove(1)}>Next</span>
    </div>


render <App />, document.getElementById('app')
