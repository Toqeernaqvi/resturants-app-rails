webhook_populate_recent_sms = (driver_id) ->
  $.ajax
    url: '/admin/schedulers/chat_history'+'?driver='+driver_id
    type: 'get'
    success: (data) ->
      chatTILE = '#chat_'+driver_id
      $(chatTILE+' .messages').prepend data['message']
      return

setCookieWebhooks = (cname, cvalue, exdays) ->
  d = new Date
  d.setTime d.getTime() + exdays * 24 * 60 * 60 * 1000
  expires = 'expires=' + d.toGMTString()
  document.cookie = cname + '=' + cvalue + ';' + expires + ';'
  return

setCookieStateWebhooks = (rowID = '', chatState = '', active = '', driverName = '') ->
  setCookieWebhooks 'chatList', '', 900
  chat = []
  getLength = $('.chatTile').length
  console.log getLength
  i = 0
  while i < getLength
    tileBlock = document.getElementsByClassName('chatTile')[i]
    chatWinID = tileBlock.getAttribute('id')
    idIs = tileBlock.getAttribute('data-chatid')
    tileStatus = tileBlock.getAttribute('data-chat-status')
    activeTile = tileBlock.classList.contains('active')
    driverNameIs = $('#' + chatWinID + ' .headText').text()
    if activeTile == true
      activeTile = 'active'
    else if activeTile == false
      activeTile = ''
    chat.push [
      idIs
      tileStatus
      activeTile
      driverNameIs
    ]
    achat = JSON.stringify(chat)
    setCookieWebhooks 'chatList', achat, 900
    i++
  return
      
rePositionTilesWebhooks = ->
  console.log "repositioning webhooks"
  screenSize = $(window).width()
  checkRightSideBar = $('.rightSideBar').length
  getRightSideBarWidth = if checkRightSideBar == 1 then $('.rightSideBar').width() + 35 else 35
  screenAfterMinusRightBar = screenSize - getRightSideBarWidth
  allowTiles = parseInt(screenAfterMinusRightBar / 325)
  getAlreadyOpendTiles = $('.chatTile').length
  $('.chatTile').each (index) ->
    i = index + 1
    if i == 1 and i <= allowTiles
      $(this).css 'right': getRightSideBarWidth + 'px'
    else if i <= allowTiles
      rightMargin = index * 325
      $(this).css 'right': getRightSideBarWidth + rightMargin + 'px'
    else
      $('.chatTile').first().remove()
      rePositionTilesWebhooks()
    return
  return

$(window).resize ->
  rePositionTilesWebhooks()
  return

populate_tile = (driver) ->
  rowID = driver['driver_id']
  rowNAME = driver['driver_name']
  rowSMS = driver['message']
  
  checkTileExsit = $('#chat_' + rowID).length
  $('.chatTile').removeClass 'active'
  if checkTileExsit == 0
    App.global_driver = App.cable.subscriptions.create {
      channel: "DriversChannel"
      driver_id: rowID
    },
    connected: ->
      # Called when the subscription is ready for use on the server

    disconnected: ->
      # Called when the subscription has been terminated by the server

    received: (message) ->
      console.log("message", message)
      chatTILE = '#chat_'+message['driver_id']
      $(chatTILE+' .messages').append message['message']
      $(chatTILE+' .body').animate { scrollTop: $(chatTILE + ' .body.messages > div:last').offset().top }, 2000

    send_message: (message, rowID) ->
      @perform 'send_message', message: message, driver_id: rowID
  
    chatTile = 
      L_1: '<div class="chatTile active" id="chat_' + rowID + '" data-chatid="' + rowID + '" data-chat-status="max">'
      L_2: '<div class="header">'
      L_3: '<div class="headText">Driver: ' + rowNAME + '</div>'
      L_4: '<div class="closeTile" data-win-id="chat_' + rowID + '"><em class="fa fa-times"></em></div>'
      L_5: '</div>'
      L_6: '<div class="body messages"><div class="welcomeMsg">' + rowSMS + '</div></div>'
      L_7: '<div class="footer">'
      L_8: '<div class="senderPart">'
      L_9: '<input type="text" class="bsInput" id="message_' + rowID + '" data-messageid="' + rowID + '"  message" placeholder="Enter your message..." autofocus />'
      L_10: '<button type="button" class="bsInput send">Send</button>'
      L_11: '</div>'
      L_12: '</div>'
      L_13: '</div>'
    key = Object.keys(chatTile)
    rawChatCollected = ''
    i = 0
    while i < key.length
      rawHTML = key[i]
      rawChatCollected += chatTile[rawHTML]
      i++
    $('body').append rawChatCollected
    setCookieStateWebhooks()
    setTimeout (->
      rePositionTilesWebhooks()
      return
    ), 100
    webhook_populate_recent_sms(rowID)
  else if checkTileExsit == 1
    $('#chat_' + rowID).css 'top': 'calc(100vh - 400px)'
    $('#chat_' + rowID + ' .body, #chat_' + rowID + ' .footer').show()
    $('#chat_' + rowID).attr 'data-chat-status', 'max'
    setTimeout (->
      rePositionTilesWebhooks()
      return
    ), 100
  return

App.global_driver = App.cable.subscriptions.create {
    channel: "WebhooksChannel"
  },
  connected: ->
    # Called when the subscription is ready for use on the server

  disconnected: ->
    # Called when the subscription has been terminated by the server

  received: (driver) ->
    populate_tile(driver)
    