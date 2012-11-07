{print} = require 'util'
{spawn, exec} = require 'child_process'

task 'build', 'Build .js files from .coffee files', ->
  for file in ['background', 'content-script', 'model', 'popup']
    coffee = spawn 'coffee', ['-c', "#{file}.coffee"]
    coffee.stdout.on 'data', (data) -> print data.toString()
    coffee.stderr.on 'data', (data) -> print data.toString()

