# This introduces a bug when creating a new payment, which prevents
# the credit card details form from showing (it hides it for permanent)
# $ ->
#   if $('.new_payment').is('*')
#     # $('.payment-method-settings fieldset').addClass('hidden').first().removeClass('hidden')
#     $('input[name="payment[payment_method_id]"]').click ()->
#       $('.payment-method-settings fieldset').addClass('hidden')
#       id = $(this).parents('li').data('id')
#       $("fieldset[data-id='#{id}']").removeClass('hidden')
