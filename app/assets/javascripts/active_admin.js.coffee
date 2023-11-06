#= require arctic_admin/base
#= require activeadmin_addons/all
#= require underscore
#= require gmaps/google
#= require activeadmin/trumbowyg/trumbowyg
#= require activeadmin/trumbowyg_input
#= require activeadmin/trumbowyg/plugins/upload/trumbowyg.upload
#= require chartkick
#= require Chart.bundle
#= require cable
#= require recurring
#= require search-select
#= require ckeditor/init

$ ->
  currentPageIs = window.location.href
  currentPageIs = currentPageIs.split('/')
  newPageIs = ''
  i = 0
  while i < currentPageIs.length
    if i > 2 and i < 5
      newPageIs += '__' + currentPageIs[i]
    i++
  if newPageIs.includes('?')
    newPageIs = newPageIs.replace('?', '--')
  if newPageIs.includes('=')
    newPageIs = newPageIs.replace('=', '---')
  if newPageIs.includes('.')
    newPageIs = newPageIs.replace('.', '0')
  $('body').addClass newPageIs
  return

id = 1
$(document).ready ->
  if $('.address .driverShifts').length
    $('.driverShifts .has_many_container').each (i, day) ->
      if $(day).find('fieldset').length > 1
        $(day).find('fieldset').find('li.boolean:first').hide()
        $(day).find('fieldset:first').find('li.boolean').hide()
      else if $(day).find('fieldset').length == 1
        $(day).find('fieldset').find('.has_many_delete').hide()
        $(day).find('fieldset').find('.has_many_remove').hide()
        container = $(day).find('fieldset')
        start_time = $(container).find('.date_time_picker:first').find('input.date-time-picker-input')
        end_time = $(container).find('.date_time_picker:last').find('input.date-time-picker-input')
        if start_time.parents('.field_with_errors').length < 0 && end_time.parents('.field_with_errors').length < 0 && start_time.val() == '00:00' && end_time.val() == '00:00'
          $(container).find('.boolean').find('.has_many_close').attr('checked', true)
          $(container).find('label:first').show()
        else if start_time.val() != '00:00' || end_time.val() != '00:00'
          $(container).find('.boolean').find('.has_many_close').attr('checked', false)
          $(container).find('label:first').hide()
      return
    
    $(document).on 'change paste keyup', '.date-time-picker-input', (event) ->
      start_time = $(this).parents('.has_many_fields').find('.date_time_picker:first').find('input.date-time-picker-input').val()
      end_time = $(this).parents('.has_many_fields').find('.date_time_picker:last').find('input.date-time-picker-input').val()
      if $(this).parents('.has_many_container').find('fieldset').length == 1
        if start_time == '00:00' && end_time == '00:00'
          $(this).parents('.has_many_fields').find('.boolean').find('.has_many_close').attr('checked', true)
          $(this).parents('.has_many_fields').find('label:first').show()
        else
          $(this).parents('.has_many_fields').find('.boolean').find('.has_many_close').attr('checked', false)
          $(this).parents('.has_many_fields').find('label:first').hide()

    $(document).on 'click', '.driverShifts .has_many_add', ->
      $(this).parents('.has_many_container').find('fieldset.has_many_fields').each (i, elem) ->
        if i > 0
          $(elem).find('.boolean').find('.has_many_close').attr('checked', false)
          $(elem).find('label:first').hide()
          $(elem).find('.has_many_delete label').show()
      return

    $(document).on 'has_many_remove:after', '.driverShifts .has_many_container', (e, fieldset, container)->
      list_item_count = container.find('.has_many_fields').length
      if list_item_count == 1
        container.find('.has_many_fields').find('.has_many_delete label').hide()
        start_time = container.find('.date_time_picker:first').find('input.date-time-picker-input').val()
        end_time = container.find('.date_time_picker:last').find('input.date-time-picker-input').val()
        if start_time == '00:00' && end_time == '00:00'
          container.find('.boolean').find('.has_many_close').attr('checked', true)
          container.find('label:first').show()
        else
          container.find('.boolean').find('.has_many_close').attr('checked', false)
          container.find('label:first').hide()
    $(document).on 'has_many_add:before', '.driverShifts .has_many_container', (e, container)->
      list_item_count = $(container).find('.has_many_fields').length
      if list_item_count == 1
        start_time = $(container).find('.date_time_picker:first').find('input.date-time-picker-input').val()
        end_time = $(container).find('.date_time_picker:last').find('input.date-time-picker-input').val()
        if start_time == '00:00' && end_time == '00:00'
          e.preventDefault()

  if $("#runningmenu_bev_rest_deleted").length
    $(document).on 'click', '#runningmenu_address_ids_'+ $('#runningmenu_bev_rest_id').val(), ->
      console.log($('#runningmenu_bev_rest_id').val())
      $("#runningmenu_bev_rest_deleted").val(true)
  if $(".hideMenuItem_").length
    $(".hideMenuItem_").parent().hide()
  $('fieldset.inputs > ol > li.fooditems > a').on 'click', ->
    setTimeout (->
      if $(".hideMenuItem_").length > 0
       $(".hideMenuItem_").parent().hide()
      return
    ), 50
  if $("input#runningmenu_delivery_at").length
    populate_drivers_combo()
  toggle_new_runningmenu_fields()
  #update_map()
  $('.clear_filters_btn').attr 'href', '?commit=clear_filters'
  $( "#driver_phone_number_input > .driver_phone_field" ).prop( "disabled", true )
  populate_runningmenufields()
  $('#order_report_form select, #order_report_form input').on 'change', (e) ->
    $('#order_report_form').submit()
    return

  $('.delete_btn').on 'click', ->
    return confirm('Are you sure you want to delete this?')

  $('.active_btn').on 'click', ->
    return confirm('Are you sure you want to active this?')

  $('#runningmenu_submit_action input[type="submit"]').on 'click', (event)->
    delivery_at = $("input#runningmenu_delivery_at").val()
    address_id = $("select#runningmenu_address_id").val()
    address_ids = []
    $("input[name='runningmenu[address_ids][]']").each ->
      if $(this).val() != ""
        address_ids.push $(this).val()
      return
    if delivery_at && address_ids.length > 0
      event.preventDefault()
      $.ajax
        async: false,
        url: "/admin/schedulers/shifts_available?delivery_at="+delivery_at+"&address_id="+address_id+"&address_ids="+address_ids,
        success: (result) ->
          if result.show_dialog
            $('#dialog-confirm').html($.parseHTML(result.addresses))
            confirmDialog($("#runningmenu_submit_action").parents('form'))
          else
            $($("#runningmenu_submit_action").parents('form')).unbind('submit').submit()
          return

  $('.restaurants_tags').on 'select2:select', (e) ->
    id = e.params.data.id
    option = $(e.target).children('[value=' + id + ']')
    option.detach()
    $(e.target).append(option).change()
    return
  initAutocomplete()
  $('.autocomplete').each (i, obj) ->
    obj.id = obj.id + '_' + i
    street = document.getElementById('street_number')
    route = document.getElementById('route')
    locality = document.getElementById('locality')
    administrative_area_level_1 = document.getElementById('administrative_area_level_1')
    postal_code = document.getElementById('postal_code')
    longitude = document.getElementById('longitude')
    latitude = document.getElementById('latitude')
    street.id = street.id + '_' + i
    route.id = route.id + '_' + i
    locality.id = locality.id + '_' + i
    administrative_area_level_1.id = administrative_area_level_1.id + '_' + i
    postal_code.id = postal_code.id + '_' + i
    longitude.id = longitude.id + '_' + i
    latitude.id = latitude.id + '_' + i
    id = i + 1
    return
  $(document).on 'click', 'a.button.has_many_add', (event) ->
    $('#autocomplete').on 'click', (e) ->
      auto = document.getElementById('autocomplete')
      street = document.getElementById('street_number')
      route = document.getElementById('route')
      locality = document.getElementById('locality')
      administrative_area_level_1 = document.getElementById('administrative_area_level_1')
      postal_code = document.getElementById('postal_code')
      longitude = document.getElementById('longitude')
      latitude = document.getElementById('latitude')
      auto.id = auto.id + '_' + id
      street.id = street.id + '_' + id
      route.id = route.id + '_' + id
      locality.id = locality.id + '_' + id
      administrative_area_level_1.id = administrative_area_level_1.id + '_' + id
      postal_code.id = postal_code.id + '_' + id
      longitude.id = longitude.id + '_' + id
      latitude.id = latitude.id + '_' + id
      id = id + 1
      geolocate(this)
      return
  if $('#company_reduced_markup_input').length
    if !$('#company_reduced_markup_check').prop('checked')
      $('#company_reduced_markup_input').hide()

    $('label > #company_reduced_markup_check').click ->
      $('#company_reduced_markup_input').toggle @checked
      return

  if $('#company_copay_amount_input').length
    if !$('#company_user_copay').prop('checked')
      $('#company_copay_amount_input').hide()

    $('label > #company_user_copay').click ->
      $('#company_copay_amount_input').toggle @checked
      return

  if $('#runningmenu_per_user_copay_input').length
    if !$('#runningmenu_per_user_copay').prop('checked')
      $('#runningmenu_per_user_copay_amount_input').hide()

    $('label > #runningmenu_per_user_copay').click ->
      $('#runningmenu_per_user_copay_amount_input').toggle @checked
      return

  if $('#company_billing_attributes_invoice_credit_card_input').length
    if $('#company_billing_attributes_invoice_credit_card_credit_card').prop('checked')
      $('#billing-detail > fieldset.inputs > ol > li.has_many_container.addresses').hide()
      # $('#billing-detail > fieldset.inputs > ol > li.has_many_container.approvers').hide()
      $('#company_billing_attributes_name_input').hide()
      if $('#company_billing_attributes_change_card_input').length && !$('#company_billing_attributes_change_card').prop('checked')
        $('#company_billing_attributes_card_number_input').hide()
        $('#company_billing_attributes_expiry_month_input').hide()
        $('#company_billing_attributes_expiry_year_input').hide()
        $('#company_billing_attributes_cvc_input').hide()
        $('#company_billing_attributes_change_card').show()
      if $('#company_billing_attributes_change_card_input').length && $('#company_billing_attributes_change_card').prop('checked')
        $('#company_billing_attributes_card_number_input').show()
        $('#company_billing_attributes_expiry_month_input').show()
        $('#company_billing_attributes_expiry_year_input').show()
        $('#company_billing_attributes_cvc_input').show()
        $('#company_billing_attributes_change_card').show()

    $('#company_billing_attributes_invoice_credit_card_credit_card').click ->
      $('#company_billing_attributes_card_number_input').show()
      $('#company_billing_attributes_expiry_month_input').show()
      $('#company_billing_attributes_expiry_year_input').show()
      $('#company_billing_attributes_cvc_input').show()
      $('#billing-detail > fieldset.inputs > ol > li.has_many_container.addresses').hide()
      # $('#billing-detail > fieldset.inputs > ol > li.has_many_container.approvers').hide()
      $('#company_billing_attributes_name_input').hide()
      if $('#company_billing_attributes_change_card_input').length
        if $('#company_billing_attributes_change_card').prop('checked')
          $('#company_billing_attributes_card_number_input').show()
          $('#company_billing_attributes_expiry_month_input').show()
          $('#company_billing_attributes_expiry_year_input').show()
          $('#company_billing_attributes_cvc_input').show()
          $('#company_billing_attributes_change_card_input').show()
        else
          $('#company_billing_attributes_card_number_input').hide()
          $('#company_billing_attributes_expiry_month_input').hide()
          $('#company_billing_attributes_expiry_year_input').hide()
          $('#company_billing_attributes_cvc_input').hide()
          $('#company_billing_attributes_change_card_input').show()
        return
    $('#company_billing_attributes_invoice_credit_card_invoice').click ->
      $('#company_billing_attributes_card_number_input').hide()
      $('#company_billing_attributes_expiry_month_input').hide()
      $('#company_billing_attributes_expiry_year_input').hide()
      $('#company_billing_attributes_cvc_input').hide()
      $('#company_billing_attributes_change_card_input').hide()
      $('#billing-detail > fieldset.inputs > ol > li.has_many_container.addresses').show()
      # $('#billing-detail > fieldset.inputs > ol > li.has_many_container.approvers').show()
      $('#company_billing_attributes_name_input').show()
      return

    $('#company_billing_attributes_change_card').click ->
      $('#company_billing_attributes_card_number_input').toggle @checked
      $('#company_billing_attributes_expiry_month_input').toggle @checked
      $('#company_billing_attributes_expiry_year_input').toggle @checked
      $('#company_billing_attributes_cvc_input').toggle @checked
      return

    if $('#company_billing_attributes_invoice_credit_card_invoice').prop('checked')
      $('#company_billing_attributes_card_number_input').hide()
      $('#company_billing_attributes_expiry_month_input').hide()
      $('#company_billing_attributes_expiry_year_input').hide()
      $('#company_billing_attributes_cvc_input').hide()
      $('#company_billing_attributes_change_card_input').hide()
      return

    if !$('#company_billing_attributes_invoice_credit_card_credit_card').prop('checked') && !$('#company_billing_attributes_invoice_credit_card_invoice').prop('checked')
      $('#company_billing_attributes_card_number_input').hide()
      $('#company_billing_attributes_expiry_month_input').hide()
      $('#company_billing_attributes_expiry_year_input').hide()
      $('#company_billing_attributes_cvc_input').hide()
      return

  # if !$('#runningmenu_request_recurring').prop('checked')
    # $('.wrapper_recurring').hide()

  # $('#runningmenu_request_recurring').click ->
    # $('.wrapper_recurring').toggle @checked
    # return

  if $('.company_field_type').length
    $('.company_field_type').each (index) ->
      options_subscribe_events(this)

    $('.company_field_type').on 'change', (e) ->
      options_subscribe_events(this)
  return


