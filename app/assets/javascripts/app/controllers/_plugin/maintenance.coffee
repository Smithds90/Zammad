class Maintenance extends App.Controller
  serverRestarted: false
  constructor: ->
    super
    @controllerBind(
      'maintenance'
      (data) =>
        if data.type is 'message'
          @showMessage(data)
        if data.type is 'mode'
          @maintanaceMode(data)
        if data.type is 'app_version'
          @maintanaceAppVersion(data)
        if data.type is 'config_changed'
          @maintanaceConfigChanged(data)
        if data.type is 'restart_auto'
          @maintanaceRestartAuto(data)
        if data.type is 'restart_manual'
          @maintanaceRestartManual(data)
    )

  showMessage: (message = {}) =>
    if message.reload
      @disconnectClient()
      button = __('Continue session')
    else
      button = __('Close')

    if message.reload
      App.SessionStorage.clear()

    new App.SessionMessage(
      head:          message.head
      contentInline: message.message
      small:         true
      keyboard:      true
      backdrop:      true
      buttonClose:   true
      buttonSubmit:  button
      forceReload:   message.reload
    )

  maintanaceMode: (data = {}) =>
    return if data.on isnt true
    return if !@authenticateCheck()
    @navigate '#logout'

  #App.Event.trigger('maintenance', {type:'restart_auto'})
  maintanaceRestartAuto: (data) =>
    return if @messageRestartAuto

    App.SessionStorage.clear()

    @messageRestartAuto = new App.SessionMessage(
      head:         __('Zammad is restarting…')
      message:      __('Some system settings have changed, Zammad is restarting. Please wait until Zammad is back again.')
      keyboard:     false
      backdrop:     false
      buttonClose:  false
      buttonSubmit: false
      small:        true
      forceReload:  true
    )
    @disconnectClient()
    @checkAvailability()

  #App.Event.trigger('maintenance', {type:'restart_manual'})
  maintanaceRestartManual: (data) =>
    return if @messageRestartManual

    App.SessionStorage.clear()

    @messageRestartManual = new App.SessionMessage(
      head:         __('Zammad requires a restart!')
      message:      __('Some system settings have changed, please restart all Zammad processes! If you want to do this automatically, set environment variable APP_RESTART_CMD="/path/to/your_app_script.sh restart".')
      keyboard:     false
      backdrop:     false
      buttonClose:  false
      buttonSubmit: false
      small:        true
      forceReload:  true
    )
    @disconnectClient()
    @checkAvailability()

  maintanaceConfigChanged: (data) =>
    return if @messageConfigChanged

    App.SessionStorage.clear()

    @messageConfigChanged = new App.SessionMessage(
      head:          __('Config has changed')
      message:       __('The configuration of Zammad has changed, please reload your browser.')
      keyboard:      false
      backdrop:      true
      buttonClose:   false
      buttonSubmit:  __('Continue session')
      forceReload:   true
    )

  maintanaceAppVersion: (data) =>
    return if @messageAppVersion
    return if @appVersion is data.app_version
    if !@appVersion
      @appVersion = data.app_version
      return
    @appVersion = data.app_version
    localAppVersion = @appVersion.split(':')
    return if localAppVersion[1] isnt 'true'

    App.SessionStorage.clear()

    message = =>
      @messageAppVersion = new App.SessionMessage(
        head:         __('New Version')
        message:      __('A new version of Zammad is available, please reload your browser.')
        keyboard:     false
        backdrop:     true
        buttonClose:  false
        buttonSubmit: __('Continue session')
        forceReload:  true
      )
    @delay(message, 2000)

  checkAvailability: (timeout) =>
    delay = =>
      @ajax(
        id:      'check_availability'
        type:    'get'
        url:     "#{@apiPath}/available"
        success: (data) =>
          if @serverRestarted
            @windowReload()
            return

          @checkAvailability()
        error: =>
          @serverRestarted = true
          @checkAvailability(2000)
      )

    timeout ?= 1000
    @delay(delay, timeout)

App.Config.set('maintenance', Maintenance, 'Plugins')
