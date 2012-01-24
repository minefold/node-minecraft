# Logs in and listens to chat.
# $ coffee examples/perv.coffee pluto.minefold.com 25565 whatupdave password

mc = require('..')
[_, _, host, port, username, password] = process.argv

mc.createOnlineClient host, port, username, password, (perv) ->
  console.warn "#{username} connected to #{host}:#{port}"

  perv.on 'chat', (msg) ->
    console.log msg
