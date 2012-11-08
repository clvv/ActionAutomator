class EventRecorder

  constructor: (options) ->
    @frames = []
    @recording = false

  start: ->
    @recording = true
    console.log 'Starting to record events...'
    $(document).click @recordEvent.bind @
    $(':input').change @recordEvent.bind @

  stop: ->
    @recording = false
    console.log 'Stopping...'

  recordEvent: (e) ->
    return if not @recording
    self = @
    record =
      url: document.location.href
      type: e.type
      target: self.getXPath e.target
      value: if e.type is 'change' then $(e.target).val() else null
    @frames.push record
    console.log record
    chrome.extension.sendMessage
      type: 'event'
      event: record

  getElementByXPath: (path) ->
    result = document.evaluate path, document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null
    return result.singleNodeValue

  getXPath: (el) ->
    segs = []
    while el
      if el.hasAttribute 'id'
        segs.unshift "id(\"#{el.getAttribute 'id'}\")"
        return segs.join '/'
      else if el.hasAttribute 'class'
        segs.unshift "#{el.localName.toLowerCase()}[@class=\"#{el.getAttribute 'class'}\"]"
      else
        sib = el.previousSibling
        i = 1
        while sib = sib.previousSibling
          i++ if sib.localName is el.localName
        segs.unshift "#{el.localName.toLowerCase()}[#{i}]"
      if segs.length
        return "/#{segs.join '/'}"
      else
        return null
      el = el.parentNode

class EventPlayback
  constructor: (record) ->
    @events = record.events
    @events.length = record.size

  processURL: (url) ->
    url.split(/[?#]/)[0]

  compareLocation: (url1, url2) ->
    if url1 is url2
      true
    else if (@processURL url1) is (@processURL url2)
      true
    else
      false

  getElementByXPath: (path) ->
    result = document.evaluate path, document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null
    return result.singleNodeValue

  playback: ->
    for event in @events
      continue if not @compareLocation event.url, document.location.href
      console.log event
      switch event.type
        when 'click'
          el = @getElementByXPath event.target
          console.log 'clicking'
          console.log el
          $(el).click()
        when 'change'
          el = @getElementByXPath event.target
          console.log 'changing'
          console.log el
          $(el).val event.value
    null

class PageControl
  constructor: ->

  place: (records) ->
    for record in records
      do (record) =>
        console.log record
        $('body').append '
          <div id=' + record.id + ' class="AA-record">
            <div>
              <button class="handle">◆</button>
              <button class="playback">' + record.title + '</button>
              <button class="dropdown">▾</button>
            </div>
            <ul>
              <li><a class="rename">Rename</a></li>
              <li><a class="delete">Delete</a></li>
            </ul>
            <input class="edit" type="text" value="' + record.title + '" />
        </div>'
        console.log record.offset
        record.offset ?= top: 0, left: 0
        $("##{record.id}").offset record.offset
        $("##{record.id} .playback").button().click ->
          chrome.extension.sendMessage
            type: 'action'
            action: 'start-playback'
            id: record.id
        .next().button().click ->
          menu = $(@).parent().next()
          if menu.is ':visible'
            menu.hide()
          else
            menu.show().position
              my: 'left top',
              at: 'left bottom',
              of: @
        .parent().buttonset()
        .next().hide().menu()
        $("##{record.id} .delete").click ->
          $("##{record.id}").html ''
          chrome.extension.sendMessage
            type: 'action'
            action: 'delete'
            id: record.id
        $("##{record.id} .rename").click ->
          input = $("##{record.id} .edit")
          input.addClass 'editing'
          input.position
            my: 'left'
            at: 'left'
            of: @
          setTimeout (-> input.focus()), 10
        close = =>
          input = $("##{record.id} .edit")
          @updateRecord record.id, title: input.val()
          input.removeClass 'editing'
          $("##{record.id} .playback .ui-button-text").html input.val()
        $("##{record.id} .edit").blur close
        $("##{record.id} .edit").keypress (e) ->
          close() if e.keyCode is 13
        $("##{record.id}").draggable
          cancel: false
          handle: '.handle'
          stop: (event, ui) =>
            console.log 'drag stopped!'
            console.log event
            console.log ui
            @updateRecord record.id,
              offset: ui.offset

  updateRecord: (id, attr) ->
    chrome.extension.sendMessage
      type: 'data'
      id  : id
      attr: attr

  display: (msg) ->
    $('.AA-msg').html "<h3>#{msg}</h3>"

  clearDisplay: ->
    $('.AA-msg').html ''

$('body').append '<div class="AA-msg"></div>'

er = null
ep = null
control = new PageControl

chrome.extension.onMessage.addListener (request, sender, sendResponse) ->
  console.log 'Got message from extension.'
  console.log request
  switch request.action
    when 'start'
      console.log 'Action is "start"'
      er = new EventRecorder
      er.start()
      control.display 'Recording...'
    when 'stop'
      console.log 'Action is "stop"'
      er.stop()
      control.clearDisplay()
    when 'playback'
      console.log 'Action is "playback"'
      ep = new EventPlayback request.record
      ep.playback()
      control.display 'Replaying...'
    when 'place'
      console.log 'Action is "place"'

console.log 'content-script loaded'

chrome.extension.sendMessage type: 'ping', (response) ->
  console.log 'got response from control'
  console.log response.records
  control.place response.records

