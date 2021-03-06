CALENDAR = require '../data/calendar.json'
CALENDAR_MAP = {}
for day, idx in CALENDAR
  CALENDAR_MAP[day.week] ||= {}
  CALENDAR_MAP[day.week]["#{day.day}"] = idx


require './index.less'
import React from 'react'
import {render} from 'react-dom'


day_to_s = (day) ->
  date = CALENDAR[day]
  "Day #{date.day} of #{date.week}, #{date.month} (#{date.sub_season})"

days_till_event = (year, day, event) ->
  (
    ((event.deadline_at.year - year) * CALENDAR.length) +
    (event.deadline_at.day - day)
  )

mod = (number, modulus) -> ((number % modulus) + modulus) % modulus


class MonthTableWidget extends React.Component
  renderMonthWeekTd: (events, today, day) ->
    class_name = 'mw_td_base mw_td_day'
    class_name += " #{day.sub_season.toLowerCase()}"
    class_name += if today.idx == day.idx then ' mw_td_this_day' else ''

    events_num = 0
    for event in events
      continue if event.deadline_at.day != day.idx
      events_num += 1

    if events_num > 0
      events_str = <div className='mw_td_events_cnt'>({events_num})</div>
    else
      events_str = ''

    <td className={class_name} key="mtw-td-#{day.idx}">
      {day.day}{events_str}
    </td>

  renderMonthWeekTr: (events, today, week, days) ->
    class_name = 'mw_td_base mw_td_month'
    class_name += if today.week == week then ' mw_td_this_month' else ''

    fill_left_num = -(1 - days[0].day)
    fill_right_num = 7 - days[days.length - 1].day

    <tr key="mtw-tr-#{week}">
      <td className={class_name}>{week}</td>
      {
        <td className='mw_td_base mw_td_empty' key="mtw-td-b-#{n}"/> \
        for n in [1..fill_left_num] \
        when fill_left_num
      }
      {this.renderMonthWeekTd(events, today, day) for day in days}
      {
        <td className='mw_td_base mw_td_empty' key="mtw-td-a-#{n}"/> \
        for n in [1..fill_right_num] \
        when fill_right_num
      }
    </tr>

  render: ->
    date = CALENDAR[this.props.day]
    events = (
      e for e in this.props.events \
      when CALENDAR[e.deadline_at.day].month_num == date.month_num \
      and e.deadline_at.year == this.props.year
    )

    days = (day for day in CALENDAR when day.month_num == date.month_num)
    months = {}
    for day in days
      months[day.week] ||= []
      months[day.week].push(day)

    init_day = {week: days[0].week, day: days[0].day}

    <table id='mt_table'>
      <thead>
        <tr>
          <th>Week</th>
          <th colSpan='7'>{date.month}</th>
        </tr>
      </thead>
      <tbody>
        {
          this.renderMonthWeekTr(events, date, week, days) \
          for week, days of months
        }
      </tbody>
    </table>


class EventsTableWidget extends React.Component
  renderEvent: (event) ->
    days_till = days_till_event(this.props.year, this.props.day, event)

    days_till_s = if days_till == 0
        'today'
      else if days_till == -1
        'yesterday'
      else if days_till == 1
        'tomorrow'
      else if days_till > 1
        "in #{days_till} days"
      else
        "#{Math.abs(days_till)} days ago"

    class_name = if days_till < 0
        class_name = 'event_past'
      else if days_till == 0
        class_name = 'event_today'
      else if days_till == 1
        class_name = 'event_tomorrow'
      else
        null

    <tr key="tr-e-#{event.key}" className={class_name}>
      <td>
        <button onClick={=> this.props.delEvent(event.key)}>X</button>
      </td>
      <td>{days_till_s}</td>
      <td>{event.description}</td>
    </tr>

  render: ->
    <table id='e_table'>
      <thead>
        <tr>
          <th></th>
          <th className='et_th_when'>When</th>
          <th className='et_th_what'>What</th>
        </tr>
      </thead>
      <tbody>
        {this.renderEvent(event) for event in this.props.events}
      </tbody>
    </table>


class AddEventWidget extends React.Component
  MODE_IN_DAYS = 'In days'
  MODE_AT_DATE = 'At Date'
  MODES = [MODE_IN_DAYS, MODE_AT_DATE]

  constructor: (props) ->
    super props
    this.state = {
      description: '',
      mode: MODES[0],
      error: false,
    }

  handleModeSelect: (e) ->
    this.setState({mode: e.target.value})

  handleInfo: (e) ->
    if e.target.value.length < 5
      this.setState({error: true})
    else
      this.setState({
        description: e.target.value,
        error: false,
      })

  handleClick: (day) ->
    if this.state.error
      return

    this.props.onClick(day, this.state.description)

  render: ->
    input_class_name = 'aew_desc'
    input_class_name += if this.state.error then ' err' else ''

    <div className='box'>
      <input
        className={input_class_name}
        placeholder='What will happen...'
        type='text'
        onChange={(e) => this.handleInfo(e)}
      />
      <select
        onChange={(e) => this.handleModeSelect(e)}
        value={this.state.mode}
      >
        {<option value={d} key={d}>{d}</option> for d in MODES}
      </select>
      {
        <InDaysWidget
          submit_text='Add Event'
          day={this.props.day}
          onClick={(day) => this.handleClick(day)}
        /> \
        if this.state.mode == MODE_IN_DAYS
      }
      {
        <AtDateWidget
          intro_text='At'
          submit_text='Add Event'
          onClick={(day) => this.handleClick(day)}
        /> \
        if this.state.mode == MODE_AT_DATE
      }
    </div>


