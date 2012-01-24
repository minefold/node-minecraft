# node-minecraft

by [Chris Lloyd](http://github.com/chrislloyd) & [Dave Newman](http://github.com/whatupdave) @ [Minefold](https://minefold.com)

Provides an implementation of the Minecraft protocol for Node.js that can be used for both client and server hacking.


## Installation

You need [Node.js](nodejs.org) and [NPM](npmjs.org) installed first.

    $ npm install node-minecraft


## Writing Bots

It's best to check out `examples/helloworld.coffee` and `examples/perv.coffee`. They are both small bots that successfully connect to a world and serve some function. Let's run through a simple echo bot. All it does is repeat any chat messages it hears.

    # Loads the library
    mc = require 'node-minecraft'

    # This creates a new client
    mc.createOnlineClient host, port, username, password, (bot) ->

      # 'chat' is an event that is fired when a chat message is recieved
      bot.on 'chat', (msg) ->
        # `say` writes a string back for everybody to see.
        bot.say msg

Dead simple!

## FAQ

### Why `createOnlineClient`?

Minecraft checks that you have bought a copy of the game before you can play online. This why the library needs your password. You'll need to use that method if you are putting your bot into public servers who are in `online-mode`.

If you have a local server that is in offline mode you can use the `createOfflineClient` that doesn't validate with Mojang. This is best for testing and spinning up lots of bots locally.

### Why does the bot just float there?

Minecraft works by each client calculating where it is suppose to be. The bot at the moment is too dumb to know about gravity, so it doesn't move. However, in future versions of `node-minecraft` we want to make the bots more intelligent. Perhaps you could contribute that?
