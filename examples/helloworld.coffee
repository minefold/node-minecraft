# Logs in and says hello.
# $ coffee examples/helloworld.coffee pluto.minefold.com 25565 whatupdave password

mc = require('..')
[_, _, host, port, username, password] = process.argv

mc.createOnlineClient host, port, username, password, (bot) ->
  bot.say 'Hello world!', ->
    bot.end()