$(document).on('has_many_add:after', ->
  $(".tags_input", document).each ->
    # console.log('bism', $("#"+$(this, document).attr('id')).hasClass('select2-hidden-accessible'))
    if !$("#"+$(this, document).attr('id')).hasClass('select2-hidden-accessible')
      # console.log('$(this, document)', $(this, document))
      elem = $(this, document)
      setTimeout (->
        $(elem, document).select2
          tags: true
          multiple: "multiple"
        return
      ), 100
      
    return
  
  $('.company_field_type').on 'change', (e) ->
    options_subscribe_events(this)
)

$(document).on 'click', '.header #tabs > li > a[href="#"]', ->
  checkClassAvailable = $(this).next('ul.menu.dBlock').length
  if checkClassAvailable == 0
    $(this).next('ul.menu').addClass 'dBlock'
  else if checkClassAvailable == 1
    $(this).next('ul.menu').removeClass 'dBlock'
  return

options_subscribe_events = (obj) ->
  if $('option:selected', obj).text() == 'Text'
    $(obj).parent().siblings().eq(2).hide()
  else
    $(obj).parent().siblings().eq(2).show()
  return

confirmDialog = (form_id) ->
  $('#dialog-confirm').dialog
    resizable: false
    height: 'auto'
    width: 600
    modal: true
    buttons:
      'Continue anyway': ->
        $(this).dialog 'close'
        $(form_id).unbind('submit').submit()
      Cancel: ->
        $(this).dialog 'close'
        return

populate_drivers_combo = ->
  selected_recurring_driver = 0
  delivery_at = $("input#runningmenu_delivery_at").val()
  pickup_at = $("input#runningmenu_pickup_at").val()
  delivery_type = $("#runningmenu_delivery_type").val()
  address_id = $('#runningmenu_address_id').val()
  address_ids = []
  $("input[name='runningmenu[address_ids][]']").each ->
    if $(this).val() != ""
      address_ids.push $(this).val()
    return
  if delivery_at && pickup_at && delivery_type && address_id
    $.ajax
      url: "/admin/schedulers/available_list?delivery_at="+delivery_at+"&pickup_at="+pickup_at+"&delivery_type="+delivery_type+"&address_id="+address_id+"&address_ids="+address_ids,
      success: (result) ->
        driver_id = $("#runningmenu_selected_driver_id").val()
        driver_name = $("#runningmenu_selected_driver_id").attr("name")
        $("#runningmenu_driver_id").html('<option value=""></option>');
        $.each result.drivers, (i, j) ->
          if j.id == parseInt( driver_id )
            row = '<option value="' + j.id + '" selected="selected">' + j.first_name + ' ' + j.last_name + '</option>'
            selected_recurring_driver = 1
          else
            row = '<option value="' + j.id + '">' + j.first_name + ' ' + j.last_name + '</option>'
          $(row).appendTo '#runningmenu_driver_id'
          return
        if selected_recurring_driver == 0 && parseInt( driver_id ) > 0
          row = '<option value="' + driver_id + '" selected="selected">' + driver_name + '</option>'
          $(row).appendTo '#runningmenu_driver_id'
        return

toggle_new_runningmenu_fields = ->
  delivery_type = $("select#runningmenu_delivery_type").val()
  arr = []
  items = document.getElementsByClassName('selected-item')
  i = 0
  while i < items.length
    arr.push items[i].id.substr(items[i].id.length - 3)
    i++
  if $("#runningmenu_menu_type").val() == "buffet"
    $("li#runningmenu_per_meal_budget_input").hide()
    $("li#runningmenu_per_user_copay_input").hide()
    $("li#runningmenu_per_user_copay_amount_input").hide()
    if $('form#new_runningmenu').length > 0
      $.ajax
        url: "/admin/schedulers/runningmenu_beverages_restaurant_has_buffet_menu"
        success: (result) ->
          $("#runningmenu_address_ids_selected_values").html ''
          $("#runningmenu_address_ids_selected_values").html('<input id="runningmenu_address_ids_empty" name="runningmenu[address_ids][]" value="" type="hidden">')
          if result.str_html != false && delivery_type != 'delivery'
            $.ajax
              async: false
              url: "/admin/schedulers/runningmenu_beverages_restaurant?addresses="+arr
              success: (result) ->
                $("#runningmenu_address_ids_selected_values").append(result.str_html)
  else
    $("li#runningmenu_per_meal_budget_input").show()
    $("li#runningmenu_per_user_copay_input").show()
    if $("#runningmenu_per_user_copay").prop("checked")
      $("li#runningmenu_per_user_copay_amount_input").show()
    else
      $("li#runningmenu_per_user_copay_amount_input").hide()
    if $('form#new_runningmenu').length > 0
      if delivery_type != 'delivery'
        $("#runningmenu_address_ids_selected_values").html ''
        $("#runningmenu_address_ids_selected_values").html('<input id="runningmenu_address_ids_empty" name="runningmenu[address_ids][]" value="" type="hidden">')
        $.ajax
          async: false
          url: "/admin/schedulers/runningmenu_beverages_restaurant?addresses="+arr
          success: (result) ->
            $("#runningmenu_address_ids_selected_values").append(result.str_html)

setHours = (dt, h) ->
  s = /(\d+):(\d+)(.+)/.exec(h)
  dt.setHours if s[3] == 'pm' then 12 + parseInt(s[1], 10) else parseInt(s[1], 10)
  dt.setMinutes parseInt(s[2], 10)
  return

$(document).ready ->
  saved_recurring_first_address()
  #recurring_first_address()
  $('#recurring_scheduler_address_ids').on 'change', ->
    recurring_first_address()
  $('#recurring_scheduler_address_ids').on 'select2:select', ->
    recurring_first_address()

recurring_first_address = ->
  selected_addresses = $(document).find('.selected-item')
  if selected_addresses.length > 0
    restaurant_address = selected_addresses[0].firstElementChild.value
    $('#recurring_scheduler_first_restaurant').val(restaurant_address)
  else
    $('#recurring_scheduler_first_restaurant').val('')

saved_recurring_first_address = ->
  first_restaurant = $('#recurring_scheduler_first_restaurant').val()
  if first_restaurant != ''
    first_restaurant_div = $('#recurring_scheduler_address_ids_'+first_restaurant)
    $('input#recurring_scheduler_address_ids_empty').after(first_restaurant_div)
  return

