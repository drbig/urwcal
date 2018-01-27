#
# Logic section
#

calendar_data = require '../data/calendar.json'
calendar_map = {}
for day, idx in calendar_data
  calendar_map[day.week] ||= {}
  calendar_map[day.week]["#{day.day}"] = idx


# yes, JS is fuckin' brain dead
mod = (number, modulus) -> ((number % modulus) + modulus) % modulus


class UrwDate
  constructor: (@day_idx) ->

  day: ->
    calendar_data[@day_idx]

  move: (n) ->
    @day_idx = mod @day_idx + n, calendar_data.length

  to_s: ->
    day = this.day()
    "Day #{day.day} of #{day.week}, #{day.month} (#{day.sub_season})"


#
# Web section
#

require './index.less'
import React from 'react'
import {render} from 'react-dom'

make_td = (c) -> <td>{c}</td>
make_tr = (c...) -> <tr>{c}</tr>

format_days = (days) ->
  for day in days
    console.log day
    make_td(day.day)

class MonthView extends React.Component
  render: ->
    month_num = this.props.urw_date.day().month_num
    console.log month_num
    days_lst = (day for day in calendar_data when day.month_num == month_num)
    month_map = {}
    for day in days_lst
      month_map[day.week] ||= []
      month_map[day.week].push(day)

    console.log month_map
    init_day = {week: days_lst[0].week, day: days_lst[0].day}
    console.log init_day

    <table>
      <thead>
        <tr>
          <th>Week</th>
          <th colSpan='7'>{this.props.urw_date.day().month}</th>
        </tr>
      </thead>
      <tbody>
        {make_tr(day.week, format_days(days)) for week, days of month_map}
      </tbody>
    </table>


class App extends React.Component
  constructor: (props) ->
    super props
    @urw_date = new UrwDate(0)
    this.state = {urw_date: @urw_date}

  handleMove: (n) ->
    @urw_date.move(n)
    this.setState({urw_date: @urw_date})

  render: ->
    <div>
      <div>
        <button onClick={=> this.handleMove(-1)}>Prev</button>
        <span>{this.state.urw_date.to_s()}</span>
        <button onClick={=> this.handleMove(1)}>Next</button>
      </div>
      <div>
        <MonthView urw_date={this.state.urw_date} />
      </div>
    </div>


render <App />, document.getElementById('app')
