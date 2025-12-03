package.path = "./?.lua;./?/init.lua;" .. package.path

local ffi = require("ffi")
local bit = require("bit")
local sdl = require("scripts.SDL3")
local imgui = require("scripts.cimgui")
local ImGui_SDL = require("scripts.imgui_sdl3_impl")
local nfd = require("scripts.nfdex")

require("scripts.helpers")

-- Initialize video subsystem
local ok = sdl.SDL_Init(sdl.SDL_INIT_VIDEO)
if not ok then
  error("SDL_Init failed: " .. ffi.string(sdl.SDL_GetError()))
end

-- Global variables
Width, Height = 960, 540
WIN_W, WIN_H = Width, Height

-- Create a window
local win = sdl.SDL_CreateWindow("Serie Mini", WIN_W, WIN_H, sdl.SDL_WINDOW_RESIZABLE)
if not win then
  error("SDL_CreateWindow failed: " .. ffi.string(sdl.SDL_GetError()))
end

sdl.SDL_StartTextInput(win)

-- Create a renderer
local ren = sdl.SDL_CreateRenderer(win, ffi.NULL)
if ren == nil or ren == ffi.NULL then
  error("SDL_CreateRenderer failed: " .. ffi.string(sdl.SDL_GetError()))
end

ImGui_SDL.Init(ren, win)
nfd.Init()

-- Init App (code in App.lua)
local app = require("app")

--local tex = sdl.SDL_LoadTexture(renderer, "assets/images/Kibo.png")

local file_filters = {
  { name = "Text Files", spec = "txt,lua,json" },
  { name = "Images", spec = "png,jpg" }
}


local event = ffi.new("SDL_Event[1]")
local running = true

-- FPS Managing
local cap_fps = true  -- Set to false for uncapped performance
local target_fps = 60
local target_frame_time = 1000 / target_fps  -- ~16.666ms
local last_time = getTicks()
local frame_start_time = last_time
local frame_count = 0
local fps = 0
local last_fps_time = last_time

sdl.SDL_RenderTexture(ren, tex, nil, nil)

local function handleEvents()
  -- SDL Events
  while sdl.SDL_PollEvent(event) do

    ImGui_SDL.ProcessEvent(event[0]) -- Pass event to ImGui

    local eventType = event[0].type

    if eventType == sdl.SDL_EVENT_QUIT then
      running = false
      print("QUIT")
    end

    if eventType == sdl.SDL_EVENT_WINDOW_RESIZED then
      -- In case resizing needs to be addressed
      --win_w, win_h = getWindowSize()
    end

    if eventType == sdl.SDL_EVENT_MOUSE_BUTTON_DOWN then
      print("BTN")
      local mouseButton = ffi.cast("SDL_MouseButtonEvent*", event)
      print(mouseButton.button)
      -- 1 left 3 right
      if (mouseButton.button == 3) then
        --local path = nfd.Open(nil, file_filters)
        --if path then print(path) end
      end
    end

    if eventType == sdl.SDL_EVENT_MOUSE_MOTION then
      local mouseMotion = ffi.cast("SDL_MouseMotionEvent*", event)
      -- print("Mouse moved to", mouseMotion.x, mouseMotion.y, "rel", mouseMotion.xrel, mouseMotion.yrel)
    end

    if eventType == sdl.SDL_EVENT_KEY_DOWN or eventType == sdl.SDL_EVENT_KEY_UP then
      local keyEvent = ffi.cast("SDL_KeyboardEvent*", event)
      local keycode = keyEvent.scancode
      local key = keyEvent.key
      local keyMod = keyEvent.mod
      local repeatKey = keyEvent["repeat"]
      local isDown = etype == 0x300
      print("Key:", key, keyMod, repeatKey, isDown and "down" or "up")
    end

  end
end

-- Main loop
while running do
  -- Frame calculations
  frame_start_time = getTicks()
  local delta_time = (frame_start_time - last_time) / 1000.0  -- Delta in seconds
  last_time = frame_start_time

  handleEvents()

  -- ImGui Frame
  ImGui_SDL.NewFrame()

  -- Update App (Code in app.lua)
  app.Update(delta_time, fps)
  app.Draw(delta_time, fps)

  -- Background
  sdl.SDL_SetRenderDrawColor(ren, 0, 0, 0, 255)
  sdl.SDL_RenderClear(ren)

  -- Show Render
  ImGui_SDL.Render()
  sdl.SDL_RenderPresent(ren)

  -- FPS calculation
  frame_count = frame_count + 1
  local current_time = getTicks()
  local elapsed = current_time - frame_start_time

  if current_time - last_fps_time >= 1000 then
    fps = frame_count
    frame_count = 0
    last_fps_time = current_time
  end
  
  -- frame capping
  if cap_fps then
      local frame_time = getTicks() - frame_start_time
      if frame_time < target_frame_time then
          sdl.SDL_Delay(target_frame_time - frame_time)
      end
  end

end

print("END")

-- Clean up
nfd.Shutdown()
ImGui_SDL.Shutdown()
sdl.SDL_DestroyTexture(tex)
if ren ~= nil then sdl.SDL_DestroyRenderer(ren) end
if win ~= nil then sdl.SDL_DestroyWindow(win) end
sdl.SDL_Quit()