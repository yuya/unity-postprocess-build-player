#!/usr/bin/osascript

set envList to {"Product", "Development"}

choose from list envList ¬
  with title "Unity iOS Builder" ¬
  with prompt "Choose Environment:" ¬
  default items "Product"

return result
