var valueOrDefault = function(obj, value, def) {
  if (typeof obj[value] == 'undefined') {
    obj[value] = def;
  }
};

exports.show = function(markup, params) {
  params = params || {};
  valueOrDefault(params, 'afterClose', function() {});
  valueOrDefault(params, 'overlay', true);
  valueOrDefault(params, 'closeButton', true);
  valueOrDefault(params, 'opacity', 0.2);
  valueOrDefault(params, 'escape', true);

  $(document).bind('afterClose.facebox', params.afterClose);

  // resets the box. required when the markup from the first
  // display has been removed when the second one occurs.
  // delete $.facebox.settings.inited;

  $.facebox.settings.overlay = params.overlay;
  $.facebox.settings.opacity = params.opacity;
  $.facebox(markup);

  if (typeof params.top !== 'undefined') {
    $("#facebox").css("top", params.top + "px");
  }

  if (!params.escape) {
    $(document).unbind('keydown.facebox');
  }

  if (!params.closeButton) {
    $('#facebox .close').remove();
  }
};

exports.close = function(afterClose) {
  if (afterClose) {
    $(document).bind('afterClose.facebox', function() {
      afterClose();
      $(document).unbind('afterClose.facebox');
    });
  }

  $.facebox.close();
};
