core.Checkout = {};

$(document).on("ready page:load", function() {
    if ($('.shipping-methods').length > 0) {
        core.Checkout.readyShippingMethodChangeHandler();
    }
});

core.Checkout.readyShippingMethodChangeHandler = function() {
    $(".shipping-rate").change(function() {
        var form = $("#checkout_form_delivery");

        // Disabling the submit button stops race conditions where they change
        // the shipping method a couple of times in quick succession and then hit
        // submit. There is a risk that previous form POSTs could still be in-flight
        // when they hit submit and we get an unexpected result.
        form.find("input[type='submit']").prop('disabled', true).val('Processing...');

        // Adding this hidden field stops automatically advancing to the next
        // checkout stage.
        form.append($('<input type="hidden" name="no_advance" value="true">'));

        // Submit the form to work out the new shipping costs.
        form.submit();
    });
};