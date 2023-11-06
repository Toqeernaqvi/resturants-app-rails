$(document).ready ->
  populate_recurring_runningmenufields()
  recurring_populate_drivers_combo()
  recurring_toggle_new_runningmenu_fields()
  check_recurrence_error()
  if $('#recurring_scheduler_per_user_copay_input').length
    if !$('#recurring_scheduler_per_user_copay').prop('checked')
      $('#recurring_scheduler_per_user_copay_amount_input').hide()

    $('label > #recurring_scheduler_per_user_copay').click ->
      $('#recurring_scheduler_per_user_copay_amount_input').toggle @checked
      return
  if $("#recurring_scheduler_bev_rest_deleted").length
    $(document).on 'click', '#recurring_scheduler_address_ids_'+ $('#recurring_scheduler_bev_rest_id').val(), ->
      $("#recurring_scheduler_bev_rest_deleted").val(true)

populate_recurring_runningmenufields = ->
  company_address_id = $("select#recurring_scheduler_address_id").val();
  recurring_scheduler_id = $("#recurring_scheduler_id").val();
  if company_address_id
    $.ajax
      url: "/admin/addresses/"+company_address_id+"/recurring_company_fields?recurring_scheduler_id=" +recurring_scheduler_id
      success: (result) ->
        $("#recurring_wrapper_fields").html(result.data)
        return

populate_recurring_runningmenutags = ->
  company_address_id = $("select#recurring_scheduler_address_id").val();
  if company_address_id
    $.ajax
      url: "/admin/addresses/"+company_address_id+"/runningmenu_tags"
      success: (result) ->
        $("select#recurring_scheduler_tag_list").empty().select2({data: result})
        $("input[name='recurring_scheduler[tag_list][]']").val($("select#recurring_scheduler_tag_list").val().join(','))
        return

#$(document).on 'change', '#recurring_scheduler_address_id', ->
  #populate_recurring_runningmenufields()

$(document).on 'change', '#recurring_scheduler_address_id', ->
  #filter()
  recurring_update_budget()
  populate_recurring_runningmenufields()
  populate_recurring_runningmenutags()
  company_address_id = $(this).val();
  meal_type = $("select#recurring_scheduler_menu_type").val();
  recurring_scheduler_id = $("form").attr("action").split("/")[3]
  $.ajax
    url: "/admin/schedulers/recurring_company_admins?id=" +recurring_scheduler_id+ "&company_address_id=" +company_address_id
    success: (result) ->
      $("#recurring_scheduler_user_id").html(result.data)
  $.ajax
    url: "/admin/schedulers/company_delivery_notes?type=recurring&id=" +recurring_scheduler_id+ "&company_address_id=" +company_address_id
    success: (result) ->
      $(".delivery_notes_li").remove()
      $("#recurring_scheduler_delivery_instructions_input").after(result.data)
      return
  return

check_recurrence_error = ->
  if $("#recurring_scheduler_startdate_input.error").length > 0
    $("#ui-id-3").click()

recurring_update_budget = ->
  company_address_id = $("select#recurring_scheduler_address_id").val();
  if company_address_id
    $.ajax
      url: "/admin/addresses/"+company_address_id+"/company_budget"
      success: (result) ->
        $("#recurring_scheduler_per_meal_budget").val(result.budget)
        if result.user_copay == 1 && $("#recurring_scheduler_menu_type").val() == "individual"
          $("#recurring_scheduler_per_user_copay").prop("checked", true);
          $('#recurring_scheduler_per_user_copay_amount_input').show()
        else
          $("#recurring_scheduler_per_user_copay").prop("checked", false)
          $('#recurring_scheduler_per_user_copay_amount_input').hide()
        $("#recurring_scheduler_per_user_copay_amount").val(result.copay_amount)
  return

recurring_toggle_new_runningmenu_fields = ->
  arr = []
  items = document.getElementsByClassName('selected-item')
  i = 0
  while i < items.length
    arr.push items[i].id.substr(items[i].id.length - 3)
    i++
  if $("#recurring_scheduler_menu_type").val() == "buffet"
    $("li#recurring_scheduler_per_meal_budget_input").hide()
    $("li#recurring_scheduler_per_user_copay_input").hide()
    $("li#recurring_scheduler_per_user_copay_amount_input").hide()
    if $('form#new_recurring_scheduler').length > 0
      $.ajax
        url: "/admin/schedulers/runningmenu_beverages_restaurant_has_buffet_menu"
        success: (result) ->
          if result.str_html == false
            $("#recurring_scheduler_address_ids_selected_values").html ''
            $("#recurring_scheduler_address_ids_selected_values").html('<input id="recurring_scheduler_address_ids_empty" name="recurring_scheduler[address_ids][]" value="" type="hidden">')
          else
            $("#recurring_scheduler_address_ids_selected_values").html ''
            $("#recurring_scheduler_address_ids_selected_values").html('<input id="recurring_scheduler_address_ids_empty" name="recurring_scheduler[address_ids][]" value="" type="hidden">')
            $.ajax
              url: "/admin/schedulers/recurring_runningmenu_beverages_restaurant?addresses="+arr
              success: (result) ->
                $("#recurring_scheduler_address_ids_selected_values").append(result.str_html)
                $("#recurring_scheduler_first_restaurant").val(result.beverages_restaurant_location_id)
  else
    $("li#recurring_scheduler_per_meal_budget_input").show()
    $("li#recurring_scheduler_per_user_copay_input").show()
    if $("#recurring_scheduler_per_user_copay").prop("checked")
      $("li#recurring_scheduler_per_user_copay_amount_input").show()
    else
      $("li#recurring_scheduler_per_user_copay_amount_input").hide()
    if $('form#new_recurring_scheduler').length > 0
      $("#recurring_scheduler_address_ids_selected_values").html ''
      $("#recurring_scheduler_address_ids_selected_values").html('<input id="recurring_scheduler_address_ids_empty" name="recurring_scheduler[address_ids][]" value="" type="hidden">')
      $.ajax
        url: "/admin/schedulers/recurring_runningmenu_beverages_restaurant?addresses="+arr
        success: (result) ->
          $("#recurring_scheduler_address_ids_selected_values").append(result.str_html)
          $("#recurring_scheduler_first_restaurant").val(result.beverages_restaurant_location_id)

