core.Search = {};

$(document).on("ready page:load", function() {
  // Only start predictable search on desktop
  if (!(core.isLessThanTabletWidth() || $('body.mobile').length)) {
    core.Search.readyPredictableSearch();
  }
});

core.Search.readyPredictableSearch = function() {
  $('#search-input').awesomecomplete({
    noResultsMessage: '',
    typingDelay:500,
    nameField: 'title',
    resultLimit: 999,
    dataMethod: getResults(),
    renderFunction: renderOption(),
    sortFunction: function() {
      return -1; // sorting is handled on api side
    },
    onComplete: function(dataItem){
      var link = $("."+this.suggestionListClass).find("."+this.activeItemClass).find('a');
      location.href=$(link).attr('href');
      ga('send', 'pageview', '/s?search_category=autocomplete&keywords=' + $(this).find('span').text());
    }
  });

  function getResults(){
    return function(term, _awesomecomplete, onData){
      var searchOption = {url:"/s" + '?keywords=' + term, title: term, image_url: "", target:""};
      if (term.length >= 3) {
        $.ajax({
          data: { keywords: term } ,
          url: "/api/predictable_search/search"
        }).done(function( data ) {
          data = disambiguateResults(data);
          data.unshift(searchOption);
          onData(data)
        });
      }else {
        onData([searchOption])
      }
    }
  }

  function disambiguateResults(data){
    var disambiguated = jQuery.extend(true, [], data);
    disambiguated.map(function(e){
      e.target = "";
    });


    for (var j=0; j < data.length; j++) {
      for (var i = 0; i < data.length; i++) {
        if (data[j].target !== null && data[i].title == data[j].title && i !== j) {
          disambiguated[j].target =  data[j].target.toLowerCase();
          disambiguated[i].target = data[i].target.toLowerCase();
        }
      }
    }
    return disambiguated
  }

  function renderOption(){
    return function(dataItem, topMatch, originalDataItem){
      var url = originalDataItem['url'],
          title = dataItem['title'],
          target = originalDataItem['target'],
          image_url = originalDataItem['image_url'];
      var image = '';
      if (image_url!==null && image_url.length > 0) {
        image = '<img class="search-image" src="' + image_url +'"/>';
      }
      return '<a href="'+ url +'" class="ga-track-search"> ' + image + ' <span>'+ title +' <em>'+ target +'</em></span></a>';
    }
  }
};