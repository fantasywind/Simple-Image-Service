express = require 'express'
http = require 'http'
path = require 'path'
gm = require 'gm'

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