recurring_populate_drivers_combo = ->
  $.ajax
    url: "/admin/schedulers/recurring_available_list",
    success: (result) ->
      driver_id = $("#recurring_scheduler_selected_driver_id").val()
      $("#recurring_scheduler_driver_id").html('<option value=""></option>');
      $.each result.drivers, (i, j) ->
        if j.id == parseInt( driver_id )
          row = '<option value="' + j.id + '" selected="selected">' + j.first_name + ' ' + j.last_name + '</option>'
        else
          row = '<option value="' + j.id + '">' + j.first_name + ' ' + j.last_name + '</option>'
        $(row).appendTo '#recurring_scheduler_driver_id'
        return
      return

$(document).on 'change', '#recurring_scheduler_menu_type', ->
  recurring_toggle_new_runningmenu_fields()
  #filter()
  return
#$(document).on 'change', '#recurring_scheduler_orders_count', ->
  #recurring_populate_drivers_combo()
  #return
$(document).on 'change', '#recurring_scheduler_runningmenu_type', ->
  #filter()
  return
$(document).on 'change', '#recurring_scheduler_address_id', ->
  #filter()
  #update_map()
  recurring_update_budget()
  populate_recurring_runningmenufields()
  company_address_id = $(this).val();
  meal_type = $("select#recurring_scheduler_menu_type").val();
  recurring_scheduler_id = $("form").attr("action").split("/")[3]
  $.ajax
    url: "/admin/schedulers/recurring_company_admins?id=" +recurring_scheduler_id+ "&company_address_id=" +company_address_id
    success: (result) ->
      $("#recurring_scheduler_user_id").html(result.data)
  $.ajax
    url: "/admin/schedulers/company_delivery_notes?type=recurring&id=" +recurring_scheduler_id+ "&company_address_id=" +company_address_id
    success: (result) ->
      $(".delivery_notes_li").remove()
      $("#recurring_scheduler_delivery_instructions_input").after(result.data)
      $("#recurring_scheduler_delivery_instructions").val(result.delivery_instructions)
      return
  return

$(document).ready ->
  if $('#recurring_scheduler_address_id').length
    company_address_id = $('#recurring_scheduler_address_id').val()
    recurring_scheduler_id = $("form").attr("action").split("/")[3]
    if company_address_id
      #$.ajax
        #url: "/admin/schedulers/recurring_company_admins?id=" +recurring_scheduler_id+ "&company_address_id=" +company_address_id
        #success: (result) ->
          #$("#recurring_scheduler_user_id").html(result.data)
      $.ajax
        url: "/admin/schedulers/company_delivery_notes?id=" +recurring_scheduler_id+ "&company_address_id=" +company_address_id
        success: (result) ->
          $(".delivery_notes_li").remove()
          $("#recurring_scheduler_delivery_instructions_input").after(result.data)
          return
    return

$(document).on 'change', 'select#recurring_scheduler_cuisine_ids', ->
  #filter()
  return
$(document).on 'change', 'input#recurring_scheduler_per_meal_budget', ->
  #filter()
  return

$(document).ready ->
  divData2Move = $('#recurring_scheduler_address_ids_input > div > #recurring_scheduler_address_ids_selected_values').html()
  $('#recurring_scheduler_address_ids_input span.select2-selection.select2-selection--multiple').prepend '<div id="recurring_scheduler_address_ids_selected_values" class="selected-values">' + divData2Move + '</div>'
  $('#recurring_scheduler_address_ids_input > div > #recurring_scheduler_address_ids_selected_values').remove()
  if $("#recurring_scheduler_dynamic_sections_address_ids").length
    arr = $("#recurring_scheduler_dynamic_sections_address_ids").val().split(" ")
    $.each arr, (index, val) ->
      $('#recurring_scheduler_address_ids_selected_values .selected-item').each ->
        if $(this).is("#recurring_scheduler_address_ids_"+val)
          $(this).hide()
      return
    return
  return

#$(document).ready ->
  #$(document).on 'change', '.runningmenu_driver', ->
    #fieldValue = @value
    #rowID = $(this).attr('data-row-ID')
    #$.post 'schedulers/'+rowID+'/driver', {
      #id: rowID
      #driver_id: fieldValue
    #}, ((data) ->
    #), 'json'
    #return
  #return

#$(document).on 'change', '#recurring_scheduler_address_id, #recurring_scheduler_menu_type', ->
  #menu_type = $("select#recurring_scheduler_menu_type").val();
  #company_address_id = $("select#recurring_scheduler_address_id").val();
  #if menu_type == "buffet" and company_address_id
    #filter()
  #return
