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


make_option = (l, key=null) ->
  <option value='{l}' key={key}>{l}</option>

make_td = (c, class_name=null, key=null) ->
  <td className={class_name} key={key}>{c}</td>

make_tr = (c) -> <tr>{c}</tr>


class MonthWeekTd extends React.Component
  render: ->
    class_name = 'mw_td_base mw_td_day'
    class_name += (
      if this.props.day.idx == this.props.today.idx
      then ' mw_td_this_day'
      else ''
    )

    <td className={class_name}>{this.props.day.day}</td>


class MonthWeekTr extends React.Component
  renderMonthWeekTd: (day) ->
    key = "mw-td-#{day.idx}"

    <MonthWeekTd key={key} today={this.props.today} day={day} />

  render: ->
    class_name = 'mw_td_base mw_td_month'
    class_name += (
      if this.props.week == this.props.today.week
      then ' mw_td_this_month'
      else ''
    )
    fill_left_num = -(1 - this.props.days[0].day)
    fill_right_num = 7 - this.props.days[this.props.days.length - 1].day

    <tr>
      <td className={class_name}>{this.props.week}</td>
      {
        make_td('', 'mw_td_base mw_td_empty', "etd-#{this.props.week}-#{n}") \
        for n in [1..fill_left_num] \
        when fill_left_num
      }
      {this.renderMonthWeekTd(day) for day in this.props.days}
      {
        make_td('', 'mw_td_base mw_td_empty', "etd-#{this.props.week}-#{n}") \
        for n in [1..fill_right_num] \
        when fill_right_num
      }
    </tr>


class MonthTable extends React.Component
  renderMonthWeekTr: (week, days) ->
    key = "mw-tr-#{week}"

    <MonthWeekTr
      key={key}
      today={this.props.urw_date.day()}
      week={week}
      days={days}
    />

  render: ->
    month_num = this.props.urw_date.day().month_num
    days_lst = (day for day in calendar_data when day.month_num == month_num)
    month_map = {}
    for day in days_lst
      month_map[day.week] ||= []
      month_map[day.week].push(day)

    init_day = {week: days_lst[0].week, day: days_lst[0].day}

    <table id='mt_table'>
      <thead>
        <tr>
          <th>Week</th>
          <th colSpan='7'>{this.props.urw_date.day().month}</th>
        </tr>
      </thead>
      <tbody>
        {this.renderMonthWeekTr(week, days) for week, days of month_map}
      </tbody>
    </table>


class UrwMainApp extends React.Component
  constructor: (props) ->
    super props
    @urw_date = new UrwDate(this.props.day_idx)
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
        <MonthTable urw_date={this.state.urw_date} />
      </div>
    </div>


class UrwDateSelector extends React.Component
  constructor: (props) ->
    super props
    this.state = {
      week: null,
      day: null,
    }

  handleWeekChoice: (e) ->
    week = e.target.value
    console.log "Week choice? #{week}"

    if week == ''
      return

    this.setState({week: week})

  handleDayChoice: (e) ->
    day = e.target.value
    console.log "Day selected? #{day}"

  renderDaySelect: ->
    console.log "Day Select run!"

    <select onChange={(e) => this.handleDayChoice(e)}>
      <option value=''>Select day...</option>
      {<option value={d} key="#{this.state.week}-#{d}">{d}</option> for d of calendar_map[this.state.week]}
    </select>

  render: ->
    <div>
      Select now:
      <select onChange={(e) => this.handleWeekChoice(e)}>
        <option value=''>Select week...</option>
        {<option value={w} key={w}>{w}</option> for w of calendar_map}
      </select>
      {this.renderDaySelect() if this.state.week}
    </div>


class App extends React.Component
  constructor: (props) ->
    super props
    this.state = {
      day_idx: 0
      renderSelector: true,
      renderMain: false,
    }

    handleDateSelected: (e) ->
      this.setState({
        day_idx: e.state.day_idx,
        renderSelector: false,
        renderMain: true,
      })

  render: ->
    <div>
      {
        <UrwDateSelector
          handleDateSelected={=> this.handleDateSelected()}
        /> \
        if this.state.renderSelector
      }
      {
        <UrwMainApp
          day={this.state.day_idx}
        /> \
        if this.state.renderMain
      }
    </div>


render <App />, document.getElementById('app')
