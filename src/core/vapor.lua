local vapor = {}

vapor.currently_downloading = {}

function vapor.imgname(gameobj)
  return gameobj.id..".png"
end

function vapor.fname(gameobj,sourceindex)
  return gameobj.id.."-"..sourceindex..".love"
end

function vapor.execgame(binarypath, gamepath)
  local execstr
  if love._os == "Windows" then
    local fstr = [[start "" "%s" "%%APPDATA%%/LOVE/vapor-data/%s"]]
    execstr = fstr:format(binarypath, gamepath)
  else
    -- OS X, Linux
    local fstr = [["%s" "%s/%s" &]]
    execstr = fstr:format(binarypath, love.filesystem.getSaveDirectory(), gamepath)
  end
  print(gamepath.." starting.")
  return os.execute(execstr)
end

function vapor.dogame(gameobj)

  local fn = vapor.fname(gameobj,gameobj.stable)
  if not vapor.currently_downloading[fn] then
    
    if love.filesystem.exists(fn) then
      print(fn .. " exists.")
      
      local hash
      if love.filesystem.exists(fn..".sha1") then
        hash = love.filesystem.read(fn..".sha1")
      end
      if gameobj.hashes[gameobj.stable] == hash then
        print(fn .. " hash validated.")
        local status = vapor.execgame(binary, fn)
      else
        if gameobj.invalid then
          gameobj.invalid = nil
          love.filesystem.remove(fn)
          love.filesystem.remove(fn..".sha1")
        else
          gameobj.invalid = true
          print(fn .. " hash not validated.")
        end
      end
    else
      print(fn .. " is being downloaded.")
      local url = gameobj.sources[gameobj.stable]
      vapor.currently_downloading[fn] = true
      downloader:request(url, async.love_filesystem_sink(fn,true), function()
        vapor.currently_downloading[fn] = nil
        ui.download_change = true
      end)
    end
  
  end
end

function vapor.deletegame(index)
  local gameobj = remote.data.games[index]
  if gameobj and not vapor.currently_downloading[vapor.fname(gameobj,gameobj.stable)] then
    love.filesystem.remove(vapor.fname(gameobj,gameobj.stable))
    love.filesystem.remove(vapor.fname(gameobj,gameobj.stable)..".sha1")
    love.filesystem.remove(vapor.imgname(gameobj))
    ui.images[index] = nil
    gameobj.invalid = nil
    ui.download_change = true
  end
end

function vapor.favoritegame(index)
  local gameobj = remote.data.games[index]
  if gameobj then
    settings.data.games[gameobj.id].favorite = 
      not settings.data.games[gameobj.id].favorite
  end
  ui.list.favorites = ui.update_list(ui.list.favorites,ui.conditions.favorites)
end



function vapor.visitwebsitegame(index)
  local gameobj = remote.data.games[index]
  if gameobj and gameobj.website then
    openURL(gameobj.website)
  end
end

return vapor
