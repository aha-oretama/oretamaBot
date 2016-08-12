# Description:
#  Continue to search query on Twitter and to tweets.
#
# Dependencies:
#   "twit": "1.1.x"
#
# Configuration:
#   HUBOT_TWITTER_CONSUMER_KEY
#   HUBOT_TWITTER_CONSUMER_SECRET
#   HUBOT_TWITTER_ACCESS_TOKEN
#   HUBOT_TWITTER_ACCESS_TOKEN_SECRET
#
# Commands:
#   hubot ツイート流して <query> - Continue to search Twitter for a query and to tweet
#   hubot ツイート止めて - Stop to tweet
#
# Author:
#   aha-oretama <sekine_y_529@msn.com>
#

Twit = require "twit"

config =
  consumer_key: process.env.HUBOT_TWITTER_CONSUMER_KEY
  consumer_secret: process.env.HUBOT_TWITTER_CONSUMER_SECRET
  access_token: process.env.HUBOT_TWITTER_ACCESS_TOKEN
  access_token_secret: process.env.HUBOT_TWITTER_ACCESS_TOKEN_SECRET

twit = undefined

getTwit = ->
  unless twit
    twit = new Twit config
  return twit

doSearch = (msg) ->
  query = msg.match[2]
  return if !query

  twit = getTwit()
  count = 5
  searchConfig =
    q: "#{query}",
    count: count,
    lang: 'en',
    result_type: 'recent'

  twit.get 'search/tweets', searchConfig, (err, reply) ->
    return msg.send "Error retrieving tweets!" if err
    return msg.send "No results returned!" unless reply?.statuses?.length

    statuses = reply.statuses
    response = ''
    i = 0
    for status, i in statuses
      response += "**@#{status.user.screen_name}**: #{status.text}"
      response += "\n" if i != count-1

    return msg.send response

doUser = (msg) ->
  username = msg.match[2]
  return if !username

  twit = getTwit()
  count = 5
  searchConfig =
    screen_name: username,
    count: count

  twit.get 'statuses/user_timeline', searchConfig, (err, statuses) ->
    return msg.send "Error retrieving tweets!" if err
    return msg.send "No results returned!" unless statuses?.length

    response = ''
    i = 0
    msg.send "Recent tweets from #{statuses[0].user.screen_name}"
    for status, i in statuses
      response += "#{status.text}"
      response += "\n" if i != count-1

    return msg.send response

doTweet = (msg, tweet) ->
  return if !tweet
  tweetObj = status: tweet
  twit = getTwit()
  twit.post 'statuses/update', tweetObj, (err, reply) ->
    if err
      msg.send "Error sending tweet!"
    else
      username = reply?.user?.screen_name
      id = reply.id_str
      if (username && id)
        msg.send "https://www.twitter.com/#{username}/status/#{id}"

module.exports = (robot) ->
  robot.respond /ツイート流して (\S+)$/i, (msg) ->

    screen_name = msg.match[1]
    query = msg.match[2]

    username = reply?.user?.screen_name

    subscriptionManager.ensureSubscribedTo msg.message.user.reply_to, screen_name, (err) ->
      if err?
        msg.reply "Something went wrong: #{err}"
      else
        msg.reply "Great! Anytime @#{screen_name} tweets, I'll post it here."

  robot.respond /ツイート止めて/i, (msg) ->
    screen_name = msg.match[1]
    subscriptionManager.ensureUnsubscribedFrom msg.message.user.reply_to, screen_name, (err) ->
      if err?
        msg.reply "Something went wrong: #{err}"
      else
        msg.reply "Roger that! I won't post tweets from @#{screen_name} anymore."
