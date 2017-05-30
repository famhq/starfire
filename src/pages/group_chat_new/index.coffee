z = require 'zorium'
Rx = require 'rx-lite'
_find = require 'lodash/find'

Head = require '../../components/head'
GroupChat = require '../../components/group_chat'
AppBar = require '../../components/app_bar'
ButtonBack = require '../../components/button_back'
ProfileDialog = require '../../components/profile_dialog'
Ripple = require '../../components/ripple'
BottomBar = require '../../components/bottom_bar'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class GroupChatPage
  hideDrawer: true

  constructor: ({@model, requests, @router, serverData}) ->
    group = requests.flatMapLatest ({route}) =>
      @model.group.getById route.params.id

    conversationId = requests.map ({route}) ->
      route.params.conversationId

    overlay$ = new Rx.BehaviorSubject null
    selectedProfileDialogUser = new Rx.BehaviorSubject null
    me = @model.user.getMe()

    groupAndConversationIdAndMe = Rx.Observable.combineLatest(
      group
      conversationId
      me
      (vals...) -> vals
    )

    conversation = groupAndConversationIdAndMe
    .flatMapLatest ([group, conversationId, me]) =>
      hasMemberPermission = @model.group.hasPermission group, me
      conversationId ?= localStorage?['groupConversationId3:' + group.id]
      unless conversationId
        if me.country in ['RU', 'LV']
          conversationId = _find(group.conversations, {name: 'русский'})?.id
        if me.country in [
          'AR', 'BO', 'CR', 'CU', 'DM', 'EC', 'SV', 'GQ', 'GT', 'HN', 'MX'
          'NI', 'PA', 'PE', 'ES', 'UY', 'VE'
        ] or window?.navigator?.language?.split?('-')[0] is 'es'
          conversationId = _find(group.conversations, {name: 'español'})?.id
        else if me.country is 'FR'
          conversationId = _find(group.conversations, {name: 'francais'})?.id
        else if me.country is 'IT'
          conversationId = _find(group.conversations, {name: 'italiano'})?.id
        else if me.country in [
          'AE', 'EG', 'IQ', 'IL', 'SA', 'JO', 'SY',
          'YE', 'KW', 'OM', 'LY', 'MA', 'DZ', 'SD'
        ] or window?.navigator?.language?.split?('-')[0] is 'ar'
          conversationId = _find(group.conversations, {name: 'عربى'})?.id
        else
          conversationId = _find(group.conversations, {name: 'general'})?.id

        conversationId ?= group.conversations?[0].id
      if hasMemberPermission and conversationId
        @model.conversation.getById conversationId
      else
        Rx.Observable.just null

    @$head = new Head({
      @model
      requests
      serverData
      meta: {
        title: @model.l.get 'groupChatPage.title'
        description: @model.l.get 'groupChatPage.title'
      }
    })
    @$appBar = new AppBar {@model}
    @$buttonBack = new ButtonBack {@model, @router}
    @$titleRipple = new Ripple()
    @$bottomBar = new BottomBar {@model, @router, requests}

    @$groupChat = new GroupChat {
      @model
      @router
      group
      selectedProfileDialogUser
      overlay$
      conversation: conversation
    }
    @$profileDialog = new ProfileDialog {
      @model
      @router
      group
      selectedProfileDialogUser: selectedProfileDialogUser
    }


    @state = z.state
      windowSize: @model.window.getSize()
      group: group
      me: me
      overlay$: overlay$
      selectedProfileDialogUser: selectedProfileDialogUser
      conversation: conversation

  renderHead: => @$head

  render: =>
    {windowSize, overlay$, group, me, conversation
      selectedProfileDialogUser} = @state.getValue()

    hasMemberPermission = @model.group.hasPermission group, me
    hasAdminPermission = @model.group.hasPermission group, me, {level: 'admin'}

    z '.p-group-chat', {
      style:
        height: "#{windowSize.height}px"
    },
      z @$appBar, {
        title: z '.p-group-chat_title',
          z 'span.hashtag', '#'
          conversation?.name
        $topLeftButton: z @$buttonBack
        $topRightButton:
          z '.p-group_top-right',
            z '.icon',
              z @$settingsIcon,
                icon: 'settings'
                color: colors.$tertiary900
                onclick: =>
                  @router.go "/group/#{group?.id}/settings"
      }
      z '.content',
        @$groupChat

      @$bottomBar

      if overlay$
        z '.overlay',
          overlay$

      if selectedProfileDialogUser
        z @$profileDialog