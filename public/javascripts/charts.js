function replaceJqplotRenderers(options) {
  for (option in options) {
    switch(typeof(options[option])) {
      case 'object':
        replaceJqplotRenderers(options[option]);
        break;
      case 'string':
        if (/^\$\.jqplot\.\w+$/.test(options[option])) {
          options[option] = eval(options[option]);
        };
    };
  };
};

function dateChanged(dateText, inst) {
  var date = $('#date').datepicker('getDate');
  var window = $('#window').slider('value');
  if (date <= $('#date').datepicker('option', 'minDate')) {
    $('#prev').hide(null);
  } else {
    $('#prev').show(null);    
  };
  if (date >= $('#date').datepicker('option', 'maxDate')) {
    $('#next').hide(null);
  } else {
    $('#next').show(null);    
  };
  $('.chart').empty();
  $('.chart').each(function(index, chart) {
    var id = /^chart_(\d+)$/.exec(chart.id)[1];
    var url = '/charts/'+id+'.json?date='+date.toDateString()+'&window='+window;
    jQuery.getJSON(url, function(result) {
      replaceJqplotRenderers(result.options);
      $.jqplot(chart.id, result.data, result.options);
    });
  });
};

$(function() {
  jQuery.getJSON('/observation_range.json', function(range) {
    var options = {
      changeMonth: true,
      changeYear: true,
      minDate: new Date(range.minDate),
      maxDate: new Date(range.maxDate),
      onSelect: function(dateText, inst) { dateChanged(); }
    };
    $('#date').datepicker(options);
    dateChanged();    
  });
  $('#prev').click(function() {
    var date = $('#date').datepicker('getDate')
    $('#date').datepicker('setDate', new Date(date.getTime() - 86400000 * (1 + 2 * $('#window').slider('value'))));
    dateChanged();
  })
  $('#next').click(function() {
    var date = $('#date').datepicker('getDate')
    $('#date').datepicker('setDate', new Date(date.getTime() + 86400000 * (1 + 2 * $('#window').slider('value'))));
    dateChanged();
  })
  $('#window').slider({
    value: 0,
    min: 0,
    max: 3,
    step: 1,
    stop: function(event, ui) { dateChanged(); }
  });
});
