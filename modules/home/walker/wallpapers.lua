Name = "wallpapers"
NamePretty = "Wallpapers"
Icon = "preferences-desktop-wallpaper"
Cache = false
Action = "my-rwall -n %VALUE%"

function GetEntries()
  local entries = {}
  local preview_dir = os.getenv("HOME") .. "/Pictures/wallpapers/preview"
  local handle = io.popen("ls '" .. preview_dir .. "'")
  if handle then
    for filename in handle:lines() do
      local clean = filename:match("(.+)%.") or filename
      local display = clean:gsub("[_%-]", " ")
      table.insert(entries, {
        Text = display,
        Value = filename,
        Icon = preview_dir .. "/" .. filename,
        Preview = preview_dir .. "/" .. filename,
        PreviewType = "file"
      })
    end
    handle:close()
  end
  return entries
end
