# Description
#   hubot scripts for diagnosing hubot
#
# Commands:
#   hubot "ping"|"おーい|"おーい？"|"おい"|"おい？"|"生きてる？"|"生きている？"|"大丈夫？" - "なに～？"
#   hubot "date"|"日にち"|"何日" - 今日が何日か教えてあげるよー
#   hubot "day"|"曜日" - 今日が何曜日か教えてあげるよー
#   hubot "time"|"時間"|"何時" - 今が何時か教えてあげるよー
#
# Author:
#   aha-oretama <sekine_y_529@msn.com>

moment = require('moment')
moment.locale('ja')

module.exports = (robot) ->
  robot.respond /PING$|(おーい|おい|生きてる|生きている|大丈夫)(\?|？)*$/i, (msg) ->
    msg.send "なに～？"

  robot.respond /DATE$|.*日にち|.*何日/i, (msg) ->
    msg.send "今日は#{moment().format("YYYY年M月D日")}だよー"

  robot.respond /day$|.*曜日/i, (msg) ->
    msg.send "今日は#{moment().format("dddd")}だよー"

  robot.respond /TIME$|.*時間|.*何時/i, (msg) ->
    msg.send "いまは#{moment().format("HH:mm")}だよー"

