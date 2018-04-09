z = require 'zorium'
Environment = require '../../services/environment'
_map = require 'lodash/map'
_filter = require 'lodash/filter'
_find = require 'lodash/find'
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/observable/combineLatest'
require 'rxjs/operator/map'
require 'rxjs/operator/switchMap'

Base = require '../base'
Icon = require '../icon'
Spinner = require '../spinner'
CurrencyIcon = require '../currency_icon'
PrimaryButton = require '../primary_button'
FormatService = require '../../services/format'
colors = require '../../colors'
config = require '../../config'

if window?
  require './index.styl'

# TODO: make it clear that they earn currency for sticker packs

module.exports = class GroupEarnCurrency
  constructor: ({@model, @router, group}) ->
    @$spinner = new Spinner()

    currencyActions = group.switchMap (group) =>
      @model.earnAction.getAllByGroupId group.id
      .map (actions) =>
        _map actions, (action) =>
          currencyReward = _find action.data.rewards, {currencyType: 'item'}
          currencyItemKey = currencyReward?.currencyItemKey
          {
            action: action
            $claimButton: new PrimaryButton()
            $currencyIcon: new CurrencyIcon {itemKey: currencyItemKey}
          }
    me = @model.user.getMe()

    groupAndMe = RxObservable.combineLatest(
      group
      me
      (vals...) -> vals
    )

    @state = z.state
      me: me
      group: group
      meGroupUser: groupAndMe.switchMap ([group, me]) =>
        @model.groupUser.getByGroupIdAndUserId group.id, me.id
      currencyActions: currencyActions
      loadingAction: null

  visit: (e) =>
    {group} = @state.getValue()
    @state.set loadingAction: 'visit'
    @model.earnAction.incrementByGroupIdAndAction(
      group.id, 'visit'
    )
    .catch -> null
    .then (rewards) =>
      $$button = e?.target
      if $$button
        boundingRect = $$button.getBoundingClientRect?()
        x = boundingRect?.left + boundingRect?.width / 2
        y = boundingRect?.top
      else
        x = e?.clientX
        y = e?.clientY
      @model.earnAlert.show {rewards, x, y}
      @state.set loadingAction: null

  playAd: =>
    {loadingAction, group} = @state.getValue()
    unless loadingAction is 'watchAd'
      @state.set loadingAction: 'watchAd'
      @model.portal.call 'admob.prepareRewardedVideo', {
        adId: if Environment.isiOS() \
              then 'ca-app-pub-9043203456638369/5979905134'
              else 'ca-app-pub-9043203456638369/8896044215'
      }
      .then =>
        timestamp = Date.now()
        @model.portal.call 'admob.showRewardedVideo', {timestamp}
        .then (successKey) =>
          @state.set loadingAction: null
          @model.earnAction.incrementByGroupIdAndAction(
            group.id, 'watchAd', {timestamp, successKey}
          )
      .catch =>
        @state.set loadingAction: null

  render: =>
    {me, currencyActions, loadingAction, meGroupUser} = @state.getValue()

    z '.z-group-earn-currency',
      z '.g-grid',
        z '.g-cols',
        _map currencyActions, ({action, $claimButton, $currencyIcon}) =>
          isLoading = loadingAction is action.action
          countLeft = action.maxCount - (action.transaction?.count or 0)
          isClaimed = not countLeft

          z '.g-col.g-xs-12.g-md-6',
            z '.action',
              z '.rewards',
                _map action.data.rewards, (reward) ->
                  z '.reward',
                    z '.text', reward.currencyAmount
                    z '.icon',
                      if reward.currencyType is 'xp'
                        'xp'
                      else
                        z $currencyIcon, {size: '16px'}
              z '.title',
                if action.data.nameKey
                  @model.l.get action.data.nameKey
                else
                  action.name
                if countLeft > 1
                  " (#{countLeft})"
              z '.button',
                if isClaimed
                  'Claimed'
                else
                  z $claimButton,
                    text: if isLoading \
                          then @model.l.get 'general.loading'
                          else if action.data.button.textKey
                          then @model.l.get action.data.button.textKey
                          else action.data.button.text
                    onclick: (e) =>
                      route = action.data.button.route
                      if action.action is 'watchAd'
                        @playAd()
                      else if action.action is 'visit'
                        @visit e
                      else if route
                        @router.go route.key, route.replacements