$(document).ready ->
  $('#runningmenu_address_ids').on 'change', ->
    if $('#runningmenu_id').length && $('#runningmenu_id').val() == ''
      set_new_runningmenu_dates()
  $('#runningmenu_address_ids').on 'select2:select', ->
    if $('#runningmenu_id').length && $('#runningmenu_id').val() == ''
      set_new_runningmenu_dates()

set_new_runningmenu_dates = ->
  #if $('form#new_runningmenu').length > 0 && $('#runningmenu_delivery_at').val() != ''
  if $('#runningmenu_delivery_at').val() != ''
    newDate = $('#runningmenu_delivery_at').val()
    check_sunday_monday = new Date(newDate).getDay()
    $('input#runningmenu_activation_at').datetimepicker
      value: new Date
    pickup_ms = new Date(newDate).getTime() - (4.5e+6)
    pickup_at = new Date(pickup_ms)
    $('input#runningmenu_pickup_at').datetimepicker
      value: pickup_at
    #if $('#runningmenu_menu_type').val() != '' && $('#runningmenu_delivery_type').val() == 'delivery'
    if $('#runningmenu_menu_type').val() != ''
      selected_addresses = $(document).find('.selected-item')
      restaurant_address = ""
      day_before_delivery = ""
      if selected_addresses.length > 0
        restaurant_address = selected_addresses[0].firstElementChild.value
        $.ajax
          async: false
          url: "/admin/schedulers/restaurant_cutoffs?menu_type="+$('#runningmenu_menu_type').val()+"&restaurant_address_id="+restaurant_address
          success: (result) ->
            if $('#runningmenu_menu_type').val() == "buffet"
              ms = new Date(newDate).getTime() - result.buffet_cutoff
            else
              ms = new Date(newDate).getTime() - result.individual_meals_cutoff
            day_before_delivery = new Date(ms)
    else
      ###
      if $('#runningmenu_menu_type').val() == "buffet"
        ms = new Date(newDate).getTime() - 172800000
      else
        ms = new Date(newDate).getTime() - 86400000
      if check_sunday_monday == 0
        ms = new Date(newDate).getTime() - 172800000
      else if check_sunday_monday == 1
        ms = new Date(newDate).getTime() - 259200000
      day_before_delivery = new Date(ms)
      setHours(day_before_delivery, "2:00pm");      
      ###

    $('input#runningmenu_cutoff_at').datetimepicker
      value: day_before_delivery,
    $('input#runningmenu_admin_cutoff_at').datetimepicker
      value: day_before_delivery

update_map = ->
  company_address_id = $("select#runningmenu_address_id").val();
  if company_address_id
    $.ajax
      url: "/admin/addresses/"+company_address_id+"/map"
      success: (result) ->
        generate_map(result)
  return

update_budget = ->
  company_address_id = $("select#runningmenu_address_id").val();
  if company_address_id
    $.ajax
      url: "/admin/addresses/"+company_address_id+"/company_budget"
      success: (result) ->
        $("#runningmenu_per_meal_budget").val(result.budget)
        if result.user_copay == 1 && $("#runningmenu_menu_type").val() == "individual"
          $("#runningmenu_per_user_copay").prop("checked", true);
          $('#runningmenu_per_user_copay_amount_input').show()
        else
          $("#runningmenu_per_user_copay").prop("checked", false)
          $('#runningmenu_per_user_copay_amount_input').hide()
        $("#runningmenu_per_user_copay_amount").val(result.copay_amount)
  return

populate_runningmenufields = ->
  company_address_id = $("select#runningmenu_address_id").val();
  runningmenu_id = $("#runningmenu_id").val();
  if company_address_id
    $.ajax
      url: "/admin/addresses/"+company_address_id+"/company_fields?runningmenu_id=" +runningmenu_id
      success: (result) ->
        $("#wrapper_fields").html(result.data)
        return
populate_runningmenutags = ->
  company_address_id = $("select#runningmenu_address_id").val();
  runningmenu_id = $("#runningmenu_id").val();
  if company_address_id
    $.ajax
      url: "/admin/addresses/"+company_address_id+"/runningmenu_tags"
      success: (result) ->
        $("select#runningmenu_tag_list").empty().select2({data: result})
        $("input[name='runningmenu[tag_list][]']").val($("select#runningmenu_tag_list").val().join(','))
        return
$(document).on 'change', '#runningmenu_menu_type', ->
  toggle_new_runningmenu_fields()
  if $('#runningmenu_id').length && $('#runningmenu_id').val() == ''
    set_new_runningmenu_dates()
  return
$(document).on 'change', '#runningmenu_address_id', ->
  populate_drivers_combo()
  return
$(document).on 'change', '#runningmenu_delivery_type', ->
  if $('#runningmenu_id').length && $('#runningmenu_id').val() == ''
    set_new_runningmenu_dates()
  populate_drivers_combo()
  return
$(document).on 'change', '#runningmenu_address_id', ->
  #update_map()
  update_budget()
  if $('#runningmenu_id').length && $('#runningmenu_id').val() == ''
    set_new_runningmenu_dates()
  populate_runningmenufields()
  populate_runningmenutags()
  company_address_id = $(this).val();
  meal_type = $("select#runningmenu_menu_type").val();
  runningmenu_id = $("form").attr("action").split("/")[3]
  $.ajax
    url: "/admin/schedulers/company_admins?id=" +runningmenu_id+ "&company_address_id=" +company_address_id
    success: (result) ->
      $("#runningmenu_user_id").html(result.data)
  $.ajax
    url: "/admin/schedulers/company_delivery_notes?id=" +runningmenu_id+ "&company_address_id=" +company_address_id
    success: (result) ->
      $(".delivery_notes_li").remove()
      $("#runningmenu_delivery_instructions_input").after(result.data)
      $("#runningmenu_delivery_instructions").val(result.delivery_instructions)
      return
  return

$(document).ready ->
  if $('#runningmenu_address_id').length
    company_address_id = $('#runningmenu_address_id').val()
    runningmenu_id = $("form").attr("action").split("/")[3]
    if company_address_id
      #$.ajax
        #url: "/admin/schedulers/company_admins?id=" +runningmenu_id+ "&company_address_id=" +company_address_id
        #success: (result) ->
          #$("#runningmenu_user_id").html(result.data)
      $.ajax
        url: "/admin/schedulers/company_delivery_notes?id=" +runningmenu_id+ "&company_address_id=" +company_address_id
        success: (result) ->
          $(".delivery_notes_li").remove()
          $("#runningmenu_delivery_instructions_input").after(result.data)
          return
    return

$(document).on 'change', '#runningmenu_delivery_at', ->
  if $('#runningmenu_id').length && $('#runningmenu_id').val() == ''
    set_new_runningmenu_dates()
  populate_drivers_combo()
  return

$(document).on 'click', '.sortable', ->
  sort_text = $(this).attr('sort_by')
  sort_order = $("input#sort").attr('order')
  if sort_text == $("input#sort").val()
    if sort_order == 'asc'
      $("input#sort").attr('order', 'desc')
    else
      $("input#sort").attr('order', 'asc')
  else
    $("input#sort").attr('order', 'asc')
  $("input#sort").val($(this).attr('sort_by'))

generate_map = (data) ->
  $("#outer_map").show()
  handler = Gmaps.build('Google')
  handler.buildMap {
    provider: {}
    internal: id: 'map'
  }, ->
    markers = handler.addMarkers(data)
    handler.bounds.extendWith markers
    handler.fitMapToBounds()
    handler.getMap().setZoom(11)

$(document).ready ->
  divData2Move = $('#runningmenu_address_ids_input > div > #runningmenu_address_ids_selected_values').html()
  $('#runningmenu_address_ids_input span.select2-selection.select2-selection--multiple').prepend '<div id="runningmenu_address_ids_selected_values" class="selected-values">' + divData2Move + '</div>'
  $('#runningmenu_address_ids_input > div > #runningmenu_address_ids_selected_values').remove()

  divData2MoveCompany = $('#company_location_ids_input > div > #company_location_ids_selected_values').html()
  $('#company_location_ids_input span.select2-selection.select2-selection--multiple').prepend '<div id="company_location_ids_selected_values" class="selected-values">' + divData2MoveCompany + '</div>'
  $('#company_location_ids_input > div > #company_location_ids_selected_values').remove()
  if $("#runningmenu_dynamic_sections_address_ids").length
    arr = $("#runningmenu_dynamic_sections_address_ids").val().split(" ")
    $.each arr, (index, val) ->
      # $("#runningmenu_address_ids_"+val).hide()
      $('#runningmenu_address_ids_selected_values .selected-item').each ->
        if $(this).is("#runningmenu_address_ids_"+val)
          $(this).hide()
        return
      return
    return

$(document).ready ->
  $(document).on 'click', '.rightSideBar .closeBtn', (e) ->
    $(this).parent().remove()
    $('#main_content').removeClass 'mainContent'
    return
  return

$(document).ready ->
  $(document).on 'change', '.acknowledge_address', ->
    fieldValue = @value
    rowID = $(this).attr('data-row-ID')
    this_val = $(this).val()
    this_prev = $(this).prev().children()
    $.post 'schedulers/' + rowID + '/acknowledge_schedule', {
      id: rowID
      status: fieldValue
    }, ((data) ->
      if data.message == 'success'
        if this_val == 'ack_schedule'
          this_prev.css 'color', '#ff991f'
        else if this_val == 'accept_orders'
          this_prev.css 'color', '#36b37e'
        else if this_val == 'accept_modification'
          this_prev.css 'color', '#36b37e'
        else
          this_prev.css 'color', '#ff5630'
      return
    ), 'json'
    return
  return

$(document).ready ->
  $('#header').append '<span class="actToggle">&lt;</span>'
  $(document).on 'click', '.actToggle', (e) ->
    checkStatusOfLeftBar = $('#tabs').css('display')
    if checkStatusOfLeftBar == 'block'
      $('#tabs').hide 'slow'
      $('.actToggle').addClass 'goLeft'
      $('#active_admin_content').css 'margin-left': '-250px'
      $('#title_bar').css 'margin-left': '-225px'
    else if checkStatusOfLeftBar == 'none'
      $('#tabs').show 'slow'
      $('.actToggle').removeClass 'goLeft'
      $('#active_admin_content').css 'margin-left': '0px'
      $('#title_bar').css 'margin-left': '25px'
    console.log checkStatusOfLeftBar
    return
  return

