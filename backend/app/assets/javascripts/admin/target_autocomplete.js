$(document).ready(function() {
    var targetDropdown = $(".target-dropdown").first();
    if (targetDropdown) {
    	var format = function(item) { return item.name; };
    	$.ajax({
    	    url: Spree.routes.targets_search,
    	    dataType: 'json',
    	    success: function(data) {
    		targetDropdown.select2({
    		    placeholder: "Select a target",
    		    multiple: targetDropdown.data("multiple"),
    		    data: { results: data, text: 'name' },
    		    formatSelection: format,
    		    formatResult: format
    		});
    	    }
    	});
    }
});
