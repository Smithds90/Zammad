window.onload = function() {

// model
QUnit.test( "model ui basic tests", assert => {

  // load ref object
  App.Collection.loadAssets({
    TicketState: {
      1: {
        name: 'new', id: 1, updated_at: "2014-11-07T23:43:08.000Z",
      },
      2: {
        name: 'open', id: 2, updated_at: "2014-11-07T23:43:08.000Z",
      },
      3: {
        name: 'closed <>&', id: 3, updated_at: "2014-11-07T23:43:08.000Z",
      },
    },
  })

  // create ticket
  var attribute1 = {
    name: 'date', display: 'date 1',  tag: 'date', null: true
  };
  App.Ticket.configure_attributes.push( attribute1 )
  var attribute2 = {
    name: 'textarea', display: 'textarea 1',  tag: 'textarea', null: true
  };
  App.Ticket.configure_attributes.push( attribute2 )
  var attribute3 = {
    name: 'link1', display: 'link 1', linktemplate: 'http://zammad.com',  tag: 'input', null: true, translate: true
  };
  App.Ticket.configure_attributes.push( attribute3 )
  var attribute4 = {
    name: 'link2', display: 'link 1', linktemplate: 'http://zammad.com',  tag: 'input', null: true
  };
  App.Ticket.configure_attributes.push( attribute4 )

  var ticket = new App.Ticket()
  ticket.load({
    id:         1000,
    title:      'some title <>&',
    state_id:   2,
    updated_at: '2014-11-07T23:43:08.000Z',
    date:       '2015-02-07',
    textarea:   "some new\nline",
    link1:      'closed',
    link2:      'closed',
  })

  App.i18n.set('en-us')
  assert.equal( App.viewPrint( ticket, 'id' ), 1000)
  assert.equal( App.viewPrint( ticket, 'title' ), 'some title &lt;&gt;&amp;')
  assert.equal( App.viewPrint( ticket, 'state' ), 'open')
  assert.equal( App.viewPrint( ticket, 'state_id' ), 'open')
  assert.equal( App.viewPrint( ticket, 'not_existing' ), '-')
  assert.equal( App.viewPrint( ticket, 'updated_at' ), '<time class="humanTimeFromNow " datetime="2014-11-07T23:43:08.000Z" title="11/07/2014 23:43">11/07/2014</time>')
  assert.equal( App.viewPrint( ticket, 'date' ), '02/07/2015')
  assert.equal( App.viewPrint( ticket, 'textarea' ), '<div>some new</div><div>line</div>')
  assert.equal( App.viewPrint( ticket, 'link1' ), '<a href="http://zammad.com" target="blank">closed</a>')
  assert.equal( App.viewPrint( ticket, 'link2' ), '<a href="http://zammad.com" target="blank">closed</a>')

  let stub = sinon.stub(App.Config, 'get')
  stub.withArgs('timezone_default').returns('Example/Timezone')
  let attr = App.Ticket.configure_attributes.find(e => { return e.name == 'updated_at' })
  attr.include_timezone = true

  assert.equal( App.viewPrint( ticket, 'updated_at' ), '<time class="humanTimeFromNow " datetime="2014-11-07T23:43:08.000Z" title="11/07/2014 23:43 Example/Timezone" timezone="Example/Timezone">11/07/2014</time>')

  attr.include_timezone = false
  stub.restore()

  App.i18n.set('de-de')
  assert.equal( App.viewPrint( ticket, 'id' ), 1000)
  assert.equal( App.viewPrint( ticket, 'title' ), 'some title &lt;&gt;&amp;')
  assert.equal( App.viewPrint( ticket, 'state' ), 'offen')
  assert.equal( App.viewPrint( ticket, 'state_id' ), 'offen')
  assert.equal( App.viewPrint( ticket, 'not_existing' ), '-')
  assert.equal( App.viewPrint( ticket, 'updated_at' ), '<time class="humanTimeFromNow " datetime="2014-11-07T23:43:08.000Z" title="07.11.2014 23:43">07.11.2014</time>')
  assert.equal( App.viewPrint( ticket, 'date' ), '07.02.2015')
  assert.equal( App.viewPrint( ticket, 'textarea' ), '<div>some new</div><div>line</div>')
  assert.equal( App.viewPrint( ticket, 'link1' ), '<a href="http://zammad.com" target="blank">geschlossen</a>')
  assert.equal( App.viewPrint( ticket, 'link2' ), '<a href="http://zammad.com" target="blank">closed</a>')


  App.i18n.set('en-us')
  ticket.state_id = 3
  assert.equal( App.viewPrint( ticket, 'state' ), 'closed &lt;&gt;&amp;')
  assert.equal( App.viewPrint( ticket, 'state_id' ), 'closed &lt;&gt;&amp;')

  App.i18n.set('de')
  assert.equal( App.viewPrint( ticket, 'state' ), 'closed &lt;&gt;&amp;')
  assert.equal( App.viewPrint( ticket, 'state_id' ), 'closed &lt;&gt;&amp;')

  // normal string
  data = {
    a: 1,
    b: 'abc',
    c: {
      displayName: function() { return "my displayName <>&" }
    },
  }
  assert.equal( App.viewPrint( data, 'a' ), 1)
  assert.equal( App.viewPrint( data, 'b' ), 'abc')
  assert.equal( App.viewPrint( data, 'c' ), 'my displayName &lt;&gt;&amp;')

});


}
