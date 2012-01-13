# logs in, says hi, logs out
# HOST=mars.minefold.com MC_USERNAME=whatupdave MC_PASSWORD=meow coffee examples/hello-minecraft.coffee

Client = require('..').Client

delay = (ms, func) -> setTimeout func, ms

class HelloBot
  constructor: (host, port, username, password) ->
    console.log 'Connecting...'
    @client = new Client(port, host, username, password)
    
    @client.on 'connect', =>
      console.log 'Connected'
      
      delay 1000, =>
        @client.say 'Oh hai Minecraft!'
        
        delay 1000, => @client.disconnect()
  

host = process.env.HOST
port = parseInt(process.env.PORT, 10) || 25565
username = process.env.MC_USERNAME
password = process.env.MC_PASSWORD

helloBot = new HelloBot(host, port, username, password)
