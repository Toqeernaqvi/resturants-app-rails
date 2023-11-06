$(document).on 'click', '.send', ->
  drivertileID = $(this).prev().attr('data-messageid')  
  message = $('#message_'+drivertileID).val()
  if message != ''
    App.global_driver.send_message message, drivertileID
    $('#message_'+drivertileID).css("border-color", "")
    $('#message_'+drivertileID).val ''
  else
    $(this).prev().css("border-color", "red")