$(document).ready ->
  $(document).on 'change', '.runningmenu_driver', ->
    fieldValue = @value
    rowID = $(this).attr('data-row-ID')
    $.post 'schedulers/'+rowID+'/driver', {
      id: rowID
      driver_id: fieldValue
    }, ((data) ->
    ), 'json'
    return
  return

$(document).ready ->
  $('.table_actions a').each (index) ->
    $text = undefined
    $text = $(this).text()
    if $text == 'Edit' or $text == 'edit'
      $(this).html '<em class="fa fa-pencil"></em>'
      $(this).addClass 'edit'
      $(this).removeAttr 'title'
      # $(this).attr 'data-tooltip', 'true'
    else if $text == 'Delete'
      $(this).html '<em class="fa fa-trash"></em>'
      $(this).addClass 'dBtn'
      $(this).removeAttr 'title'
      # $(this).attr 'data-tooltip', 'true'
    else if $text == 'Details' or $text == 'View'
      $(this).html '<em class="fa fa-eye"></em>'
      $(this).addClass 'detailVU'
      $(this).removeAttr 'title'
      # $(this).attr 'data-tooltip', 'true'
    else if $text == 'Forward'
      $(this).html '<em class="fa fa-share-square-o" aria-hidden="true"></em>'
      $(this).addClass 'forwardVU'
      $(this).removeAttr 'title'
      # $(this).attr 'data-tooltip', 'true'
    return
  $('a[data-tooltip="true"]').hover (->
    $(this).attr 'data-title', $(this).attr('title')
    $(this).removeAttr 'title'
    if $(this).attr('data-title') != undefined
      $(this).append '<span class="activeToolTip">' + $(this).attr('data-title') + '</span>'
    return
  ), ->
    $(this).children('span.activeToolTip').remove()
    return
  return

$(document).ready ->
  $(document).on 'click', '.trumbowyg-insertImage-button', ->
    $('.trumbowyg-modal-button.trumbowyg-modal-submit').addClass 'insertImageConfirmBtn'
    return
  $(document).on 'click', '.insertImageConfirmBtn', ->
    imgLink = $('.trumbowyg-modal-box form input[name="url"]').val()
    if imgLink
      $('.trumbowyg-editor').append '<img src="' + imgLink + '">'
    return
  return

$(document).ready ->
  getHrefUpload = $('.bulk_schedule').attr('href')
  $('.bulk_schedule').parent().append '<label for="uploadCSV_" class="bulk_schedule">Bulk Schedule</label><a class="sampleFile" title="Download Sample CSV File"><em class="fa fa-download" aria-hidden="true"></em></a><form id="uploadCsvFile_" action="' + getHrefUpload + '" method="post" enctype="multipart/form-data"><input type="file" name="bulkScheduleCsv" id="uploadCSV_" accept=".csv" style="display: none;"></form>'
  $('a.bulk_schedule').remove()

  getHref = $('.sampleFile_').attr('href')
  $('.sampleFile').attr 'href', getHref
  $('.sampleFile_').parent().remove()
  $(document).on 'change', '#uploadCSV_', ->
    $('#uploadCsvFile_').trigger 'submit'
    return
  
  getHrefJsonUpload = $('.upload_json').attr('href')
  $('.upload_json').parent().append '<label for="uploadJSON_" class="upload_json">Upload Json</label><form id="uploadJsonFile_" action="' + getHrefJsonUpload + '" method="post" enctype="multipart/form-data"><input type="file" name="UploadJson" id="uploadJSON_" accept=".json" style="display: none;"></form>'
  $('a.upload_json').remove()
  $(document).on 'change', '#uploadJSON_', ->
    $('#uploadJsonFile_').trigger 'submit'
    return

$(document).ready ->
  getHrefUpload = $('.bulk_restaurant').attr('href')
  $('.bulk_restaurant').parent().append '<label for="uploadRestaurantCSV_" class="bulk_restaurant">Google Places Lookup</label><a class="sampleFile" title="Download Sample CSV File"><em class="fa fa-download" aria-hidden="true"></em></a><form id="uploadCsvFile_" action="' + getHrefUpload + '" method="post" enctype="multipart/form-data"><input type="file" name="bulkRestaurantCsv" id="uploadRestaurantCSV_" accept=".csv" style="display: none;"></form>'
  $('a.bulk_restaurant').remove()

  getHref = $('.sampleFile_').attr('href')
  $('.sampleFile').attr 'href', getHref
  $('.sampleFile_').parent().remove()
  $(document).on 'change', '#uploadRestaurantCSV_', ->
    $('#uploadCsvFile_').trigger 'submit'
    return

$ ->
  getLink = $('.hideThisElement').attr('href')
  $('.hideThisElement').parent().next().children('a').attr( 'href': getLink)
  console.log getLink
  return


