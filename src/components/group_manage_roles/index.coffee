z = require 'zorium'
RxBehaviorSubject = require('rxjs/BehaviorSubject').BehaviorSubject

Icon = require '../icon'
Fab = require '../fab'
GroupRolePermissions = require '../group_role_permissions'
Dialog = require '../dialog'
PrimaryInput = require '../primary_input'
colors = require '../../colors'

if window?
  require './index.styl'

module.exports = class GroupManageRoles
  constructor: ({@model, @router, group, gameKey}) ->

    @$fab = new Fab()
    @$addIcon = new Icon()

    permissionTypes = [
      'manageInfo'
      'readAuditLog'
      'manageChannel'
      'manageRole'
      'permaBanUser'
      'tempBanUser'
      'unbanUser'
      'sendMessage'
      'sendLink'
      'sendImage'
    ]

    @$groupRolePermissions = new GroupRolePermissions {
      @model, @router, group, gameKey, permissionTypes, onSave: @save
    }
    @$newRoleDialog = new Dialog()
    @newRoleNameValue = new RxBehaviorSubject ''
    @$newRoleInput = new PrimaryInput {value: @newRoleNameValue}

    @state = z.state {
      group
      gameKey: gameKey
      isNewRoleDialogVisible: false
      me: @model.user.getMe()
    }

  save: (roleId, permissions) =>
    {group, conversation} = @state.getValue()

    @model.groupRole.updatePermissions(
      {roleId, isGlobal: true, groupId: group.id, permissions}
    )

  addRole: =>
    {group} = @state.getValue()
    name = @newRoleNameValue.getValue()
    @model.groupRole.createByGroupId group.id, {name}

  render: =>
    {me, group, roles, gameKey, isNewRoleDialogVisible} = @state.getValue()

    z '.z-group-manage-roles',
      @$groupRolePermissions

      z '.fab',
        z @$fab,
          colors:
            c500: colors.$primary500
          $icon: z @$addIcon, {
            icon: 'add'
            isTouchTarget: false
            color: colors.$white
          }
          onclick: =>
            @state.set isNewRoleDialogVisible: true

      if isNewRoleDialogVisible
        z @$newRoleDialog,
          isVanilla: true
          $title: @model.l.get 'groupManageRoles.addRole'
          $content:
            z '.z-group-manage-roles_new-role-dialog',
              z @$newRoleInput,
                hintText: @model.l.get 'general.name'
          onLeave: =>
            @state.set isNewRoleDialogVisible: false
          cancelButton:
            text: @model.l.get 'general.cancel'
            onclick: =>
              @state.set isNewRoleDialogVisible: false
          submitButton:
            text: @model.l.get 'general.done'
            onclick: =>
              @addRole()
              .then =>
                @state.set isNewRoleDialogVisible: false