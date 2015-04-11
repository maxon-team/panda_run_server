bluebird = require 'bluebird'
redis = bluebird.promisifyAll require 'redis'

# create a new instance of redis client.
exports.createRedis = ->
    REDIS_SERVER = process.env.REDIS_SERVER or '127.0.0.1'
    REDIS_PORT = process.env.REDIS_PORT or 6379
    REDIS_PASSWORD = process.env.REDIS_PASSWORD or ''
    client = redis.createClient(REDIS_PORT, REDIS_SERVER)
    client.auth REDIS_PASSWORD, (err) ->
    	console.trace err if err
    client
