bluebird = require 'bluebird'
config   = require './config'

###

The ranking class. It provides a uniform interface to fetch data related to ranking.

@author yfwz100 <yfwz100@yeah.net>

###
class Ranking

    # initialize the redis server.
    client = config.createRedis()

    to_sorted_array = (arr) ->
        retval = []
        for i in [0..arr.length-1] by 2
            retval.push([arr[i], arr[i + 1]])
        retval

    # construct a new ranking with mode default to 'test'.
    constructor: (@mode = 'test') ->

    # add the data to ranking.
    addToRanking: (data) ->
        bluebird.all [
            client.zaddAsync "endless:journey:#{@mode}:meter", data.meter, data.id
            client.zaddAsync "endless:journey:#{@mode}:score", data.score, data.id
            client.zaddAsync "endless:journey:#{@mode}:coins", data.coins, data.id
        ]
    
    # fetch the ranking of all players.
    fetchRankings: () ->
        bluebird.all [
            client.zrevrangeAsync "endless:journey:#{@mode}:meter", 0, 10, 'WITHSCORES'
            client.zrevrangeAsync "endless:journey:#{@mode}:score", 0, 10, 'WITHSCORES'
            client.zrevrangeAsync "endless:journey:#{@mode}:coins", 0, 10, 'WITHSCORES'
        ]
        .spread (meter_list, score_list, coins_list) ->
            meter: to_sorted_array meter_list
            score: to_sorted_array score_list
            coins: to_sorted_array coins_list

    # fetch the ranking of a specific player.
    fetchRanking: (key) ->
        bluebird.all [
            client.zrankAsync "endless:journey:#{@mode}:meter", key
            client.zrankAsync "endless:journey:#{@mode}:score", key
            client.zrankAsync "endless:journey:#{@mode}:coins", key
        ]
        .spread (meter_list, score_list, coins_list) ->
            meter: to_sorted_array meter_list
            score: to_sorted_array score_list
            coins: to_sorted_array coins_list

module.exports = Ranking