$(document).ready ->
  $(document).on 'click', '.runningmenuRunningmenuTypeToggle', ->
    getStatusToggle = $(this).attr('data-customToggle')
    if getStatusToggle == 'off'
      $(this).children('span').removeClass 'active'
      $(this).children('span').addClass 'active'
      $(this).attr 'data-customToggle', 'on'
      $(this).next().next('input').val('on')
    else if getStatusToggle == 'on'
      $(this).children('span').removeClass 'active'
      $(this).attr 'data-customToggle', 'off'
      $(this).next().next('input').val('off')
    return
  $(document).on 'click', '.editable_dt_btn', ->
    checkEditStatus = $(this).attr 'data-editable'
    menuID = $(this).attr 'data-menuid'
    populate_driver_select_bulk(menuID)
    if checkEditStatus == 'off'
      $('#' + menuID + ' .deliverAt, #' + menuID + ' .cutoffAt, #' + menuID + '  .adminCutoffAt').hide()
      $('#' + menuID + ' .date-time-picker-input').show()

      $('#' + menuID + ' .runningmenu_runningmenu_type, #' + menuID + ' .runningmenuRunningmenuTypeToggle, #' + menuID + ' .buffetContent, #' + menuID + ' span.select2.select2-container.select2-container--default, #' + menuID + ' .ordersCount, #' + menuID + ' .mettingName, #' + menuID + ' .perMealBudget, #' + menuID + ' .saveData, #' + menuID + ' .close, #' + menuID + ' .companyAddress, #' + menuID + ' .saveDataToTemp').css('display':'block')
      $('#' + menuID + ' .runningmenuRunningmenuType, #' + menuID + ' .runningmenuName, #' + menuID + ' .orderCountText, #' + menuID + ' .perMealBudgetText, #' + menuID + ' .notifyAdminYes, #' + menuID + ' .runningmenuAddresses, #' + menuID + ' .companyAddressSpan, #' + menuID + ' .runningmenuDriver').css('display':'none')

      $(this).hide()

      $(this).parent().parent().parent().next('.hiddenTr').show()
      $(this).attr 'data-editable', 'on'

    else if checkEditStatus == 'on'
      $('#' + menuID + ' .deliverAt, #' + menuID + ' .cutoffAt, #' + menuID + '  .adminCutoffAt').show()
      $('#' + menuID + ' .date-time-picker-input').hide()

      $('#' + menuID + ' .runningmenu_runningmenu_type, #' + menuID + ' .runningmenuRunningmenuTypeToggle, #' + menuID + ' .buffetContent, #' + menuID + ' span.select2.select2-container.select2-container--default, #' + menuID + ' .ordersCount, #' + menuID + ' .mettingName, #' + menuID + ' .perMealBudget, #' + menuID + ' .saveData, #' + menuID + ' .close, #' + menuID + ' .companyAddress, #' + menuID + ' .saveDataToTemp').css('display':'none')
      $('#' + menuID + ' .runningmenuRunningmenuType, #' + menuID + ' .runningmenuName, #' + menuID + ' .orderCountText, #' + menuID + ' .perMealBudgetText, #' + menuID + ' .notifyAdminYes, #' + menuID + ' .runningmenuAddresses, #' + menuID + ' .companyAddressSpan, #' + menuID + ' .runningmenuDriver').css('display':'block')

      $('#' + menuID + ' .mettingName').css('display':'none')

      $(this).show()

      $(this).parent().parent().parent().next('.hiddenTr').hide()
      $(this).attr 'data-editable', 'off'
    return
  $(document).on 'click', '.close', ->
    getMenuID = $(this).attr 'data-menu-id'
    $('#' + getMenuID + ' .editable_dt_btn').show()

    $('#' + getMenuID + ' .deliverAt, #' + getMenuID + ' .cutoffAt, #' + getMenuID + '  .adminCutoffAt').show()
    $('#' + getMenuID + ' .date-time-picker-input').hide()

    $('#' + getMenuID + ' .runningmenu_runningmenu_type, #' + getMenuID + ' .runningmenuRunningmenuTypeToggle, #' + getMenuID + ' .buffetContent, #' + getMenuID + ' span.select2.select2-container.select2-container--default, #' + getMenuID + ' .ordersCount, #' + getMenuID + ' .mettingName, #' + getMenuID + ' .perMealBudget, #' + getMenuID + ' .saveData, #' + getMenuID + ' .close, #' + getMenuID + ' .companyAddress, #' + getMenuID + ' .saveDataToTemp').css('display':'none')
    $('#' + getMenuID + ' .runningmenuRunningmenuType, #' + getMenuID + ' .runningmenuName, #' + getMenuID + ' .orderCountText, #' + getMenuID + ' .perMealBudgetText, #' + getMenuID + ' .notifyAdminYes, #' + getMenuID + ' .runningmenuAddresses, #' + getMenuID + ' .companyAddressSpan, #' + getMenuID + ' .runningmenuDriver').css('display':'block')

    $('#' + getMenuID + ' .mettingName').css('display':'none')

    $('#' + getMenuID + ' .editable_dt_btn').attr 'data-editable', 'off'
    return

  $(document).on 'click', '.saveData', ->
    getSaveMenuID = $(this).attr('data-menu-id')
    runningmenuIDVal = $('#' + getSaveMenuID + ' input[name="runningmenu_id_uniq"]').val()
    deliveryAtVal = $('#' + getSaveMenuID + ' input[name="delivery_at"]').val()
    cutoffAtVal = $('#' + getSaveMenuID + ' input[name="cutoff_at"]').val()
    admincutoffAtVal = $('#' + getSaveMenuID + ' input[name="admin_cutoff_at"]').val()
    runningmenuTypeVal = $('#' + getSaveMenuID + ' select[name="runningmenu_type"]').val()
    runningmenuNameVal = $('#' + getSaveMenuID + ' input[name="runningmenu_name"]').val()
    runningmenuCountVal = $('#' + getSaveMenuID + ' input[name="orders_count"]').val()
    perMealBudgetVal = $('#' + getSaveMenuID + ' input[name="per_meal_budget"]').val()
    address_ids = $('#' + getSaveMenuID + ' select[name="my-select[]"]').val()
    addressIDVal = address_ids.join(", ")
    driverVal = $('#' + getSaveMenuID + ' select[name="runningmenu_driver"]').val()
    buffetVal = $('#' + getSaveMenuID + ' input[name="menu_type"]').val()
    notify_adminVal = $('#' + getSaveMenuID + ' input[name="notify_admin"]').val()
    companyAddressVal = $('#' + getSaveMenuID + ' select[name="runningmenu_address_id"]').val()
    cuisinesVal = $('#' + getSaveMenuID + ' input[name="schedulerCuisines"]').val()

    $.post '/admin/imported_schedules/update_imported_schedules', { delivery_at: deliveryAtVal, address_id: companyAddressVal, cutoff_at: cutoffAtVal, admin_cutoff_at: admincutoffAtVal, runningmenu_type: runningmenuTypeVal, runningmenu_name: runningmenuNameVal, orders_count: runningmenuCountVal, per_meal_budget: perMealBudgetVal, address_ids: addressIDVal, driver_id: driverVal, buffet: buffetVal, notify_admin: notify_adminVal, runningmenu_id: runningmenuIDVal, cuisines: cuisinesVal}, ((res) ->
      if res.status == 'failure'
        $('#' + getSaveMenuID).addClass('scheduleUpdateFailed')
        $('#errors_' + getSaveMenuID + ' td').text(res.validation_errors)
        if getSaveMenuID.includes( 'failed' )
        else
          setTimeout (->
            $('#' + getSaveMenuID).removeClass('scheduleUpdateFailed')
            return
          ), 3000
          return

      else if res.status == 'success'
        $('#' + getSaveMenuID + ' .deliverAt').text( res.delivery_at )
        $('#' + getSaveMenuID + ' .cutoffAt').text( res.cutoff_at )
        $('#' + getSaveMenuID + ' .adminCutoffAt').text( res.admin_cutoff_at )
        $('#' + getSaveMenuID + ' .runningmenuRunningmenuType').text( res.runningmenu_type + ' ' + res.menu_type )
        $('#' + getSaveMenuID + ' .runningmenuName').text( res.runningmenu_name )
        $('#' + getSaveMenuID + ' .orderCountText').text( res.orders_count )
        $('#' + getSaveMenuID + ' .perMealBudgetText').text( res.per_meal_budget )
        $('#' + getSaveMenuID + ' .runningmenuDriver').text( res.driver )
        $('#' + getSaveMenuID + ' .notifyAdminYes').text( res.notify_admin )
        $('#' + getSaveMenuID + ' .runningmenuAddresses').html( res.addresses )
        $('#' + getSaveMenuID + ' .companyAddressSpan').text( res.company_location )
        $('#' + getSaveMenuID + ' select[name="my-select[]"]').val(res.address_ids).trigger 'change.select2'
        $('#' + getSaveMenuID + ' #runningmenu_driver_selection').attr('data-selected-driver-id', driverVal)

        $('#' + getSaveMenuID).addClass('scheduleUpdateSuccess')
        $('#errors_' + getSaveMenuID + ' td').text(res.validation_errors)
        if getSaveMenuID.includes( 'failed' ) && res.runningmenu_id
          $('#' + getSaveMenuID).removeClass('scheduleUpdateFailed')
          $('#' + getSaveMenuID + ' input[name="runningmenu_id_uniq"]').val( res.runningmenu_id )
          $('#errors_' + getSaveMenuID + ' td').text("")
          setTimeout (->
            $('#' + getSaveMenuID).removeClass('scheduleUpdateSuccess')
            return
          ), 3000
          $('.close').trigger 'click'
        else
          setTimeout (->
            $('#' + getSaveMenuID).removeClass('scheduleUpdateSuccess')
            $('#errors_' + getSaveMenuID + ' td').text("")
            return
          ), 3000
          $('.close').trigger 'click'
          return
      return
      ), 'json'
    return

  $(document).on 'click', '.saveDataToTemp', ->
    getSaveMenuID = $(this).attr('data-menu-id')
    runningmenuIDVal = $('#' + getSaveMenuID + ' input[name="runningmenu_id_uniq"]').val()
    deliveryAtVal = $('#' + getSaveMenuID + ' input[name="delivery_at"]').val()
    cutoffAtVal = $('#' + getSaveMenuID + ' input[name="cutoff_at"]').val()
    admincutoffAtVal = $('#' + getSaveMenuID + ' input[name="admin_cutoff_at"]').val()
    runningmenuTypeVal = $('#' + getSaveMenuID + ' select[name="runningmenu_type"]').val()
    runningmenuNameVal = $('#' + getSaveMenuID + ' input[name="runningmenu_name"]').val()
    runningmenuCountVal = $('#' + getSaveMenuID + ' input[name="orders_count"]').val()
    perMealBudgetVal = $('#' + getSaveMenuID + ' input[name="per_meal_budget"]').val()
    address_ids = $('#' + getSaveMenuID + ' select[name="my-select[]"]').val()
    addressIDVal = address_ids.join(", ")
    driverVal = $('#' + getSaveMenuID + ' select[name="runningmenu_driver"]').val()
    buffetVal = $('#' + getSaveMenuID + ' input[name="menu_type"]').val()
    notify_adminVal = $('#' + getSaveMenuID + ' input[name="notify_admin"]').val()
    companyAddressVal = $('#' + getSaveMenuID + ' select[name="runningmenu_address_id"]').val()
    cuisinesVal = $('#' + getSaveMenuID + ' input[name="schedulerCuisines"]').val()
    $.post '/admin/selected_schedules/update_temp_schedules', { delivery_at: deliveryAtVal, address_id: companyAddressVal, cutoff_at: cutoffAtVal, admin_cutoff_at: admincutoffAtVal, runningmenu_type: runningmenuTypeVal, runningmenu_name: runningmenuNameVal, orders_count: runningmenuCountVal, per_meal_budget: perMealBudgetVal, address_ids: addressIDVal, driver_id: driverVal, buffet: buffetVal, notify_admin: notify_adminVal, temp_schedule_id: runningmenuIDVal, cuisines: cuisinesVal}, ((res) ->
      if res.status == 'failure'
        $('#' + getSaveMenuID).addClass('scheduleUpdateFailed')
        $('#errors_' + getSaveMenuID + ' td').text(res.validation_errors)
        setTimeout (->
          $('#' + getSaveMenuID).removeClass('scheduleUpdateFailed')
          $('#errors_' + getSaveMenuID + ' td').remove()
          return
        ), 3000
        return

      else if res.status == 'success'
        $('#' + getSaveMenuID + ' .deliverAt').text( res.delivery_at )
        $('#' + getSaveMenuID + ' .cutoffAt').text( res.cutoff_at )
        $('#' + getSaveMenuID + ' .adminCutoffAt').text( res.admin_cutoff_at )
        $('#' + getSaveMenuID + ' .runningmenuRunningmenuType').text( res.runningmenu_type + ' ' + res.menu_type )
        $('#' + getSaveMenuID + ' .runningmenuName').text( res.runningmenu_name )
        $('#' + getSaveMenuID + ' .orderCountText').text( res.orders_count )
        $('#' + getSaveMenuID + ' .perMealBudgetText').text( res.per_meal_budget )
        $('#' + getSaveMenuID + ' .runningmenuDriver').text( res.driver )
        $('#' + getSaveMenuID + ' .notifyAdminYes').text( res.notify_admin )
        $('#' + getSaveMenuID + ' .runningmenuAddresses').html( res.addresses )
        $('#' + getSaveMenuID + ' .companyAddressSpan').text( res.company_location )
        $('#' + getSaveMenuID + ' select[name="my-select[]"]').val(res.address_ids).trigger 'change.select2'
        $('#' + getSaveMenuID + ' #runningmenu_driver_selection').attr('data-selected-driver-id', driverVal)

        $('#' + getSaveMenuID).addClass('scheduleUpdateSuccess')
        $('#errors_' + getSaveMenuID + ' td').text(res.validation_errors)
        if getSaveMenuID.includes( 'failed' ) && res.runningmenu_id
          $('#' + getSaveMenuID).removeClass('scheduleUpdateFailed')
          $('#' + getSaveMenuID + ' input[name="runningmenu_id_uniq"]').val( res.runningmenu_id )
          setTimeout (->
            $('#' + getSaveMenuID).removeClass('scheduleUpdateSuccess')
            $('#errors_' + getSaveMenuID + ' td').remove()
            return
          ), 3000
          $('.close').trigger 'click'
        else
          setTimeout (->
            $('#' + getSaveMenuID).removeClass('scheduleUpdateSuccess')
            $('#errors_' + getSaveMenuID + ' td').remove()
            return
          ), 3000
          $('.close').trigger 'click'
          return
      return
      ), 'json'
    return
  return

