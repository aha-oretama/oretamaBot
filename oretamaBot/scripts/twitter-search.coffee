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
#   hubot ツイート流して <query> - 指定したツイートが流れたら教えてあげるよー
#   hubot ツイート止めて - ツイートを教えるのを止めるよー
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

createStream = (robot, msg, twit, stream, user, queryAndUser) ->
  newQuery = []
  queryAndUser.forEach (query) ->
    newQuery = newQuery.concat(query)

  # TODO: アンド検索ができない
  stream.stop() if stream
  stream = twit.stream('statuses/filter', { track: newQuery,language: 'ja' })

  console.log queryAndUser

  stream.on 'tweet', (tweet) ->
    queryAndUser.forEach (itemQueries, itemUser) ->
      for itemQuery in itemQueries
        # 複数ユーザ、複数ワードの同時検索に対応
        if tweet.text.includes(itemQuery) and user is itemUser
          sendMessage robot, msg, itemUser, "#{itemQuery}見つかったよー  https://twitter.com/#{tweet.user.screen_name}/status/#{tweet.id_str}" unless tweet.user.screen_name is 'oretamaBot'

  stream.on 'disconnect', (disconnectMessage) ->
    queryAndUser.forEach (itemQueries, itemUser) ->
      sendMessage robot, msg, itemUser "ツイート流すが切れたー。理由: #{disconnectMessage}"
  stream.on 'reconnect', (request, response, connectInterval) ->
    queryAndUser.forEach (itemQueries, itemUser) ->
      sendMessage robot, msg, itemUser, "ちょっと切れちゃった。再開は #{connectInterval/1000}秒後"

  return stream

sendMessage = (robot, msg, user, message) ->
  if typeof robot is 'Twitter'
    msg.command "@#{item.user}" + message
  else
    msg.send message


module.exports = (robot) ->
  twit = undefined
  stream = undefined
  queryAndUser = new Map()

  robot.respond /ツイート流して (\S+)$/i, (msg) ->
    query = msg.match[1]
    user = msg.envelope.user.name
    twit = getTwit()

    oldQuery = queryAndUser.get(user)
    if oldQuery is undefined
      queryAndUser.set(user,[query])
    else
      oldQuery.push(query)
      queryAndUser.set(user, oldQuery)

    # ツイートの検索開始
    stream = createStream(robot,msg,twit, stream, user, queryAndUser)

    msg.send 'ツイート流すよー'


  robot.respond /ツイート止めて/i, (msg) ->
    user = msg.envelope.user.name
    queryAndUser.delete(user)

    if queryAndUser.size is 0
      stream.stop() if stream
      stream = undefined
    else
      # 対象ユーザを除いてツイートの検索開始
      stream = createStream(robot,msg,twit, stream, user, queryAndUser)

    msg.send 'ツイート止めたよー'
