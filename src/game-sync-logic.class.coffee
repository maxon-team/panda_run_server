bluebird = require 'bluebird'
config = require './config'

###

The Game synchronization logic implementation.

The logic contains 3 stage:

 * Join

   In `join` stage, the player creates and joins a session, waiting for other players to join in, 
   or start a game if there's one already waiting.

   If the game started, eg. the `game:ready` flag is set, the game turns to `sync` stage.

 * sync

   In `sync` stage, the player creates a game and synchronizes the game data with the partner.

   If the game ended, the `game:over` message will be sent to the partner with final synchronized 
   data.

 * over

   In `over` stage, the player ends the game. The message will be synchronized to the partner.

@author yfwz100 <yfwz100@yeah.net>

###

class GameSyncLogic

    # initialize the redis client.
    client = config.createRedis()

    # initialize the array of socket.io clients.
    gameObjects = {}

    # constrcuts a new logic object.
    constructor: (@socket) ->
        # the player's name.
        @name = null
        # the partner object.
        @partner = null

    # join the game.
    join: (@name) ->
        client.spopAsync 'endless:journey:waiting'
        .then (partnerName) =>
            unless @partner = gameObjects[partnerName]
                gameObjects[@name] = this
                client.saddAsync 'endless:journey:waiting', @name
            else
                @_ready 1, @partner
                @partner._ready 2, @

    # the game is ready.
    _ready: (@status, @partner) ->
        @socket.emit 'game:ready',
            status: @status
            player: @partner.name

    # send the message to the server.
    _send: (flag, content) ->
        @socket.emit flag, content

    # synchronize the game data.
    sync: (data) ->
        if @partner
            @partner._send 'game:play',
                player: @player
                game: data

    # end the game with data.
    over: (data) ->
        if @partner
            @partner._send 'game:over', data
        else
            console.debug data

module.exports = GameSyncLogic
