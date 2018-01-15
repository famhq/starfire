z = require 'zorium'
_map = require 'lodash/map'

Icon = require '../icon'
ChannelList = require '../channel_list'
colors = require '../../colors'

if window?
  require './index.styl'

DRAWER_RIGHT_PADDING = 56
DRAWER_MAX_WIDTH = 336

module.exports = class ChannelDrawer
  constructor: ({@model, @router, @isOpen, group, conversation}) ->
    me = @model.user.getMe()

    @$channelList = new ChannelList {
      @model
      @router
      conversations: group.map (group) -> group.conversations
    }
    @$manageChannelsSettingsIcon = new Icon()

    @state = z.state
      isOpen: @isOpen
      group: group
      conversation: conversation
      me: @model.user.getMe()

  render: =>
    {isOpen, group, me, conversation} = @state.getValue()

    hasAdminPermission = @model.group.hasPermission group, me, {level: 'admin'}

    z '.z-channel-drawer', {
      onclick: =>
        @isOpen.next false
    },
      z '.drawer', {
        onclick: (e) ->
          e?.stopPropagation()
      },
        z '.title', @model.l.get 'channelDrawer.title'

        z @$channelList, {
          selectedConversationId: conversation?.id
          onclick: (e, {id}) =>
            @router.go 'groupChatConversation', {
              groupId: group?.key or group?.id, conversationId: id
            }, {ignoreHistory: true}
            @isOpen.next false
        }

        if hasAdminPermission
          [
            z '.divider'
            z '.manage-channels', {
              onclick: =>
                @router.go 'groupManageChannels', {
                  id: group?.key or group?.id
                }
            },
              z '.icon',
                z @$manageChannelsSettingsIcon,
                  icon: 'settings'
                  isTouchTarget: false
                  color: colors.$primary500
              z '.text', 'Manage channels'
          ]