$(document).ready ->
  $(document).on 'click', '#ui-id-3', ->
    pageUrl = location.href
    removeParts = pageUrl.split('/companies/')
    removeParts = removeParts[1].split('/edit')
    pdfID = removeParts[0]
    encodedpdfID = btoa pdfID
    $('#cke_90').removeAttr 'href tabindex hidefocus role aria-labelledby aria-describedby onkeydown onfocus onclick aria-haspopup aria-disabled'
    $('#cke_90').attr 'href', 'javascript://'
    $('#cke_90').attr 'onclick', 'window.open(\'/admin/companies/download_pdf?id='+encodedpdfID+'\', \'_blank\')'
    return

  user_type_select_box_val = $('.user_type_combo').val()
  users_arr = ["company_user", "company_manager", "unsubsidized_user"]
  if $('.user_type_combo').length && users_arr.indexOf(user_type_select_box_val) >= 0
    $('#' + user_type_select_box_val + '_sms_notification_input').hide()
    $('#' + user_type_select_box_val + '_menu_ready_email_input').hide()
    $('#' + user_type_select_box_val + '_phone_number_input').hide()
    $('#' + user_type_select_box_val + '_desk_phone_input').hide()
  
  $(document).on 'change', '.user_type_combo', ->
    checkCurrentUserVal = $(this).val()
    if users_arr.indexOf(checkCurrentUserVal) >= 0
      $('#' + user_type_select_box_val + '_phone_number_input').css 'display': 'none'
      $('#' + user_type_select_box_val + '_desk_phone_input').css 'display': 'none'
      $('#' + user_type_select_box_val + '_sms_notification_input').css 'display': 'none'
      $('#' + user_type_select_box_val + '_menu_ready_email_input').css 'display': 'none'
    else
      $('#' + user_type_select_box_val + '_phone_number_input').css 'display': 'block'
      $('#' + user_type_select_box_val + '_desk_phone_input').css 'display': 'block'
      $('#' + user_type_select_box_val + '_sms_notification_input').css 'display': 'block'
      $('#' + user_type_select_box_val + '_menu_ready_email_input').css 'display': 'block'
    return

  checkValue = $('#company_admin_user_type').val()
  if (checkValue == 'company_user' || checkValue == 'company_manager') && $('#company_admin_user_type').length
    $('#company_admin_office_admin_id_input').css 'display': 'inline-block'
    $('#company_admin_phone_number_input').css 'display': 'none'
    $('#company_admin_desk_phone_input').css 'display': 'none'
    $('#company_admin_sms_notification_input').css 'display': 'none'
    $('#company_admin_menu_ready_email_input').css 'display': 'none'
  else if $('#company_admin_user_type').length
    $('#company_admin_office_admin_id_input').css 'display': 'none'
    $('#company_admin_phone_number_input').css 'display': 'inline-block'
    $('#company_admin_desk_phone_input').css 'display': 'inline-block'
    $('#company_admin_sms_notification_input').css 'display': 'block'
    $('#company_admin_menu_ready_email_input').css 'display': 'block'

  $(document).on 'change', '#company_admin_user_type', ->
    checkCurrentVal = $(this).val()
    if (checkCurrentVal == 'company_user' || checkCurrentVal == 'company_manager')
      $('#company_admin_office_admin_id_input').css 'display': 'inline-block'
      $('#company_admin_phone_number_input').css 'display': 'none'
      $('#company_admin_desk_phone_input').css 'display': 'none'
      $('#company_admin_sms_notification_input').css 'display': 'none'
      $('#company_admin_menu_ready_email_input').css 'display': 'none'
    else
      $('#company_admin_office_admin_id_input').css 'display': 'none'
      $('#company_admin_phone_number_input').css 'display': 'inline-block'
      $('#company_admin_desk_phone_input').css 'display': 'inline-block'
      $('#company_admin_sms_notification_input').css 'display': 'block'
      $('#company_admin_menu_ready_email_input').css 'display': 'block'
    return
  return

$(document).ready ->
  # $("#company_user_tag_ids").select2({
  #   tags: true
  # });
  # $("#company_user_tag_list").select2({
  #   tags: true
  # });
  if $("input#company_user_tag_list").length
    $("input#company_user_tag_list").val($("select#company_user_tag_list").val().join(','));
  if $("input#company_admin_tag_list").length
    $("input#company_admin_tag_list").val($("select#company_admin_tag_list").val().join(','));
  if $("input#company_manager_tag_list").length
    $("input#company_manager_tag_list").val($("select#company_manager_tag_list").val().join(','));
  if $("input#unsubsidized_user_tag_list").length
    $("input#unsubsidized_user_tag_list").val($("select#unsubsidized_user_tag_list").val().join(','));
  if $(".tags_input").length
    $(".tags_input").each ->
      $(this).select2
        tags: true
        multiple: "multiple"
    return
  # if $("input[name='fooditem[tag_list]']").length
  #   $("input[name='fooditem[tag_list]']").each ->
  #     indx = $(this).parents('li').attr('id').split('_')[3]
  #     $(this).attr 'name', 'menu[fooditems_attributes][' + indx + '][tag_list]'
  #     # console.log 'nub', $('#'+$(this).parents('li').attr('id')+ ' '+'select').val().join(',')
  #     $(this).val($('#'+$(this).parents('li').attr('id')+ ' '+'select').val().join(','))
  #     $(this).attr("id", $('#'+$(this).parents('li').attr('id')+ ' '+'select').attr('id'))
  #     $('#'+$(this).parents('li').attr('id')+ ' '+'select').attr('data-model', $('#'+$(this).parents('li').attr('id')+ ' '+'select').attr('id').split("_").slice(0, 4).join('_'))
  #     # $(this).select2({ tags: true})
  #     console.log('my document loaded')
  #   return
  # if $("input[name='runningmenu[tag_list][]']").length
    # $("input[name='runningmenu[tag_list][]']").val($("select#runningmenu_tag_list").val().join(','));
  
  $(document).on 'click', '.selectedCheckBox', ->
    checkValueOfCheckBox = $(this).val()
    getRowID = $(this).attr('data-row-id')
    newStatus = 'off'
    if checkValueOfCheckBox == 'on'
      newStatus = 'off'
      $(this).val 'off'
    else if checkValueOfCheckBox == 'off'
      newStatus = 'on'
      $(this).val 'on'
    $.post '/admin/selected_schedules/change_status', {
      rowID: getRowID
      status: newStatus
    }, ((res) ->
      console.log 'this will appear on completion'
      return
    ), 'json'
    return

# Driver Shifts
$(document).ready ->
  $('.driverShifts a.button.has_many_remove').html '<em class="fa fa-minus"></em>'
  $(document).on 'click', 'a.button.has_many_add', ->
    $('.driverShifts a.button.has_many_remove').html '<em class="fa fa-minus"></em>'
    return
  return

$(document).on 'blur', 'input[name="delivery_at"]', ->
  populate_driver_select_bulk($(this).parent().parent().attr('id'))
  return

$(document).on 'change', 'select[name="runningmenu_address_id"]', ->
  populate_driver_select_bulk($(this).parent().parent().attr('id'))
  return

$(document).on 'change', 'select[name="my-select[]"]', ->
  if $(this).val() != ""
    #newDate = $('input[name="delivery_at"]').val()
    newDate = $(this).parent().parent().find('input[name="delivery_at"]').val()
    buffet = $(this).parent().parent().find('span.runningmenuRunningmenuTypeToggle').children().attr("class")
    restaurant_address = $(this).val()[0]
    day_before_delivery = ""
    $.ajax
      async: false
      url: "/admin/schedulers/restaurant_cutoffs?restaurant_address_id="+restaurant_address
      success: (result) ->
        if buffet == "active"
          ms = new Date(newDate).getTime() - result.buffet_cutoff
        else
          ms = new Date(newDate).getTime() - result.individual_meals_cutoff
        day_before_delivery = new Date(ms)
    $(this).parent().parent().find('input[name="cutoff_at"]').datetimepicker
      value: day_before_delivery,
    $(this).parent().parent().find('input[name="admin_cutoff_at"]').datetimepicker
      value: day_before_delivery
  return

$(document).on 'click', 'td span.runningmenuRunningmenuTypeToggle', ->
  if $(this).parent().parent().find('select[name="my-select[]"]').val() != ""
    newDate = $(this).parent().parent().find('input[name="delivery_at"]').val()
    buffet = $(this).parent().parent().find('span.runningmenuRunningmenuTypeToggle').children().attr("class")
    restaurant_address = $(this).parent().parent().find('select[name="my-select[]"]').val()[0]
    day_before_delivery = ""
    $.ajax
      async: false
      url: "/admin/schedulers/restaurant_cutoffs?restaurant_address_id="+restaurant_address
      success: (result) ->
        if buffet != "active"
          ms = new Date(newDate).getTime() - result.buffet_cutoff
        else
          ms = new Date(newDate).getTime() - result.individual_meals_cutoff
        day_before_delivery = new Date(ms)
    $(this).parent().parent().find('input[name="cutoff_at"]').datetimepicker
      value: day_before_delivery,
    $(this).parent().parent().find('input[name="admin_cutoff_at"]').datetimepicker
      value: day_before_delivery
  return

$(document).on 'change', 'select[name="driver[restaurant_address_id]"]', (e) ->
  restaurant_address_id = $(this).val()
  $('#trigger_restaurant_shifts').attr 'href', (i, h) ->
    h + (if h.indexOf('?') != -1 then '&restaurant_address_id=' + restaurant_address_id else '?restaurant_address_id=' + restaurant_address_id)
  $('#trigger_restaurant_shifts')[0].click()
  $('.driverShifts').html('')
  return

populate_driver_select_bulk = (row_id) ->
  getRowID = row_id
  driverSelectedID = $('#' + getRowID + ' #runningmenu_driver_selection').attr 'data-selected-driver-id'
  driverSelectedID = parseInt( driverSelectedID )
  delivery_at = $('#' + getRowID + ' input[name="delivery_at"]').val()
  runningmenu_address_id = $('#' + getRowID + ' select[name="runningmenu_address_id"]').val()
  if delivery_at && runningmenu_address_id
    $.ajax
      url: "/admin/schedulers/available_list?delivery_at="+delivery_at+"&delivery_type="+'pickup'+"&address_id="+runningmenu_address_id,
      success: (result) ->
        $('#' + getRowID + ' #runningmenu_driver_selection').html '<option value=""></option>'
        $.each result.drivers, (i, j) ->
          if j.id == driverSelectedID
            row = '<option value="' + j.id + '" selected="selected">' + j.first_name + ' ' + j.last_name + '</option>'
          else
            row = '<option value="' + j.id + '" >' + j.first_name + ' ' + j.last_name + '</option>'
          $(row).appendTo '#' + getRowID + ' #runningmenu_driver_selection'
          return
        return


