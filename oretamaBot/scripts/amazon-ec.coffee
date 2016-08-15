# Description
#   hubot scripts for amazon-product-api hubot
#
# Commands:
#   hubot "考え中" - "考え中"
#
# Author:
#   aha-oretama <sekine_y_529@msn.com>

OperationHelper = require('apac').OperationHelper
CronJob = require('cron').CronJob
moment = require 'moment'

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

search = (msg, operationHelper, query, isKindle, during, page) ->

  binding = if isKindle then 'kindle' else 'not kindle'

  operationHelper.execute('ItemSearch',{
    'SearchIndex': 'Books',
    'BrowseNode': comicNode,
    'Title': query,
#    'Power':"pubdate:#{during} and binding:#{binding}",
    'Power':"pubdate:during 08-2016 or pubdate:during 07-2016 and binding:#{binding}",
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
      msg.send "#{baseItem.Title[0]}が見つかったよー\n発売日は #{if isKindle then baseItem.ReleaseDate[0] else baseItem.PublicationDate[0]}だよ #{item.DetailPageURL[0]}"

    if page < totalPages and page < 10
      setTimeout(search, 5000, msg, operationHelper, query,isKindle,during, page + 1)

  ).catch((err) ->
    console.log("error:", err)
  )

newReleaseSearch = (msg,isKindle) ->
  query = msg.match[1]
  lastMonth = moment().add(-1,'M').format('MM-YYYY')
  thisMonth = moment().format('MM-YYYY')
  nextMonth = moment().add(1,'M').format('MM-YYYY')
  during = "(during #{lastMonth} or during #{thisMonth} or during #{nextMonth})"

  operationHelper = getOperationHelper()
  search msg, operationHelper, query, isKindle ,during, 1

module.exports = (robot) ->

  robot.respond /kindle最新刊 (\S+)$/i, (msg) ->
    newReleaseSearch msg, true

  robot.respond /comic最新刊 (\S+)$/i, (msg) ->
    newReleaseSearch msg, false

#  new CronJob('*/5 * * * * *', () ->
#    releaseList = []
#    releaseList.push(search [], operationHelper, 1)
#    robot.send releaseList
#  ).start()
