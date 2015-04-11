http            = require 'http'
path            = require 'path'

express         = require 'express'
session         = require 'express-session'
cookieParser    = require 'cookie-parser'
bodyParser      = require 'body-parser'
logger          = require 'morgan'

socketio        = require 'socket.io'

bluebird        = require 'bluebird'
redis           = bluebird.promisifyAll require 'redis'

app = express()
server = http.Server app
io  = socketio.listen server

# read the port from environment.
app.set 'port', process.env.PORT or 8080

# log the requests.
app.use logger 'combined'

# set the body parser.
app.use bodyParser.json()
app.use bodyParser.urlencoded extended: off
app.use bodyParser.text()

# set the session manager.
app.use session
    secret: 'endless journey'
    resave: off
    saveUninitialized: on
    cookie: secure: on

# serve the static content.
app.use express.static path.join __dirname, '..', 'static'

RankingClass = require './ranking.class'
ranking = new RankingClass()

# post data to the server.
app.post '/game/scores', (req, res) ->
    if data = req.body
        ranking.addToRanking data
        .then ->
            bluebird.all [
                ranking.fetchRankings()
                ranking.fetchRanking data.id
            ]
        .spread (ranks, self) ->
            res.json
                all: ranks
                self: self
        .catch (err) ->
            console.trace err
            res.status(500).end()
    else
        res.status(404).end()

# get the scores from the list.
app.get '/game/scores', (req, res) ->
    ranking.fetchRankings()
    .then (ranks) ->
        res.json ranks
    .catch (err) ->
        console.trace err
        res.status(500).end()

GameSyncLogicClass = require './game-sync-logic.class'

io.on 'connection', (socket) ->
    logic = new GameSyncLogicClass(socket)
    console.log 'connected.'

    # Join the game.
    socket.on 'game:join', (player) ->
        console.log 'joint.'
        logic.join player

    # Play the game.
    socket.on 'game:play', (data) ->
        console.log 'played.'
        logic.sync data

    # when the game is over.
    socket.on 'game:over', (data) ->
        console.log 'over.'
        logic.over data

server.listen app.get('port'), ->
    console.log "Server is running at #{app.get('port')}."
