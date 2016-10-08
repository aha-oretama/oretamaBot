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
cronJob = require('cron').CronJob
moment = require 'moment'
_ = require 'lodash'

class AmazonSearch
  comicNode = "2278488051"
  @operationHelper

  constructor: (associateId,id,secret)->  # コンストラクタ
    config =
      assocId: associateId
      awsId: id
      awsSecret: secret
      locale: 'JP'
      xml2jsOptions: { explicitArray: true }

    this.operationHelper = new OperationHelper(config)

  search: (query, isKindle, page, callback, nothingCallBack) ->

    binding = if isKindle then 'kindle' else 'not kindle'
    month = moment().add(-2,'M').format('MM-YYYY')

    this.operationHelper.execute('ItemSearch',{
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

      if totalResults is 0
        nothingCallBack
        return

      for item in items
        baseItem = item.ItemAttributes[0]
        callback {
          title: baseItem.Title[0],
          releaseDate: if isKindle then baseItem.ReleaseDate[0] else baseItem.PublicationDate[0],
          url: item.DetailPageURL[0]
        }

      if page < totalPages and page < 10
        setTimeout(this.search, 5000, query,isKindle, page + 1,callback, nothingCallBack)

    ).catch((err) ->
      console.log("error:", err)
    )


amazonSearch = new AmazonSearch(process.env.AWS_ASSOCIATE_ID, process.env.AWS_ID, process.env.AWS_SECRET)

newReleaseSearch = (msg,query,isKindle) ->
  # 検索の実行
  amazonSearch.search(query, isKindle, 1,
    ((item) -> msg.send "#{item.title}が見つかったよー。¥n発売日は #{item.releaseDate}だよー¥n#{item.url}"),
    (() -> msg.send "#{query}は最近リリースされてないよー")
  )

nexWeekSearch = (msg, query , isKindle) ->
  nextWeek = moment().add(+1,'w').format('YYYY-MM-DD')
  futureTimeSearch(msg,query,isKindle, nextWeek)

tomorrowSearch = (msg, query , isKindle) ->
  nextDay = moment().add(+1,'d').format('YYYY-MM-DD')
  futureTimeSearch(msg,query,isKindle, nextDay)

futureTimeSearch = (msg, query, isKindle, time) ->
  amazonSearch.search(query, isKindle , 1,
    ((item) -> msg.send "#{item.title}が発売されるよ。¥n発売日は #{item.releaseDate}だよー¥n#{item.url}" if item.releaseDate is time)
  )


module.exports = (robot) ->

  # 起動時にクーロン設定
  send = (name,msg) ->
    response = new robot.Response(robot, {user : {id : -1, name : name}, text : "none", done : false}, [])
    response.send "TODO"

  # *(sec) *(min) *(hour) *(day) *(month) *(day of the week)
  new cronJob('0 * * * * *', () ->
    currentTime = new Date
    send ""
  ).start()

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

