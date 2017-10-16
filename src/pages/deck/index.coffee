z = require 'zorium'

colors = require '../../colors'
Head = require '../../components/head'
AppBar = require '../../components/app_bar'
ButtonBack = require '../../components/button_back'
Deck = require '../../components/deck'

if window?
  require './index.styl'

module.exports = class DeckPage
  hideDrawer: true

  constructor: ({@model, requests, @router, serverData}) ->
    deck = requests.switchMap ({route}) =>
      @model.clashRoyaleDeck.getById route.params.id
    gameKey = requests.map ({route}) ->
      route.params.gameKey or config.DEFAULT_GAME_KEY

    @$head = new Head({
      @model
      requests
      serverData
      meta: {
        title: @model.l.get 'general.decks'
        description: @model.l.get 'general.decks'
      }
    })
    @$appBar = new AppBar {@model}
    @$buttonBack = new ButtonBack {@model, @router}
    @$deck = new Deck {@model, @router, deck, gameKey}

    @state = z.state
      deck: deck
      windowSize: @model.window.getSize()

  renderHead: => @$head

  render: =>
    {deck, windowSize} = @state.getValue()

    z '.p-deck', {
      style:
        height: "#{windowSize.height}px"
    },
      z @$appBar, {
        title: deck?.name
        style: 'primary'
        $topLeftButton: z @$buttonBack, {color: colors.$primary500}
        isFlat: true
        $topRightButton: null # FIXME
      }
      @$deck
