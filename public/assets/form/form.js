(function ($) {

/*
*
*  provides feedback form for zammad
*

<button id="feedback-form">Feedback</button>

<script id="zammad_form_script" src="http://localhost:3000/assets/form/form.js"></script>
<script>
$(function() {
  $('#feedback-form').ZammadForm({
    messageTitle: 'Feedback Form', // optional
    messageSubmit: 'Submit', // optional
    messageThankYou: 'Thank you for your inquiry! We\'ll contact you soon as possible.', // optional
    messageNoConfig: 'Unable to load form config from server. Maybe featrue is disabled.', // optional
    showTitle: true,
    lang: 'de', // optional, <html lang="xx"> will be used per default
    modal: true,
    attributes: [
      {
        display: 'Name',
        name: 'name',
        tag: 'input',
        type: 'text',
        placeholder: 'Your Name',
      },
      {
        display: 'Email',
        name: 'email',
        tag: 'input',
        type: 'email',
        placeholder: 'Your Email',
      },
      {
        display: 'Message',
        name: 'body',
        tag: 'textarea',
        placeholder: 'Your Message...',
        rows: 7,
      },
    ]
  });
});
</script>

*/

  var pluginName = 'ZammadForm',
  defaults = {
    lang: undefined,
    debug: false,
    noCSS: false,
    prefixCSS: 'zammad-form-',
    showTitle: false,
    messageTitle: 'Zammad Form',
    messageSubmit: 'Submit',
    messageThankYou: 'Thank you for your inquiry! We\'ll contact you soon as possible.',
    messageNoConfig: 'Unable to load form config from server. Maybe featrue is disabled.',
    attributes: [
      {
        display: 'Name',
        name: 'name',
        tag: 'input',
        type: 'text',
        placeholder: 'Your Name',
      },
      {
        display: 'Email',
        name: 'email',
        tag: 'input',
        type: 'email',
        placeholder: 'Your Email',
      },
      {
        display: 'Message',
        name: 'body',
        tag: 'textarea',
        placeholder: 'Your Message...',
        rows: 7,
      },
    ],
    translations: {
      de: {
        'Name': 'Name',
        'Your Name': 'Ihr Name',
        'Email': 'E-Mail',
        'Your Email': 'Ihre E-Mail',
        'Message': 'Nachricht',
        'Your Message...': 'Ihre Nachricht...',
      },
      es: {
        'Name': 'Nombre',
        'Your Name': 'tu Nombre',
        'Email': 'correo electrónico',
        'Your Email': 'Tu correo electrónico',
        'Message': 'Mensaje',
        'Your Message...': 'tu Mensaje...',
      },
      fr: {
        'Name': 'Prénom',
        'Your Name': 'Votre nom',
        'Email': 'Email',
        'Your Email': 'Votre Email',
        'Message': 'Message',
        'Your Message...': 'Votre message...',
      },
    }
  };

  function Plugin(element, options) {
    this.element  = element
    this.$element = $(element)

    this._defaults = defaults;
    this._name     = pluginName;

    this._endpoint_config = '/api/v1/form_config'
    this._endpoint_submit = '/api/v1/form_submit'
    this._script_location = '/assets/form/form.js'
    this._css_location    = '/assets/form/form.css'

    this._src = document.getElementById('zammad_form_script').src
    this.css_location = this._src.replace(this._script_location, this._css_location)
    this.endpoint_config = this._src.replace(this._script_location, this._endpoint_config)
    this.endpoint_submit = this._src.replace(this._script_location, this._endpoint_submit)

    this.options = $.extend({}, defaults, options)
    if (!this.options.lang) {
      this.options.lang = $('html').attr('lang')
    }
    if (this.options.lang) {
      this.options.lang = this.options.lang.replace(/-.+?$/, '')
      this.log('debug', "lang: " + this.options.lang)
    }

    this._config = {}

    this.init()
  }

  Plugin.prototype.init = function () {
    var _this = this,
      params = {}

    _this.log('debug', 'init', this._src)

    if (!_this.options.noCSS) {
      _this.loadCss(_this.css_location)
    }

    _this.log('debug', 'endpoint_config: ' + _this.endpoint_config)
    _this.log('debug', 'endpoint_submit: ' + _this.endpoint_submit)

    // load config
    if (this.options.test) {
      params.test = true
    }
    $.ajax({
      url: _this.endpoint_config,
      data: params
    }).done(function(data) {
      _this.log('debug', 'config:', data)
      _this._config = data
    }).fail(function(jqXHR, textStatus, errorThrown) {
      if (jqXHR.status == 401) {
        _this.log('error', 'Faild to load form config, feature is disabled!')
      }
      else {
        _this.log('error', 'Faild to load form config!')
      }
      _this.noConfig()
    });

    // show form
    if (!this.options.modal) {
      _this.render()
    }

    // bind form on call
    else {
      this.$element.off('click.zammad-form').on('click.zammad-form', function (e) {
        e.preventDefault()
        _this.render()
        return true
      })
    }
  }

  // load css
  Plugin.prototype.loadCss = function(filename) {
    if (document.createStyleSheet) {
      document.createStyleSheet(filename)
    }
    else {
      $('<link rel="stylesheet" type="text/css" href="' + filename + '" />').appendTo('head')
    }
  }

  // send
  Plugin.prototype.submit = function() {
    var _this = this

    // check min modal open time
    if (_this.modalOpenTime) {
      var currentTime = new Date().getTime()
      var diff = currentTime - _this.modalOpenTime.getTime()
      _this.log('debug', 'currentTime', currentTime)
      _this.log('debug', 'modalOpenTime', _this.modalOpenTime.getTime())
      _this.log('debug', 'diffTime', diff)
      if (diff < 1000*8) {
        alert('Sorry, you look like an robot!')
        return
      }
    }

    // disable form
    _this.$form.find('button').prop('disabled', true)

    $.ajax({
      method: 'post',
      url: _this.endpoint_submit,
      data: _this.getParams(),
    }).done(function(data) {

      // removed errors
      _this.$form.find('.has-error').removeClass('has-error')

      // set errors
      if (data.errors) {
        $.each(data.errors, function( key, value ) {
          _this.$form.find('[name=' + key + ']').closest('.form-group').addClass('has-error')
        })
        _this.$form.find('button').prop('disabled', false)
        return
      }

      // ticket has been created
      _this.thanks()

    }).fail(function() {
      _this.$form.find('button').prop('disabled', false)
      alert('Faild to submit form!')
    });
  }

  // get params
  Plugin.prototype.getParams = function() {
    var _this = this,
      params = {}

    $.each( _this.$form.serializeArray(), function(index, item) {
      params[item.name] = item.value
    })

    if (!params.title) {
      params.title = this.options.messageTitle
    }

    if (this.options.test) {
      params.test = true
    }
    _this.log('debug', 'params', params)
    return params
  }

  Plugin.prototype.closeModal = function() {
    if (this.$modal) {
      this.$modal.remove()
    }
  }

  // render form
  Plugin.prototype.render = function(e) {
    var _this = this
    _this.closeModal()
    _this.modalOpenTime = new Date()
    _this.log('debug', 'modalOpenTime:', _this.modalOpenTime)

    var element = "<div class=\"" + _this.options.prefixCSS + "modal\">\
      <div class=\"" + _this.options.prefixCSS + "modal-backdrop js-close\"></div>\
      <div class=\"" + _this.options.prefixCSS + "modal-body\">\
        <form class=\"zammad-form\"></form>\
      </div>\
    </div>"

    if (!this.options.modal) {
      element = '<div><form class="zammad-form"></form></div>'
    }

    var $element = $(element)
    var $form = $element.find('form')
    if (this.options.showTitle && this.options.messageTitle != '') {
      $form.append('<h2>' + this.options.messageTitle + '</h2>')
    }
    $.each(this.options.attributes, function(index, value) {
      var item = $('<div class="form-group"><label>' + _this.T(value.display) + '</label></div>')
      if (value.tag == 'input') {
        item.append('<input class="form-control" name="' + value.name + '" type="' + value.type + '" placeholder="' + _this.T(value.placeholder) + '">')
      }
      else if (value.tag == 'textarea') {
        item.append('<textarea class="form-control" name="' + value.name + '" placeholder="' + _this.T(value.placeholder) + '" rows="' + value.rows + '"></textarea>')
      }
      $form.append(item)
    })
    $form.append('<button type="submit" class="btn">' + this.options.messageSubmit + '</button')

    this.$modal = $element
    this.$form  = $form

    // bind on close
    $element.find('.js-close').off('click.zammad-form').on('click.zammad-form', function (e) {
      e.preventDefault()
      _this.closeModal()
      return true
    })

    // bind form submit
    $element.off('submit.zammad-form').on('submit.zammad-form', function (e) {
      e.preventDefault()
      _this.submit()
      return true
    })

    // show form
    if (!this.options.modal) {
      _this.$element.html($element)
    }

    // append modal to body
    else {
      $('body').append($element)
    }

  }

  // thanks
  Plugin.prototype.thanks = function(e) {
    var message = $('<div class="js-thankyou">' + this.options.messageThankYou + '</div>')
    this.$form.html(message)
  }

  // unable to load config
  Plugin.prototype.noConfig = function(e) {
    var message = $('<div class="js-noConfig">' + this.options.messageNoConfig + '</div>')
    if (this.$form) {
      this.$form.html(message)
    }
    this.$element.html(message)
  }

  // log method
  Plugin.prototype.log = function() {
    var args = Array.prototype.slice.call(arguments)
    var level = args.shift()
    if (!this.options.debug && level == 'debug') {
      return
    }
    args.unshift(this._name + '||' + level)
    console.log.apply(console, args)

    var logString = ''
    $.each( args, function(index, item) {
      logString = logString + ' '
      if (typeof item == 'object') {
        logString = logString + JSON.stringify(item)
      }
      else if (item && item.toString) {
        logString = logString + item.toString()
      }
      else {
        logString = logString + item
      }
    })
    $('.js-logDisplay').prepend('<div>' + logString + '</div>')
  }

  // translation method
  Plugin.prototype.T = function() {
    var string = arguments[0]
    var items = 2 <= arguments.length ? slice.call(arguments, 1) : []
    if (this.options.lang && this.options.lang !== 'en') {
      if (!this.options.translations[this.options.lang]) {
        this.log('debug', "Translation '" + this.options.lang + "' needed!")
      }
      else {
        translations = this.options.translations[this.options.lang]
        if (!translations[string]) {
          this.log('debug', "Translation needed for '" + this.options.lang + "' " + string + "'")
        }
        string = translations[string] || string
      }
    }
    if (items) {
      for (i = 0, len = items.length; i < len; i++) {
        item = items[i]
        string = string.replace(/%s/, item)
      }
    }
    return string
  }

  $.fn[pluginName] = function (options) {
    return this.each(function () {
      var instance = $.data(this, 'plugin_' + pluginName)
      if (instance) {
        instance.$element.empty()
        $.data(this, 'plugin_' + pluginName, undefined)
      }
      $.data(
        this, 'plugin_' + pluginName,
        new Plugin(this, options)
      );
    });
  }

}(jQuery));