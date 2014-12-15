jQuery.fn.filterMembers = (members, { callback }) ->
  input = this
  members = jQuery(members)
  callback = callback or jQuery.noop
  input.on 'input', ->
    value = input.val().toLowerCase()
    members.each ->
      text = @textContent
      @style.display = if text.toLowerCase().indexOf(value) >= 0
        'inline-block' if @style.display is 'none'
      else
        'none' unless @style.display is 'none'
    callback value, members

init = ->
  { controller, action } = $('body').data()

  switch controller + '#' + action
    when 'team#index'
      tivate = (state) ->
        $(this).parent().attr('data-state', state)

      $('.js-member-filter').filterMembers $('.member'), callback: (value, members) ->
        hidden = members.filter(':hidden')
        visible = members.filter(':visible')
        if visible.length is members.length
          members.each -> tivate.call(this, null)
        else
          hidden.each -> tivate.call(this, 'inactive')
          visible.each -> tivate.call(this, 'active')

    else
      # On any other page

$ init
$(document).on 'page:load', init
