### 
RobotQUEST AI
###

# On any error: I want to log the error, then exit and reconnect. (Throw the error)

request = require 'request'
{clone, map, find, compose, isEqual, bind, extend} = require 'underscore'
{curry} = require './curry'

HOST = process.env.HOST || "http://localhost:3026"
AINAME = "AI"
REPO = "http://github.com/seanhess/botland"

MIN_MONSTERS = 5

start = (host) ->

  player =
    name: AINAME
    source: REPO

  bots = []

  # standard error handling 
  # should cause everything to exit
  onError = (err) ->
    throw err

  api = robotQuestApi host, onError

  ## START 
  api.gameInfo (info) ->

    api.createPlayer player, (data) ->
      player.id = data.id

      poll = ->
        api.objects (objects) ->
          tick objects

      setInterval poll, info.tick

      ## MONSTER ACTONS
      # api: the api
      # objects: the world
      # player: the player
      # bot: the bot
      # info: the game info


      act = (objects, bot) ->
        ai = find ais, (a) -> a.name() is bot.name
        ai.act api, info, player, objects, bot

      ## MAIN GAME
      # objects: the world
      tick = (objects) ->

        # update all our bots with info from the server
        bots = objects.filter(isAi).map (newBot) ->
          bot = find bots, compose(eq(newBot.id), id)
          extend(bot ? {}, newBot)

        if bots.length < MIN_MONSTERS
          x = random info.width
          y = random info.height
          type = randomElement ais
          spawn(x, y, type.sprite(), type.name())

        bots.forEach (bot) ->
          act objects, bot

      # SPAWN
      spawn = (x, y, sprite, name) ->
        bot = {x, y, sprite, name}
        api.createMinion player, bot, ->


## HELPERS
isAi = (bot) -> bot.player == AINAME

random = (n) -> Math.floor(Math.random() * n)
randomElement = (vs) -> vs[random(vs.length)]

## AI!

# RAT (boring little guys, they never attack, they don't move that much!)
rat =
  name: -> "rat"
  sprite: -> randomElement ["monster1-0-4", "monster1-1-4", "monster1-2-4", "monster1-3-4"]
  act: (api, info, player, objects, bot) ->
    direction = randomElement ["Up", "Down", "Left", "Right"]
    action = randomElement ["Stop", "Stop", "Move"]
    api.command player, bot, {action, direction}, ->


# ORC: will attach you if you are next to it. Move randomly
orc =
  name: -> "orc"
  sprite: -> randomElement ["monster1-0-2", "monster1-1-2", "monster1-5-1"]
  act: (api, info, player, objects, bot) ->
    direction = randomElement ["Up", "Down", "Left", "Right"]
    action = randomElement ["Stop", "Stop", "Move"]
    api.command player, bot, {action, direction}, ->



# TROLL: Will hunt anyone down within X spaces



# MAGE: will hunt down the person with the most kills. At the top of the leaderboard :) Booyah!

ais = [rat, orc]

## API
robotQuestApi = (host, onError) ->

  respond = (cb, checkStatus = true) ->
    (err, rs, body) ->
      if err? then return onError err
      if checkStatus and rs.statusCode != 200
        return onError new Error body.message
      cb body

  gameInfo: (cb) ->
    request.get {url: host + "/game/info", json: true}, respond cb

  objects: (cb) ->
    request.get {url: host + "/game/objects", json: true}, respond cb

  createPlayer: (player, cb) ->
    request.post {url: host + "/players", json: player}, respond cb

  createMinion: (player, minion, cb) ->
    request.post {url: host + "/players/" + player.id + "/minions", json: minion}, respond(cb, false)

  command: (player, minion, command, cb) ->
    request.post {url: host + "/players/" + player.id + "/minions/" + minion.id + "/command", json: command}, respond cb




val = curry (key, obj) -> obj[key]
eq = curry (a, b) -> a == b
id = (obj) -> obj.id

if module == require.main
  start HOST
  

