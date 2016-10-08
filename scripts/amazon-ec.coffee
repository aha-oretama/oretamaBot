# Description
#   hubot scripts for amazon-product-api hubot
#
# Commands:
#   hubot kindle最新刊探して <title> - kindle 版の最新刊を検索して表示
#   hubot comic最新刊探して <title> - コミック(kindle除く)版の最新刊を検索して表示
#
# Author:
#   aha-oretama <sekine_y_529@msn.com>

OperationHelper = require('apac').OperationHelper
CronJob = require('cron').CronJob
moment = require 'moment'
_ = require 'lodash'

comicNode = "2278488051"

config =
  assocId: process.env.AWS_ASSOCIATE_ID,
  awsId: process.env.AWS_ID,
  awsSecret: process.env.AWS_SECRET
  locale: 'JP'
  xml2jsOptions: { explicitArray: true }

getOperationHelper = () ->
  unless operationHelper
    operationHelper = new OperationHelper config
  return operationHelper

search = (msg, operationHelper, query, isKindle, month, page) ->

  binding = if isKindle then 'kindle' else 'not kindle'

  operationHelper.execute('ItemSearch',{
    'SearchIndex': 'Books',
    'BrowseNode': comicNode,
    'Power':"title-begins:#{query} and pubdate:after #{month} and binding:#{binding}",
    'ResponseGroup':'Large',
    'Sort':'daterank',
    'ItemPage': page
  }).then((response) ->
    console.log "Raw response body: ", response.responseBody

    # 処理が速すぎるとときどき AWS API がエラーとなるため処理終了
    if response.result.ItemSearchResponse is undefined
      return

    baseResult = response.result.ItemSearchResponse.Items[0]

    totalResults = parseInt baseResult.TotalResults[0], 10
    totalPages = parseInt baseResult.TotalPages[0], 10
    items = baseResult.Item

    console.log totalResults
    console.log totalPages

    if totalResults is 0
      msg.send "#{query}は最近リリースされてないよー"
      return

    for item in items
      baseItem = item.ItemAttributes[0]
      msg.send "#{baseItem.Title[0]}が見つかったよー。発売日は #{if isKindle then baseItem.ReleaseDate[0] else baseItem.PublicationDate[0]}だよー #{item.DetailPageURL[0]}"

    if page < totalPages and page < 10
      setTimeout(search, 5000, msg, operationHelper, query,isKindle,month, page + 1)

  ).catch((err) ->
    console.log("error:", err)
  )

newReleaseSearch = (msg,query,isKindle) ->
  monthBeforeLast = moment().add(-2,'M').format('MM-YYYY')
  operationHelper = getOperationHelper()

  # 検索の実行
  search msg, operationHelper, query, isKindle ,monthBeforeLast, 1

module.exports = (robot) ->

  robot.respond /kindle最新刊(\S*) (\S+)$/i, (msg) ->
    newReleaseSearch msg, msg.match[2], true

  robot.respond /comic最新刊(\S*) (\S+)$/i, (msg) ->
    newReleaseSearch msg, msg.match[2], false

  robot.respond /kindle登録(\S*) (\S+)$/i, (msg) ->
    # 重複を除く
    original = robot.brain.get(msg.envelope.user.name)
    originalArray = if original then original.split(',') else []
    originalArray.push(msg.match[2])
    message = _.uniq(originalArray).join(",")

    # 保存
    robot.brain.set msg.envelope.user.name, message
    robot.brain.save()
    msg.send message

    for query in originalArray
      newReleaseSearch msg, query, true

  robot.respond /登録内容(\S*)/i, (msg) ->
    # 呼び出し
    msg.send robot.brain.get(msg.envelope.user.name)
