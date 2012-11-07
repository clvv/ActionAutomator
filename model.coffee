class Record extends Backbone.Model
  initialize: ->
    if not @get 'title'
      @set 'title', 'New record'

class Database extends Backbone.Collection
  localStorage: new Backbone.LocalStorage "Database"
  model: Record

window.Record = Record
window.Database = new Database

