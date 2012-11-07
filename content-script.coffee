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
        $('body').append '<div id=' + record.id + '>
          <p>
            drag
            <input class="playback" type="button" value="' + record.title + '" />
            <input class="delete" type="button" value="Delete" />
          </p>
        </div>'
        console.log record.offset
        $("##{record.id}").offset record.offset if record.offset
        $("##{record.id} .playback").click ->
          chrome.extension.sendMessage
            type: 'action'
            action: 'start-playback'
            id: record.id
        $("##{record.id} .delete").click ->
          chrome.extension.sendMessage
            type: 'action'
            action: 'delete'
            id: record.id
        $("##{record.id}").draggable
          handle: 'p'
          stop: (event, ui) =>
            console.log 'drag stopped!'
            console.log event
            console.log ui
            @updateButtonOffset record.id, ui.offset

  updateButtonOffset: (id, offset) ->
    chrome.extension.sendMessage
      type : 'data'
      id   : id
      attr :
        offset: offset

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
    when 'stop'
      console.log 'Action is "stop"'
      er.stop()
    when 'playback'
      console.log 'Action is "playback"'
      ep = new EventPlayback request.record
      ep.playback()
    when 'place'
      console.log 'Action is "place"'

console.log 'content-script loaded'

chrome.extension.sendMessage type: 'ping', (response) ->
  console.log 'got response from control'
  console.log response.records
  control.place response.records

