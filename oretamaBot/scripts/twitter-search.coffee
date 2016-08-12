# Description:
#  Continue to search query on Twitter and to tweets.
#
# Dependencies:
#   "twit": "1.1.x"
#
# Configuration:
#   HUBOT_TWITTER_KEY
#   HUBOT_TWITTER_SECRET
#   HUBOT_TWITTER_TOKEN
#   HUBOT_TWITTER_TOKEN_SECRET
#
# Commands:
#   hubot ツイート流して <query> - Continue to search Twitter for a query and to tweet
#   hubot ツイート止めて - Stop to tweet
#
# Author:
#   aha-oretama <sekine_y_529@msn.com>
#

Twit = require 'twit'

config =
  consumer_key: process.env.HUBOT_TWITTER_KEY
  consumer_secret: process.env.HUBOT_TWITTER_SECRET
  access_token: process.env.HUBOT_TWITTER_TOKEN
  access_token_secret: process.env.HUBOT_TWITTER_TOKEN_SECRET


getTwit = ->
  unless twit
    twit = new Twit config
  return twit

module.exports = (robot) ->
  twit = undefined
  stream = undefined

  robot.respond /ツイート流して (\S+)$/i, (msg) ->
    query = msg.match[1]
    twit = getTwit()

    stream.stop() if stream
    stream = twit.stream('statuses/filter', { track: query,language: 'ja' })

    msg.send 'ツイート流すよー'

    stream.on 'tweet', (tweet) ->
      msg.send "#{query}見つかったよー\n\nhttps://twitter.com/#{tweet.user.screen_name}/status/#{tweet.id_str}"
    stream.on "disconnect", (disconnectMessage) ->
      msg.send "ツイート流すが切れたー。理由: #{disconnectMessage}"
    stream.on "reconnect", (request, response, connectInterval) ->
      msg.send "ちょっと切れちゃった。再開は #{connectInterval}ミリ秒後"

  robot.respond /ツイート止めて/i, (msg) ->
    stream.stop() if stream
    msg.send 'ツイート止めたよー'
