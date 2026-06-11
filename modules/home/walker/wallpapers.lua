Name = "wallpapers"
NamePretty = "Wallpapers"
Icon = "preferences-desktop-wallpaper"
Cache = false
Action = "my-rwall -n %VALUE%"

function GetEntries()
  local entries = {}
  local preview_dir = os.getenv("HOME") .. "/Pictures/wallpapers/preview"
  local handle = io.popen('find "' .. preview_dir .. '" -maxdepth 1 -type f')
  if handle then
    for path in handle:lines() do
      local filename = path:match("([^/]+)$")

      local clean = filename:match("(.+)%.") or filename
      local display = clean:gsub("[_%-]", " ")

      table.insert(entries, {
        Text = display,
        Value = filename,
        Icon = path,
        Preview = path,
        PreviewType = "file"
      })
    end
    handle:close()
  end 
  return entries
end
