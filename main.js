$(document).ready(function() {
  $('#eval').click(function() {
    try {
      var result = calculator.parse($('#input').val());
      $('#output').html(JSON.stringify(result, undefined, 2));
    } catch (e) {
      $('#output').html("<div class='error'><pre>\n" + String(e) + '\n</pre></div>');
    }
  });
});
