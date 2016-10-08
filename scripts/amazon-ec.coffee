# Description
#   hubot scripts for amazon-product-api hubot
#
# Commands:
#   hubot kindle最新刊探して <title> - kindle 版の最新刊を検索して表示
#   hubot comic最新刊探して <title> - コミック(kindle除く)版の最新刊を検索して表示
#   hubot kindle登録して <title> - kindle 版の最新刊を探す条件を保存する
#   hubot comic登録して <title> - comic 版の最新刊を探す条件を保存する
#   hubot 登録内容教えて - 登録内容を表示する
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
      msg.send "#{baseItem.Title[0]}が見つかったよー。¥n発売日は #{if isKindle then baseItem.ReleaseDate[0] else baseItem.PublicationDate[0]}だよー¥n#{item.DetailPageURL[0]}"

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
    message = msg.match[2]
    originalArray = robot.brain.get(msg.envelope.user.name) ? []

    # 重複を除く
    if !originalArray.filter((item) -> item.title is message).length
      originalArray.push({title: message, kindle: true})

    # 保存
    robot.brain.set msg.envelope.user.name, originalArray
    robot.brain.save()

    msg.send "登録内容は" + originalArray.reduce((previous, current) -> {title:"#{previous.title},#{current.title}"}).title

  robot.respond /登録内容(\S*)/i, (msg) ->
    # 呼び出し
    msg.send robot.brain.get(msg.envelope.user.name)
