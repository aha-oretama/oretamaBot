# Description:
#   Generates help commands for Hubot.
#
# Commands:
#   hubot "help"|"ヘルプ"|"使い方"|"教えて" - 使い方を教えてあげるよー
#
# Notes:
#   These commands are grabbed from comment blocks at the top of each file.

module.exports = (robot) ->

  robot.respond /help|ヘルプ|使い方|教えて/i, (msg) ->
    cmds = renamedHelpCommands(robot)

    for cmd in cmds
      msg.send cmd

renamedHelpCommands = (robot) ->
  robot_name = robot.alias or robot.name
  help_commands = robot.helpCommands().map (command) ->
    command.replace /^hubot/i, robot_name
  help_commands.sort()
