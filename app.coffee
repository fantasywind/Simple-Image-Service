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
program.option '-s, --size [image]', 'Maxinum Image Width Size in px', parseInt
program.option '-t, --thumb [thumb]', 'Thumb Width Size in px (seperate with ",")', thumbList
program.option '-f, --field [post fidle name]', 'Post file filed name'
program.parse process.argv

MAX_WIDTH = program.size or Math.Infinity
THUMBS = program.thumb
FILE_FIELD = program.field or 'image'

app = express()

# all environments
app.set 'port', process.env.PORT || 3000
app.use express.favicon()
app.use express.bodyParser
  keepExtensions: true
  uploadDir: __dirname + '/images'
app.use express.logger('dev')
app.use express.json()
app.use express.urlencoded()
app.use express.methodOverride()
app.use app.router
app.use express.static(path.join(__dirname, 'images'))

# development only
if 'development' is app.get('env')
  app.use express.errorHandler()

class Photo
  constructor: (@file, @queue, @finish)->

    @tmpName = @file.path.split '/'
    @tmpName = @tmpName[@tmpName.length - 1]
    @tmpName = @tmpName.split '.'
    @extension = @tmpName[@tmpName.length - 1]
    @tmpName = @tmpName[@tmpName.length - 2]

    @img = gm(@file.path)
    @format()

  format: ->
    # Check format
    @img.format (err, value)=>
      if !err?
        @imageType = value
        @size()
      else
        console.error 'Not Image.'
        @status = false
        @queue.counter += 1
        @finish()

  size: ->
    # Check size
    @img.size (err, value)=>
      if !err?
        @width = value.width
        @height = value.height
        @ratio = @height / @width
        if @width < MAX_WIDTH
          @source = "/images/#{@tmpName}.#{@extension}"
          @thumb()
        else
          @resize()
      else
        console.error 'Cannot get size.'
        @status = false
        @queue.counter += 1
        @finish()

  resize: ->
    # Resize large then limit
    @img.resize(MAX_WIDTH, parseInt(MAX_WIDTH * @ratio, 10)).write "#{__dirname}/images/#{@tmpName}.#{@extension}", (err)=>
      if err?
        console.error 'Resize photo failed'
        @status = false
        @queue.counter += 1
        @finish()
      else
        @source = "/images/#{@tmpName}.#{@extension}"
        @thumb()

  thumb: ->
    # Make thumb
    @thumbSources = []
    failed = false
    thumbLength = program.thumb.length

    for width in program.thumb
      ((w)=>
        @img.thumb w, parseInt(w * @ratio, 10), "#{__dirname}/images/#{@tmpName}_#{w}.#{@extension}", 80, (err, stdout, stderr, command)=>
          if err?
            console.error 'Make thumb failed.'
            @queue.counter += 1
            @finish()
          else
            @thumbSources.push "/images/#{@tmpName}_#{w}.#{@extension}"
            if @thumbSources.length is thumbLength
              @status = true
              @queue.counter += 1
              @finish()
      )(width)

app.post '/', (req, res)->
  try
    if !req.files[FILE_FIELD]?
      throw new Error 'No Image Input'

    queue =
      total: req.files[FILE_FIELD].length
      counter: 0
      images: []

    finish = ->
      if queue.total is queue.counter
        images = []

        for img in queue.images
          if img.status
            images.push
              host: req.headers.host
              source: img.source
              thumbs: img.thumbSources

        res.json
          status: true
          images: images

    for img in req.files[FILE_FIELD]
      queue.images.push new Photo img, queue, finish

  catch ex
    res.json
      status: false
      msg: ex.toString()

http.createServer(app).listen app.get('port'), ->
  console.log 'Express server listening on port ' + app.get('port')