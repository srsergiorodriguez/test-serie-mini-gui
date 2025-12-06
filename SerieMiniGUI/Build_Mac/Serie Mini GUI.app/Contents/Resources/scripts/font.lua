local ffi = require("ffi")
local utf8 = require('lib.luaLibs.utf8')
local sdl = require("lib.SDL3.init")
local sdlttf = require("lib.SDL3_TTF.init")

CurrentFont = "Pixafont"

function SetupFonts()
	local fonts = {
		Pixafont = {
			data = {},
			font = nil,
			path = "assets/fonts/Pixafont.ttf",
			glyphs = "ABCDEFGHIJKLMNÑOPQRSTUVWXYZ _-abcdefghijklmnñopqrstuvwxyz@()áéíóúü¡!¿?{}&$%=+/*«[]|\".,;:º█êëèïîìôöòù1234567890",
      cache = {}, -- textWidth, textHeight and pixels
      uppercase = false
		},
    PixaMini = {
			data = {},
			font = nil,
			path = "assets/fonts/PixaMini.ttf",
			glyphs = "ABCDEFGHIJKLMNÑOPQRSTUVWXYZ _-abcdefghijklmnñopqrstuvwxyz@()áéíóúü¡!¿?{}&$%=+/*«[]|\".,;:º█êëèïîìôöòù1234567890",
      cache = {},
      uppercase = false
		},
		Paleo = {
			data = {},
			font = nil,
			path = "assets/fonts/Paleo.ttf",
			glyphs = "ABCDEFGHIJKLMNÑOPQRSTUVWXYZ _-¡!¿?.,;:\"|áéíóúü()[]êëèïîìô<>█1234567890",
      cache = {},
      uppercase = true
		}
	}

  if not sdlttf.TTF_Init() then
    error("SDL_TTF failed: " .. ffi.string(sdl.SDL_GetError()))
  end

	for name, f in pairs(fonts) do
    
    f.font = sdlttf.TTF_OpenFont(f.path, 8)
    if f.font == nil then
      error("Font failed: " .. ffi.string(sdl.SDL_GetError()))
    end

	end

	return fonts
end

Fonts = SetupFonts()

function CloseFonts()
  for name, f in pairs(Fonts) do
    sdlttf.TTF_CloseFont(f.font);
  end
  sdlttf.TTF_Quit()
end

-- print(TableTree(Fonts))