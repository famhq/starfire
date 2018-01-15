z = require 'zorium'
_map = require 'lodash/map'
_filter = require 'lodash/filter'
_take = require 'lodash/take'
_isEmpty = require 'lodash/isEmpty'
_orderBy = require 'lodash/orderBy'
_clone = require 'lodash/clone'
Environment = require 'clay-environment'
RxObservable = require('rxjs/Observable').Observable
require 'rxjs/add/observable/combineLatest'
require 'rxjs/add/operator/map'

Icon = require '../icon'
FlatButton = require '../flat_button'
AdsenseAd = require '../adsense_ad'
ClanBadge = require '../clan_badge'
GroupBadge = require '../group_badge'
SemverService = require '../../services/semver'
Ripple = require '../ripple'
colors = require '../../colors'
config = require '../../config'

if window?
  IScroll = require 'iscroll/build/iscroll-lite-snap.js'
  require './index.styl'

GROUPS_IN_DRAWER = 2
MAX_OVERLAY_OPACITY = 0.5

module.exports = class Drawer
  constructor: ({@model, @router, group, @overlay$}) ->
    @transformProperty = window?.getTransformProperty()
    @$adsenseAd = new AdsenseAd {@model}
    @$groupBadge = new GroupBadge {@model, group}

    me = @model.user.getMe()
    meAndGroupAndLanguage = RxObservable.combineLatest(
      me
      group
      @model.l.getLanguage()
      (vals...) -> vals
    )

    myGroups = me.switchMap (me) =>
      @model.group.getAllByUserId me.id
    groupAndMyGroups = RxObservable.combineLatest(
      group
      myGroups
      me
      (vals...) -> vals
    )

    userAgent = navigator?.userAgent
    needsApp = userAgent and
                not Environment.isGameApp(config.GAME_KEY, {userAgent}) and
                not window?.matchMedia('(display-mode: standalone)').matches

    @state = z.state
      isOpen: @model.drawer.isOpen()
      language: @model.l.getLanguage()
      me: me
      expandedItems: []
      group: group
      myGroups: groupAndMyGroups.map (props) =>
        [group, groups, me] = props
        groups = _orderBy groups, (group) =>
          @model.cookie.get("group_#{group.id}_lastVisit") or 0
        , 'desc'
        if group # current group, show up top
          groups = _filter groups, ({id}) ->
            id isnt group.id
          groups = [group].concat groups
        groups = _take(groups, GROUPS_IN_DRAWER)
        _map groups, (group, i) =>
          meGroupUser = group.meGroupUser
          {
            group
            $badge: if group.clan \
                    then new ClanBadge {@model, clan: group.clan}
                    else new GroupBadge {@model, group}
            $chevronIcon: new Icon()
            $ripple: new Ripple()
          }
      windowSize: @model.window.getSize()
      drawerWidth: @model.window.getDrawerWidth()
      breakpoint: @model.window.getBreakpoint()

      menuItems: meAndGroupAndLanguage.map ([me, group, language]) =>
        groupId = group.key or group.id
        meGroupUser = group.meGroupUser
        _filter([
          {
            path: @router.get 'groupHome', {groupId}
            title: @model.l.get 'general.home'
            $icon: new Icon()
            $ripple: new Ripple()
            iconName: 'home'
            isDefault: true
          }
          {
            path: @router.get 'groupChat', {groupId}
            title: @model.l.get 'general.chat'
            $icon: new Icon()
            $ripple: new Ripple()
            iconName: 'chat'
          }
          if language in config.COMMUNITY_LANGUAGES and
              group.key isnt 'playhard' and group.type is 'public'
            {
              path: @router.get 'groupForum', {groupId}
              title: @model.l.get 'general.forum'
              $icon: new Icon()
              $ripple: new Ripple()
              iconName: 'rss'
            }
          {
            path: @router.get 'groupShop', {groupId}
            # title: @model.l.get 'general.shop'
            title: @model.l.get 'general.freeStuff'
            $icon: new Icon()
            iconName: 'shop'
          }
          {
            path: @router.get 'groupCollection', {groupId}
            title: @model.l.get 'collectionPage.title'
            $icon: new Icon()
            iconName: 'cards'
          }
          if group.key is 'playhard'
            {
              path: @router.get 'groupVideos', {groupId}
              title: @model.l.get 'videosPage.title'
              $icon: new Icon()
              iconName: 'video'
            }
          {
            path: @router.get 'groupLeaderboard', {groupId}
            title: @model.l.get 'groupLeaderboardPage.title'
            $icon: new Icon()
            iconName: 'trophy'
          }
          {
            path: @router.get 'groupProfile', {groupId}
            title: @model.l.get 'drawer.menuItemProfile'
            $icon: new Icon()
            $ripple: new Ripple()
            iconName: 'profile'
          }
          {
            path: @router.get 'groupTools', {groupId}
            title: @model.l.get 'addonsPage.title'
            $icon: new Icon()
            $ripple: new Ripple()
            iconName: 'ellipsis'
          }
          if @model.groupUser.hasPermission {
            meGroupUser, me, permissions: ['manageRole']
          }
            {
              path: @router.get 'groupSettings', {groupId}
              title: @model.l.get 'groupSettingsPage.title'
              $icon: new Icon()
              iconName: 'settings'
              $chevronIcon: new Icon()
              children: [
                {
                  path: @router.get 'groupManageChannels', {
                    id: group.key or group.id
                  }
                  title: @model.l.get 'groupManageChannelsPage.title'
                }
                {
                  path: @router.get 'groupManageRoles', {
                    id: group.key or group.id
                  }
                  title: @model.l.get 'groupManageRolesPage.title'
                }
                if @model.groupUser.hasPermission {
                  meGroupUser, me, permissions: ['readAuditLog']
                }
                  {
                    path: @router.get 'groupAuditLog', {groupId}
                    title: @model.l.get 'groupAuditLogPage.title'
                  }
                {
                  path: @router.get 'groupBannedUsers', {
                    id: group.key or group.id
                  }
                  title: @model.l.get 'groupBannedUsersPage.title'
                }
              ]
            }
          if needsApp
            {
              isDivider: true
            }
          if needsApp
            {
              onclick: =>
                @model.portal.call 'app.install'
              title: @model.l.get 'drawer.menuItemNeedsApp'
              $icon: new Icon()
              $ripple: new Ripple()
              iconName: 'get'
            }
          ])

  afterMount: (@$$el) =>
    {drawerWidth, breakpoint} = @state.getValue()

    breakpoint = @model.window.getBreakpoint()
    onBreakpoint = (breakpoint) =>
      if not @iScrollContainer and breakpoint isnt 'desktop'
        checkIsReady = =>
          $$container = @$$el
          if $$container and $$container.clientWidth
            @initIScroll $$container
          else
            setTimeout checkIsReady, 1000

        checkIsReady()
      else if @iScrollContainer and breakpoint is 'desktop'
        @open()
        @iScrollContainer?.destroy()
        delete @iScrollContainer
        @disposable?.unsubscribe()
    @breakpointDisposable = breakpoint.subscribe onBreakpoint
    onBreakpoint breakpoint

  beforeUnmount: =>
    @iScrollContainer?.destroy()
    delete @iScrollContainer
    @disposable?.unsubscribe()
    @breakpointDisposable?.unsubscribe()

  close: =>
    @iScrollContainer.goToPage 1, 0, 500

  open: =>
    @iScrollContainer.goToPage 0, 0, 500

  initIScroll: ($$container) =>
    {drawerWidth} = @state.getValue()
    @iScrollContainer = new IScroll $$container, {
      scrollX: true
      scrollY: false
      eventPassthrough: true
      bounce: false
      snap: '.tab'
      deceleration: 0.002
    }

    # the scroll listener in IScroll (iscroll-probe.js) is really slow
    updateOpacity = =>
      opacity = 1 + @iScrollContainer.x / drawerWidth
      @$$overlay.style.opacity = opacity * MAX_OVERLAY_OPACITY

    @disposable = @model.drawer.isOpen().subscribe (isOpen) =>
      if isOpen then @open() else @close()
      @$$overlay = @$$el.querySelector '.overlay-tab'
      updateOpacity()

    isScrolling = false
    @iScrollContainer.on 'scrollStart', =>
      isScrolling = true
      @$$overlay = @$$el.querySelector '.overlay-tab'
      update = ->
        updateOpacity()
        if isScrolling
          window.requestAnimationFrame update
      update()
      updateOpacity()

    @iScrollContainer.on 'scrollEnd', =>
      {isOpen} = @state.getValue()
      isScrolling = false

      newIsOpen = @iScrollContainer.currentPage.pageX is 0

      # landing on new tab
      if newIsOpen and not isOpen
        @model.drawer.open()
      else if not newIsOpen and isOpen
        @model.drawer.close()

  isExpandedByPath: (path) =>
    {expandedItems} = @state.getValue()
    expandedItems.indexOf(path) isnt -1

  toggleExpandItemByPath: (path) =>
    {expandedItems} = @state.getValue()
    isExpanded = @isExpandedByPath path

    if isExpanded
      expandedItems = _clone expandedItems
      expandedItems.splice expandedItems.indexOf(path), 1
      @state.set expandedItems: expandedItems
    else
      @state.set expandedItems: expandedItems.concat [path]

  render: ({currentPath}) =>
    {isOpen, me, menuItems, myGroups, drawerWidth, breakpoint, group,
      language, windowSize} = @state.getValue()

    group ?= {}
    groupId = group.key or group.id

    translateX = if isOpen then 0 else "-#{drawerWidth}px"
    # adblock plus blocks has-ad
    hasA = not Environment.isMobile() and windowSize?.height > 880

    renderChild = ({path, title, $chevronIcon, children}, depth = 0) =>
      isSelected = currentPath?.indexOf(path) is 0
      isExpanded = isSelected or @isExpandedByPath path

      hasChildren = not _isEmpty children
      z 'li.menu-item',
        z 'a.menu-item-link.is-child', {
          className: z.classKebab {isSelected}
          href: path
          onclick: (e) =>
            e.preventDefault()
            @model.drawer.close()
            @router.goPath path
        },
          z '.icon'
          title
          if hasChildren
            z '.chevron',
              z $chevronIcon,
                icon: if isExpanded \
                      then 'chevron-up'
                      else 'chevron-down'
                color: colors.$tertiary500Text70
                isAlignedRight: true
                onclick: (e) =>
                  e?.stopPropagation()
                  e?.preventDefault()
                  @toggleExpandItemByPath path
        if hasChildren and isExpanded
          z "ul.children-#{depth}",
            _map children, (child) ->
              renderChild child, depth + 1

    z '.z-drawer', {
      className: z.classKebab {isOpen, hasA}
      key: 'drawer'
      style:
        display: if windowSize.width then 'block' else 'none'
        height: "#{windowSize.height}px"
        width: if breakpoint is 'mobile' \
               then '100%'
               else "#{drawerWidth}px"
    },
      z '.drawer-wrapper', {
        style:
          width: "#{drawerWidth + windowSize.width}px"
          # "#{@transformProperty}": "translate(#{translateX}, 0)"
          # webkitTransform: "translate(#{translateX}, 0)"
      },
        z '.drawer-tab.tab',
          z '.drawer', {
            style:
              width: "#{drawerWidth}px"
          },
            z '.header',
              z '.icon',
                z @$groupBadge
              z '.name',
                @model.group.getDisplayName group
            z '.content',
              z 'ul.menu',
                [
                  if me and not me?.isMember
                    [
                      z 'li.sign-in-buttons',
                        z '.button', {
                          onclick: =>
                            @model.signInDialog.open 'signIn'
                        }, @model.l.get 'general.signIn'
                        z '.button', {
                          onclick: =>
                            @model.signInDialog.open()
                        }, @model.l.get 'general.signUp'
                      z 'li.divider'
                    ]
                  _map menuItems, (menuItem) =>
                    {path, onclick, title, $icon, $chevronIcon, $ripple, isNew,
                      iconName, isDivider, children} = menuItem

                    hasChildren = not _isEmpty children
                    groupId = group.key or group.id

                    if isDivider
                      return z 'li.divider'

                    if menuItem.isDefault
                      isSelected = currentPath in [
                        @router.get 'siteHome'
                        @router.get 'groupHome', {groupId}
                        '/'
                      ]
                    else
                      isSelected = currentPath?.indexOf(path) is 0

                    isExpanded = isSelected or @isExpandedByPath path

                    z 'li.menu-item', {
                      className: z.classKebab {isSelected}
                    },
                      z 'a.menu-item-link', {
                        href: path
                        onclick: (e) =>
                          e.preventDefault()
                          if onclick
                            onclick()
                          else if path
                            @router.goPath path
                          @model.drawer.close()
                      },
                        z '.icon',
                          z $icon,
                            isTouchTarget: false
                            icon: iconName
                            color: colors.$primary500
                        title
                        if isNew
                          z '.new', @model.l.get 'general.new'
                        if hasChildren
                          z '.chevron',
                            z $chevronIcon,
                              icon: if isExpanded \
                                    then 'chevron-up'
                                    else 'chevron-down'
                              color: colors.$tertiary500Text70
                              isAlignedRight: true
                              touchHeight: '28px'
                              onclick: (e) =>
                                e?.stopPropagation()
                                e?.preventDefault()
                                @toggleExpandItemByPath path
                      if hasChildren and isExpanded
                        z 'ul.children',
                          _map children, (child) ->
                            renderChild child, 1
                        if breakpoint is 'desktop'
                          z $ripple

                  unless _isEmpty myGroups
                    z 'li.divider'

                  z 'li.subhead', @model.l.get 'drawer.otherGroups'

                  _map myGroups, (myGroup) =>
                    {$badge, $ripple, group, $chevronIcon, children} = myGroup
                    groupPath = @router.get 'group', {groupId}
                    groupEnPath = @router.get 'group', {
                      id: group.key or group.id
                      }, {language: 'en'}

                    isSelected = currentPath?.indexOf(groupPath) is 0 or
                      currentPath?.indexOf(groupEnPath) is 0

                    z 'li.menu-item', {
                      className: z.classKebab {isSelected}
                    },
                      z 'a.menu-item-link', {
                        href: groupPath
                        onclick: (e) =>
                          e.preventDefault()
                          @model.drawer.close()
                          @router.go 'groupHome', {
                            groupId: group.key or group.id
                          }
                      },
                        z '.icon',
                          z $badge
                        @model.group.getDisplayName group
                        if breakpoint is 'desktop'
                          $ripple
                ]

            if hasA
              z '.ad',
                z @$adsenseAd, {
                  slot: 'desktop336x280'
                }

        z '.overlay-tab.tab', {
          onclick: =>
            @model.drawer.close()
        },
          z '.grip'