populate_recent_sms = (driver_id) ->
  $.ajax
    url: '/admin/schedulers/chat_history'+'?driver='+driver_id
    type: 'get'
    success: (data) ->
      chatTILE = '#chat_'+driver_id
      $(chatTILE+' .messages').append data['message']
      return

# CHAT TILES

setCookie = (cname, cvalue, exdays) ->
  d = new Date
  d.setTime d.getTime() + exdays * 24 * 60 * 60 * 1000
  expires = 'expires=' + d.toGMTString()
  document.cookie = cname + '=' + cvalue + ';' + expires + ';'
  return

setMenuTypeCookie = (cname, cvalue, exdays) ->
  document.cookie = cname + '=' + cvalue + ';path=/'
  return

getCookie = (cname) ->
  name = cname + '='
  decodedCookie = decodeURIComponent(document.cookie)
  ca = decodedCookie.split(';')
  i = 0
  while i < ca.length
    c = ca[i]
    while c.charAt(0) == ' '
      c = c.substring(1)
    if c.indexOf(name) == 0
      return c.substring(name.length, c.length)
    i++
  ''

checkCookie = (rowID = '', chatState = '', active = '', driverName = '') ->
  chat = getCookie('chatList')
  if chat.length == 0
    chatObj = []
    chatObj.push [
      rowID
      chatState
      if active then active else ''
      driverName
    ]
    chatObj = JSON.stringify(chatObj)
    setCookie 'chatList', chatObj, 900
  else if chat.length >= 0
    chat = JSON.parse(chat)
    newArrayinCookie = [
      rowID
      chatState
      if active then active else ''
      driverName
    ]
    chat.push newArrayinCookie
    chat = JSON.stringify(chat)
    setCookie 'chatList', chat, 900
  return

setCookieState = (rowID = '', chatState = '', active = '', driverName = '') ->
  setCookie 'chatList', '', 900
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
    setCookie 'chatList', achat, 900
    i++
  return

loadChats = ->
  chat = getCookie('chatList')
  if chat != ''
    chat = JSON.parse(chat)
    i = 0
    while i < chat.length
      chatID = chat[i][0]
      console.log chatID
      App.global_driver = App.cable.subscriptions.create {
        channel: "DriversChannel"
        driver_id: chatID
      },
      connected: ->
        # Called when the subscription is ready for use on the server

      disconnected: ->
        # Called when the subscription has been terminated by the server

      received: (message) ->
        chatTILE = '#chat_'+message['driver_id']
        console.log message
        $(chatTILE+' .messages').append message['message']
        $(chatTILE+' .body').animate { scrollTop: $(chatTILE + ' .body.messages > div:last').offset().top }, 2000

      send_message: (message, chatID) ->
        @perform 'send_message', message: message, driver_id: chatID

      completeChatID = 'chat_' + chatID
      chatStatus = chat[i][1]
      chatActive = chat[i][2]
      driverName = chat[i][3]
      chatTile = '<div class="chatTile ' + chatActive + '" id="chat_' + chatID + '" data-chatid="' + chatID + '" data-chat-status="' + chatStatus + '">'
      chatTile += '<div class="header">'
      chatTile += '<div class="headText">' + driverName + '</div>'
      chatTile += '<div class="closeTile" data-win-id="chat_' + chatID + '"><i class="fa fa-times"></i></div>'
      chatTile += '</div>'
      chatTile += '<div class="body messages"><div class="welcomeMsg">Lets chat!</div></div>'
      chatTile += '<div class="footer">'
      chatTile += '<div class="senderPart">'
      chatTile += '<input type="text" class="bsInput" id="message_' + chatID + '" data-messageid="' + chatID + '"  message" placeholder="Enter your message..." autofocus />'
      chatTile += '<button type="button" class="bsInput send">Send</button>'
      chatTile += '</div>'
      chatTile += '</div>'
      chatTile += '</div>'
      $('body').append chatTile
      if chatStatus == 'min'
        $('#chat_' + chatID + ' .body, #chat_' + chatID + ' .footer').hide()
        $('#chat_' + chatID).css
          'top': 'calc(100vh + -40px)'
          'z-index': '2'
      setTimeout (->
        rePositionTiles()
        return
      ), 100
      i++
      populate_recent_sms(chatID)
  else
    console.log 'No chat to load'
  return

$(document).ready ->
  loadChats()
  $('#footer').append '<input type="hidden" id="driver_closed_chat" value="">'
  return

rePositionTiles = ->
  console.log "repositioning"
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
      rePositionTiles()
    return
  return

$(window).resize ->
  rePositionTiles()
  return

$(document).on 'click', '.chatTile', ->
  $('.chatTile').removeClass 'active'
  $(this).addClass 'active'
  $('#' + @id + ' .message').focus()
  $('.chatTile').css 'z-index': '1'
  $(this).css 'z-index': '2'
  setCookieState()
  return

$(document).on 'click', '#open_chat', ->
  rowID = $(this).attr('data-row-id')
  rowNAME = $(this).attr('data-row-name')


  checkTileExsit = $('#chat_' + rowID).length
  $('.chatTile').removeClass 'active'
  if checkTileExsit == 0
    if $('#driver_closed_chat').val().split(',').indexOf(rowID) < 0
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
      L_4: '<div class="closeTile" data-win-id="chat_' + rowID + '"><i class="fa fa-times"></i></div>'
      L_5: '</div>'
      L_6: '<div class="body messages"><div class="welcomeMsg">Lets chat!</div></div>'
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
    setCookieState()
    rePositionTiles()
    populate_recent_sms(rowID)
  else if checkTileExsit == 1
    $('#chat_' + rowID).css 'top': 'calc(100vh - 400px)'
    $('#chat_' + rowID + ' .body, #chat_' + rowID + ' .footer').show()
    $('#chat_' + rowID).attr 'data-chat-status', 'max'
  return

$(document).on 'click', '.closeTile', ->
  chatID = $(this).attr('data-win-id')
  $('#' + chatID).remove()
  checkActiveTile = $('.chatTile.active').length
  console.log checkActiveTile
  setTimeout (->
    if checkActiveTile == 0
      lastID = $('.chatTile').last().attr('id')
      $('#' + lastID).addClass 'active'
      $('#' + lastID + ' .message').focus()
      setCookieState()
    return
  ), 50
  rePositionTiles()
  $('#driver_closed_chat').val $('#driver_closed_chat').val() + ',' + chatID.split('_')[1]
  return

$(document).on 'click', '.headText', ->
  chatWinID = $(this).parent().parent().attr('id')
  chatTileStatus = $('#' + chatWinID).attr('data-chat-status')
  onlyIDNumber = chatWinID.replace('chat_', '')
  activeTile = $('#' + chatWinID + '.active').length
  if activeTile == 0
    activeTile = ''
  else if activeTile == 1
    activeTile = 'active'
  driverName = $('#' + chatWinID + ' .headText').text()
  if chatTileStatus == 'max'
    $('#' + chatWinID + ' .body, #' + chatWinID + ' .footer').hide()
    $('#' + chatWinID).css
      'top': 'calc(100vh + -40px)'
      'z-index': '2'
    $('#' + chatWinID).attr 'data-chat-status', 'min'
  else if chatTileStatus == 'min'
    $('#' + chatWinID).css
      'top': 'calc(100vh - 400px)'
      'z-index': '1'
    $('#' + chatWinID + ' .body, #' + chatWinID + ' .footer').show()
    $('#' + chatWinID).attr 'data-chat-status', 'max'
  setCookieState()
  return

delete_cookie = (name) ->
  document.cookie = name + '=;expires=Thu, 01 Jan 1970 00:00:01 GMT;'
  return

$(document).ready ->
  if window.location.pathname.includes('/admin/companies/') && window.location.pathname.includes('/edit')
    allSelect2 =  $('.select2-selection__rendered')
    i = 0
    while i < allSelect2.length
      if $(allSelect2[i]).attr('title') == 'Text'
        parent = $(allSelect2[i]).parents 'fieldset.has_many_fields'
        resultChild = $(parent).children('ol').children()[3]
        $(resultChild).hide()
      else if $(allSelect2[i]).attr('title') == 'Dropdown'
        parent = $(allSelect2[i]).parents 'fieldset.has_many_fields'
        resultChild = $(parent).children('ol').children()[3]
        $(resultChild).show()
      i++
# Bind an event
  $('.company_field_type').on 'select2:select', (e) ->
    data = e.params.data
    if data.text == 'Text'
      parent = $(this).parents 'fieldset.has_many_fields'
      resultChild = $(parent).children('ol').children()[3]
      $(resultChild).hide()
    else if data.text == 'Dropdown'
      parent = $(this).parents 'fieldset.has_many_fields'
      resultChild = $(parent).children('ol').children()[3]
      $(resultChild).show()
    return

  checkClassAvailable = $('#header #tabs > li.current').length
  if checkClassAvailable == 1
    $('#header #tabs > li.current > ul').addClass 'dBlock'
  return

$(document).on 'click', '.detailVU, .closeBtn', ->
  rowIDis = $(this).parent().parent().parent().attr('id')
  checkAlreadyBg = $('#' + rowIDis).hasClass('active')
  $('#index_table_schedulers tr').removeClass 'active'
  if checkAlreadyBg == false
    $('#' + rowIDis).addClass 'active'
  else if checkAlreadyBg == true
    $('#' + rowIDis).removeClass 'active'

  setTimeout (->
    rePositionTiles()
    return
  ), 1000
  return

$(document).on 'click', '#company_submit_action',(e) ->
  if $("form#new_company").length > 0
    e.preventDefault()
    $('li.company_admins_active').find('input.timezone').each ->
      timezone = $("#company_time_zone").val()
      $(this).val(timezone)
    $("form#new_company").submit()

