$(document).ready ->
  $('#start').click ->
    chrome.extension.sendMessage
      type: 'action'
      action: 'start'
    true

  $('#stop').click ->
    chrome.extension.sendMessage
      type: 'action'
      action: 'stop'
    true

  class RecordView extends Backbone.View
    tagName: 'li'

    events:
        "click .playback"  : "playback",
        "click .place"     : "placeOnPage",
        "dblclick .record" : "edit",
        "click .delete"    : "delete",
        "keypress .edit"   : "updateOnEnter",
        "blur .edit"       : "close"

    initialize: ->
      @model.bind 'change', @render, @
      @model.bind 'destroy', @remove, @

    playback: ->
      record = @model
      console.log record
      console.log record.id
      chrome.extension.sendMessage
        type: 'action'
        action: 'start-playback'
        id: record.id

    placeOnPage: ->
      chrome.extension.sendMessage
        type: 'action'
        action: 'place'
        id: @model.id

    delete: ->
      @model.destroy()

    render: ->
      @$el.html '<div class="record">
        <input class="playback" type="button" value="playback" />
        <input class="place" type="button" value="place" />
        <label>' + @model.get('title') + '</label>
        <input class="delete" type="button" value="delete" />
      </div>
      <input class="edit" type="text" value="' + @model.get('title') + '" />'
      @input = @$ '.edit'
      @

    edit: ->
      @$el.addClass 'editing'
      @input.focus()

    close: ->
      value = @input.val()
      @model.save title: value
      @$el.removeClass 'editing'
      @render()

    updateOnEnter: (e) ->
      @close() if e.keyCode is 13

  class AppView extends Backbone.View
    el: $ '#app'

    initialize: ->
      window.Database.bind 'add', @addOne, @
      window.Database.bind 'reset', @addAll, @
      window.Database.bind 'all', @render, @
      window.Database.fetch()

    render: ->
      $('#record-list').html ''
      @addAll()

    addOne: (record) ->
      view = new RecordView model: record
      $('#record-list').append view.render().el

    addAll: ->
      window.Database.each @addOne

    refresh: ->
      window.Database.fetch()
      $('#record-list').html ''
      @addAll()

  App = window.App = new AppView
  window.RecordView = RecordView
  App.render()