class TodayWidget extends React.Component
  _get_today: ->
    day_to_s(this.props.day) + " (Year: #{this.props.year})"

  render: ->
    <div className='box'>
      <button
        onClick={=> this.props.moveDay(-1)}
        disabled={this.props.day == 0 and this.props.year == 1}
      >
        Prev
      </button>
      {this._get_today()}
      <button onClick={=> this.props.moveDay(1)}>
        Next
      </button>
    </div>


class InDaysWidget extends React.Component
  constructor: (props) ->
    super props
    this.state = {
      days: 7,
      error: false,
    }

  handleValue: (e) ->
    this.setState({days: e.target.value})

  handleClick: (e) ->
    val = parseInt(this.state.days)
    if (val > 0) and (val < 361)
      this.setState({error: false})

      day = mod(this.props.day + val, CALENDAR.length)
      this.props.onClick(day)
    else
      this.setState({error: true})

  render: ->
    input_class_name = 'idw_days'
    input_class_name += if this.state.error then ' err' else ''

    <div className={this.props.class_name}>
      In
      <input
        className={input_class_name}
        type='text' value={this.state.days}
        onChange={(e) => this.handleValue(e)}
      />
      {if this.state.days > 1 then 'days' else 'day'}
      <button onClick={(e) => this.handleClick(e)}>
        {this.props.submit_text}
      </button>
    </div>


class AtDateWidget extends React.Component
  constructor: (props) ->
    super props
    this.state = {
      week: CALENDAR[0].week,
      day: "#{CALENDAR[0].day}",
      error: false,
    }

  handleWeekSelect: (e) ->
    this.setState({week: e.target.value})

  handleDaySelect: (e) ->
    this.setState({day: e.target.value})

  handleClick: (e) ->
    day = CALENDAR_MAP[this.state.week][this.state.day]
    if day is undefined
      this.setState({error: true})
    else
      this.setState({error: false})
      this.props.onClick(day)

  render: ->
    <div className={this.props.class_name}>
      {this.props.intro_text}
      <select
        className={if this.state.error then 'err' else ''}
        onChange={(e) => this.handleDaySelect(e)}
        value={this.state.day}
      >
        {<option value={d} key={d}>day {d}</option> for d in [1..7]}
      </select>
      of
      <select
        onChange={(e) => this.handleWeekSelect(e)}
        value={this.state.week}
      >
        {<option value={w} key={w}>{w}</option> for w of CALENDAR_MAP}
      </select>
      <button onClick={(e) => this.handleClick(e)}>
        {this.props.submit_text}
      </button>
    </div>


class App extends React.Component
  EVENT_KEEP_UNTIL = -30
  LS_KEY = 'urw_cal_state'

  constructor: (props) ->
    super props

    initial_state = JSON.parse(localStorage.getItem(LS_KEY))
    if not initial_state?
      initial_state = {
        day: 0,
        year: 1,
        events: [],
        is_ready: false,
      }

    this.state = initial_state

  componentWillUpdate: (nextProps, nextState) ->
    localStorage.setItem(LS_KEY, JSON.stringify(nextState))

  initState: (day) ->
    this.setState({
      day: day,
      is_ready: true,
    })

  moveDay: (n) ->
    new_day = this.state.day + n
    new_year = this.state.year
    if new_day > (CALENDAR.length - 1)
      new_year += 1
    else if new_day < 0
      new_year -= 1

    if new_day > this.state.day or new_year > this.state.year
      new_events = (
        e for e in this.state.events \
        when days_till_event(this.state.year, this.state.day, e) > EVENT_KEEP_UNTIL
      )
    else
      new_events = this.state.events.slice()

    this.setState({
      day: mod(new_day, CALENDAR.length),
      year: new_year,
      events: new_events,
    })

  addEvent: (day, description) ->
    year = this.state.year
    if day < this.state.day
      year += 1

    event = {
      added_at: {
        year: this.state.year,
        day: this.state.day,
      },
      deadline_at: {
        year: year,
        day: day,
      },
      description: description,
      key: Date.now(),
    }
    new_events = [...this.state.events, event]
    new_events.sort((a, b) =>
      days_till_event(this.state.year, this.state.day, a) -
      days_till_event(this.state.year, this.state.day, b)
    )
    this.setState({events: new_events})

  delEvent: (key) ->
    new_events = (e for e in this.state.events when e.key != key)
    this.setState({events: new_events})

  render: ->
    if this.state.is_ready
      <div>
        <TodayWidget
          day={this.state.day}
          year={this.state.year}
          moveDay={(n) => this.moveDay(n)}
        />
        <MonthTableWidget
          day={this.state.day}
          year={this.state.year}
          events={this.state.events}
        />
        <AddEventWidget
          day={this.state.day}
          onClick={(day, description) => this.addEvent(day, description)}
        />
        {
          <EventsTableWidget
            day={this.state.day}
            year={this.state.year}
            events={this.state.events}
            delEvent={(key) => this.delEvent(key)}
          /> \
          if this.state.events.length > 0
        }
      </div>
    else
      <div>
        <AtDateWidget
          class_name='box'
          intro_text='Select starting day:'
          submit_text='Go'
          onClick={(day) => this.initState(day)}
        />
      </div>

render <App />, document.getElementById('app')
