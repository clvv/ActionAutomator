class Control
  constructor: ->
    @recording = false
    @replaying = false
    @events = []

  start: ->
    @recording = true
    chrome.tabs.getSelected null, (tab) ->
      chrome.tabs.sendMessage tab.id, action: "start", (response) ->
        null

  stop: ->
    @recording = false
    chrome.tabs.getSelected null, (tab) ->
      chrome.tabs.sendMessage tab.id, action: "stop", (response) ->
        null
    @save events: @events
    @events = []

  save: (record) ->
    return false if record.events.length is 0
    record.url ?= @processURL record.events[0].url
    record.size ?= record.events.length
    console.log 'Saving record...'
    console.log record
    model = window.Database.create record
    @addRecord record.url, model.id

  delete: (id) ->
    window.Database.fetch()
    record = window.Database.get id
    record.destroy()

  addRecord: (url, id) ->
    key = "HT-#{url}"
    val = localStorage[key] or ""
    ids = val.split /[, ]+/
    ids.push id
    localStorage[key] = ids.join ', '

  findRecords: (url) ->
    window.Database.fetch()
    key = "HT-#{url}"
    val = localStorage[key] or ""
    list = []
    ids = []
    for id in val.split /[, ]+/
      continue if not id
      console.log id
      record = window.Database.get id
      continue if not record
      console.log record
      ids.push id
      list.push
        id: id
        title: record.attributes.title
        offset: record.attributes.offset
    localStorage[key] = ids.join ', ' if ids.length > 0
    list

  processURL: (url) ->
    url.split(/[?#]/)[0]

  compareLocation: (url1, url2) ->
    if url1 is url2
      true
    else if (@processURL url1) is (@processURL url2)
      true
    else
      false

  chopRecord: ->
    page = []
    rest = []
    first = null
    @record.events ?= @record.attributes.events
    for event in @record.events
      first ?= event.url
      if rest.length is 0
        if @compareLocation first, event.url
          page.push event
        else
          rest.push event
      else
        rest.push event

    console.log rest

    @record.events = rest
    @record.size = rest.length

    if @record.size is 0
      @replaying = false

    events: page
    size: page.length

  playback: (id) ->
    window.Database.fetch()
    if id # initial call
      record = window.Database.get id
      console.log 'playback..'
      console.log record
      @replaying = true
      @record = record
    else # from "ping"
      null
    console.log 'Sending events...'
    chrome.tabs.getSelected null, (tab) =>
      chrome.tabs.sendMessage tab.id,
        action: "playback"
        record: @chopRecord()
        , (response) ->
          null

  updateRecord: (id, attr) ->
    window.Database.fetch()
    record = window.Database.get id
    console.log record
    record.save attr

  addEvent: (event) ->
    @events.push event

control = new Control

chrome.extension.onMessage.addListener (request, sender, sendResponse) ->
  console.log request
  switch request.type
    when 'event'
      if control.recording
        control.addEvent request.event
    when 'action'
      switch request.action
        when 'start' then control.start()
        when 'stop' then control.stop()
        when 'start-playback' then control.playback request.id
        when 'delete' then control.delete request.id
        when 'save' then control.save request.record
    when 'data'
      control.updateRecord request.id, request.attr
    when 'ping'
      if control.recording
        control.start()
      else if control.replaying
        control.playback()
      else
        records = control.findRecords control.processURL sender.tab.url
        console.log sender
        if records.length isnt 0
          console.log 'sending back records'
          console.log records
          sendResponse records: records

