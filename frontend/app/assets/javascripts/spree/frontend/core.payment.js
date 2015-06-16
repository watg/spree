core.payment = {};

var readyPayment = function() {
  if (!$('body').hasClass('payment')) return false;
  core.payment.readyPreparePaymentPage();
};

core.payment.readyPreparePaymentPage = function() {
  Spree.paymentMethods();
  Spree.disableSaveOnClick();
}

$(document).on('page:load ready', readyPayment);
