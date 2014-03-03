express = require 'express'
http = require 'http'
path = require 'path'
gm = require 'gm'
program = require 'commander'

thumbList = (val)->
  result = []
  thumb = val.split ','
  for size in thumb
    size = parseInt size.trim(), 10
    result.push size if !isNaN size
  return result

program.version '0.0.1'
program.option '-s, --size [image width in px]', 'Maxinum Image Size', parseInt
program.option '-t, --thumb [thumb width in px]', 'Thumb size (seperate with ",")', thumbList
program.parse process.argv

MAX_WIDTH = program.size or Math.Infinity
THUMBS = program.thumb

app = express()

# all environments
app.set 'port', process.env.PORT || 3000
app.use express.favicon()
app.use express.logger('dev')
app.use express.json()
app.use express.urlencoded()
app.use express.methodOverride()
app.use app.router
app.use express.static(path.join(__dirname, 'images')) 

# development only
if 'development' is app.get('env')
  app.use express.errorHandler()

app.post '/', (req, res)->
  res.json
    status: true
    link: ''

http.createServer(app).listen app.get('port'), ->
  console.log 'Express server listening on port ' + app.get('port')