# Persist scroll position on page updates.
pagesWithPersistentScrolls = ['.suite']

# Storing scroll positions of scrollable elements.
persistentScrollsPositions = {}

$(document).on 'page:receive', ->
  persistentScrollsPositions = {}
  for selector in pagesWithPersistentScrolls
    if $(selector).length > 0
      persistentScrollsPositions[selector] = $('html, body').scrollTop()

$(document).on 'page:load', ->
  for selector, scrollTop of persistentScrollsPositions
    if $(selector).length > 0
      $('html, body').scrollTop scrollTop
      return