$(document).on 'click', '#email_file_input_label', ->
  $('#files_input').trigger 'submit'
  return

$(document).on 'change', '#email_files', ->
  i = 0
  arr = []
  while i < $('#email_files')[0].files.length
    if $('#email_files')[0].files[i].size > 5242880
      alert $('#email_files')[0].files[i].name + ' file exceed max file size 5MB'
      $('#email_files').value = ''
      arr = []
      return
    else
      arr.push(i)
    i++
  filesLength = $('#email_files')[0].files.length
  if filesLength >= 1
    $('.multiFileSelected').val(arr)
    i = 0
    while i < filesLength
      fileName = $('#email_files')[0].files[i].name
      $( "#filesNameContainer" ).append '<div id="fileNameDiv_' + i + '"><span id="file_name_span_' + i + '"> ' + fileName + '</span><i id = "unselectFile_' + i + '" class="fa fa-times unselectFile" data-file-id=' + i + '></i></br></div>'
      i++
    # $('.fileCountSpan').text '' + filesLength + ' files selected'
    # $('.fileCountSpan').removeClass 'hidden_input_file'
    return

$(document).on 'click', '.unselectFile', ->
  fileId = $(this).attr('data-file-id')
  if fileId != undefined
    arr = $('.multiFileSelected').val().split(',')
    index = arr.indexOf(fileId)
    if index > -1
      arr.splice index, 1
      $(".multiFileSelected").val(arr.join(','))
      $('#fileNameDiv_' + fileId + '').remove()
      return
  else
    logID = $(this).attr('data-log-id')
    arr = $(".fileSelected").val().split(',')
    index = arr.indexOf(logID)
    if index > -1
      arr.splice index, 1
      $(".fileSelected").val(arr.join(','))
    $('#fileNameDiv_' + logID + '').remove()
    return

$(document).on 'change', '#cuisineslist_menu_type, #sequence_menu_type', ->
  $('a.has_many_remove').each ->
    $(this).click()
  $("a.has_many_add").click()

$(document).ready ->
  $('.selectStatusContainer .interactive-tag-select').on 'select2:close', (e) ->
    selectTag = $(e.target).parent()
    model = selectTag.data('model')
    objectId = selectTag.data('object_id')
    field = selectTag.data('field')
    tagContainer = $('.' + model + '-' + field + '-' + objectId + '-tag')
    statusTag = tagContainer.find('.status_tag')
    newValue = e.target.value
    newText = e.target.selectedOptions[0].text
    oldValue = selectTag.data('value')
    if newValue == oldValue
      selectTag.addClass 'select-container-hidden'
      tagContainer.removeClass 'interactive-tag-hidden'
    else
      url = tagContainer.data('url')
      data = id: objectId
      data[model] = {}
      data[model][field] = newValue
      $.ajax
        url: url
        data: data
        dataType: 'json'
        error: (result) ->
          $('.default-select[data-url="' + url + '"] select').val('active')
          if result.responseJSON.message == "Address line This address is in use of active meeting"
            $('#address_' + objectId + ' .col-status').append '<div id= "errorMsgContainer" style="color: red;"><strong>This address is in use of active meeting</strong></div>'
          else
            $('#address_' + objectId + ' .col-status').append '<div id= "errorMsgContainer" style="color: red;"><strong>Company Must Have one Address</strong></div>'
          setTimeout ->
            $('#errorMsgContainer').remove()
          , 1500
          return
        success: ->
          statusTag.text newText
          statusTag.removeClass oldValue
          statusTag.addClass newValue
          tagContainer.data 'value', newValue
          selectTag.data 'value', newValue
          return
        complete: ->
          selectTag.addClass 'select-container-hidden'
          tagContainer.removeClass 'interactive-tag-hidden'
          return
        type: 'PATCH'
    return
  return

$(document).ready ->
  $('#edit_menu .inline-hints').prepend '<i class="fa fa-times"></i>'
  $(document).on 'click', '.companyShowData .tag-select-container', ->
    SelectedVal = $(this).find('select').val()
    if SelectedVal == 'active'
      $(this).find('.select2-selection__rendered').text 'Active'
    else
      $(this).find('.select2-selection__rendered').text 'Deleted'
    return

  $(document).on 'click', '#edit_menu .inline-hints > i', ->
    checkIsSelected = $(this).parent().find('img').hasClass('selected')
    if checkIsSelected == false
      $(this).parent().find('img').addClass 'selected'
      $(this).parent().parent().next().find('input').prop('checked', true)
    else if checkIsSelected == true
      $(this).parent().find('img').removeClass 'selected'
      $(this).parent().parent().next().find('input').prop('checked', false)
    return

  return

$(document).ready ->
  if ($(".inline-errors").length > 0 || $("div.flashes .flash_notice").length > 0) && $("form.runningmenu").length > 0
    company_address_id = $("select#runningmenu_address_id").val();
    delivery_at = $("input#runningmenu_delivery_at").val();
    pickup_at = $("input#runningmenu_pickup_at").val();
    activation_at = $("input#runningmenu_activation_at").val();
    cutoff_at = $("input#runningmenu_cutoff_at").val();
    admin_cutoff_at = $("input#runningmenu_admin_cutoff_at").val();
    form_type = $("form").attr("id");
    if company_address_id and delivery_at and pickup_at and activation_at and cutoff_at and admin_cutoff_at
      $.ajax
        url: "/admin/schedulers/company_time_zone_error_case?company_address_id="+company_address_id+"&delivery_at="+delivery_at+"&pickup_at="+pickup_at+"&activation_at="+activation_at+"&cutoff_at="+cutoff_at+"&admin_cutoff_at="+admin_cutoff_at+"&form_type="+form_type,
        success: (result) ->
          $("input#runningmenu_delivery_at").val(result.result[0])
          $("input#runningmenu_pickup_at").val(result.result[1])
          $("input#runningmenu_activation_at").val(result.result[2]);
          $("input#runningmenu_cutoff_at").val(result.result[3]);
          $("input#runningmenu_admin_cutoff_at").val(result.result[4]);
          return
    return

$(document).ready ->
  if ($(".inline-errors").length > 0 || $("div.flashes .flash_notice").length > 0) && $("form.recurring_scheduler").length > 0
    company_address_id = $("select#recurring_scheduler_address_id").val();
    startdate = $("input#recurring_scheduler_startdate").val();
    form_type = $("form").attr("id");
    if company_address_id and startdate
      $.ajax
        url: "/admin/recurring_schedulers/company_time_zone_error_case?company_address_id="+company_address_id+"&startdate="+startdate+"&form_type="+form_type,
        success: (result) ->
          $("input#recurring_scheduler_startdate").val(result.result[0]);
          return
    return

$(document).ready ->
  $(document).on 'click', '.reportForm .formtastic li#scheduled_period_input .choices ol li label', ->
    $('.reportForm .formtastic li#scheduled_period_input .choices ol li label').removeClass('selectedRadio')
    $(this).addClass('selectedRadio')
    if $("input[name='scheduled_period']:checked").val()
      if $("input[name='scheduled_period']:checked").val() == 'daily'
        $('.reportForm #scheduled_time_input .label')[0].innerText = 'Day'
      else
        $('.reportForm #scheduled_time_input .label')[0].innerText = $("input[name='scheduled_period']:checked").val().replace('ly', '')
    $('.reportForm #scheduled_time_input').show()
    return
  setTimeout (->
    $('.inline-hints img').each ->
      checkSrc = $(this).attr('src')
      if checkSrc == ''
        $(this).closest('.inline-hints').hide()
      return
    return
  ), 100
  setTimeout (->
    $('#runningmenu_address_ids').next().addClass('listener-element')
    return
  ), 100
  return

setDeliveryTypeCookie = (cname, cvalue, exdays) ->
  document.cookie = cname + '=' + cvalue + ';path=/'
  return

setDeliveryAtCookie = (cname, cvalue, exdays) ->
  document.cookie = cname + '=' + cvalue + ';path=/'
  return

$(document).ready ->
  delivery_type_hint = $("select#runningmenu_delivery_type").val();
  if delivery_type_hint == "delivery"
    $("#runningmenu_address_ids_input").append('<p class="inline-hints">Only 1 restaurant allowed in case of delivery</p>')
  $(document).on 'change', 'select#runningmenu_delivery_type', (e) ->
    delivery_type = $("select#runningmenu_delivery_type").val();
    if delivery_type == "delivery"
      $("#runningmenu_address_ids_selected_values").html ''
      $("#runningmenu_address_ids_selected_values").html('<input id="runningmenu_address_ids_empty" name="runningmenu[address_ids][]" value="" type="hidden">')
      $("#runningmenu_address_ids_input").append('<p class="inline-hints">Only 1 restaurant allowed in case of delivery</p>')
    else
      $("#runningmenu_address_ids_selected_values").html ''
      $.ajax
        url: "/admin/schedulers/runningmenu_beverages_restaurant?addresses="
        success: (result) ->
          $("#runningmenu_address_ids_selected_values").append(result.str_html)
          $("p.inline-hints").remove()
    return
  return

 $(document).on 'click', '.listener-element', ->
    menu_type = $("select#runningmenu_menu_type").val();
    delivery_type = $("select#runningmenu_delivery_type").val();
    delivery_at = $("#runningmenu_delivery_at").val();
    url_ = $("select#runningmenu_address_ids").attr('data-url');
    setMenuTypeCookie 'menu_type', menu_type, 900
    setDeliveryTypeCookie 'delivery_type', delivery_type, 900
    setDeliveryAtCookie 'delivery_at', delivery_at, 900
    $('#runningmenu_address_ids').on 'select2:selecting', ->
      if $('#runningmenu_address_ids_selected_values').children().last().text().indexOf('Beverages') == 0
        container = $('#runningmenu_address_ids_selected_values').children().last()
        $('#runningmenu_address_ids_selected_values').children().last().remove()
        $('#runningmenu_address_ids').on 'select2:select', ->
          if $('#runningmenu_address_ids_selected_values').children().last().text().indexOf('Beverages') == -1
            $('#runningmenu_address_ids_selected_values').append container
            container = ''
            return
          return
      return
   return

