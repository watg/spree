core.RakutenTrackingPixel = {};

$(document).on("ready page:load", function() {
  core.RakutenTrackingPixel.persistMID();
});


core.RakutenTrackingPixel.persistMID = function() {
   var mid = core.RakutenTrackingPixel.getUrlParameter("mid");
    if(mid){
      $.cookie("rakuten_mid", mid, { path: "/", expires: 1 });
    }
};

core.RakutenTrackingPixel.insertTrackingImage = function(rakuten_params) {
  var base_url = "http://track.linksynergy.com/ep?",
      mid = $.cookie("rakuten_mid");
  if(mid) {
    rakuten_params.mid = mid;
    rakuten_params = jQuery.map(rakuten_params,function(v, k){
                        return k + "=" + v;
                     }).join("&");
    $( "body" ).append("<img src='" + base_url + rakuten_params + "'>");
  }
};

core.RakutenTrackingPixel.getUrlParameter= function (sParam)
{
    var sPageURL = window.location.search.substring(1);
    var sURLVariables = sPageURL.split("&");
    for (var i = 0; i < sURLVariables.length; i++){
        var sParameterName = sURLVariables[i].split("=");
        if (sParameterName[0] == sParam){
            return sParameterName[1];
        }
    }
};
