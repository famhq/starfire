z = require 'zorium'
_map = require 'lodash/map'

Base = require '../base'
Spinner = require '../spinner'
ThreadListItem = require '../thread_list_item'
UiCard = require '../ui_card'
config = require '../../config'

if window?
  require './index.styl'

module.exports = class GroupHomeThreads extends Base
  constructor: ({@model, @router, group, player, @overlay$}) ->
    me = @model.user.getMe()

    @$spinner = new Spinner()
    @$uiCard = new UiCard()

    @state = z.state {
      group
      language: @model.l.getLanguage()
      $threads: group.switchMap (group) =>
        @model.thread.getAll {
          groupId: group?.id
          category: 'all'
          sort: 'popular'
          limit: 3
        }
      .map (threads) =>
        _map threads, (thread) =>
          @getCached$ "thread-#{thread.id}", ThreadListItem, {
            @model, @router, thread, group
          }
    }

  beforeUnmount: ->
    super()

  render: =>
    {group, $threads} = @state.getValue()

    z '.z-group-home-threads',
      z @$uiCard, {
        $title: @model.l.get 'groupHome.topForumThreads'
        minHeightPx: 354
        $content:
          z '.z-group-home_ui-card',
            _map $threads, ($thread) ->
              z '.list-item',
                z $thread, {hasPadding: false}
        submit:
          text: @model.l.get 'general.viewAll'
          onclick: =>
            @router.go 'groupForum', {groupId: group.key or group.id}
      }