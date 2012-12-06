class Record extends Backbone.Model
  initialize: ->
    if not @get 'title'
      @set 'title', 'New record'

class Database extends Backbone.Collection
  localStorage: new Backbone.LocalStorage "Database"
  model: Record

  processURL: (url) ->
    url.split(/[?#]/)[0]

  createRecord: (events) ->
    return false if events.length is 0
    url = @processURL events[0].url
    record =
      events: events
      size: events.length
      url: url
    console.log 'Saving record...'
    console.log record
    model = @create record
    @updateHash record.url, model.id

  updateHash: (url, id) ->
    key = "HT-#{url}"
    val = localStorage[key] or ""
    ids = val.split /[, ]+/
    ids.push id
    localStorage[key] = ids.join ', '

window.Record = Record
window.Database = new Database

