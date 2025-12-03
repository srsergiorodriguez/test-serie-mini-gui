local ffi = require("ffi")

ffi.cdef[[
  typedef struct _TTF_Font TTF_Font;

  int TTF_Init(void);
  int TTF_WasInit(void);
  void TTF_Quit(void);

  TTF_Font* TTF_OpenFont(const char *file, float ptsize);
  void TTF_CloseFont(TTF_Font *font);

  SDL_Surface * TTF_RenderText_Solid(TTF_Font *font, const char *text, size_t length, SDL_Color fg);
  SDL_Surface * TTF_RenderText_Solid_Wrapped(TTF_Font *font, const char *text, size_t length, SDL_Color fg, int wrapLength);

  bool TTF_GetStringSize(TTF_Font *font, const char *text, size_t length, int *w, int *h);
]]

local libpath
local script_dir = arg[0]:match("^(.*)/") or "."
if ffi.os == "Windows" then -- Windows
  libpath = "./SDL3_ttf.dll"
elseif ffi.os == "OSX" then -- MacOS
  libpath = "libSDL3_ttf.dylib"
else -- Linux
  -- libpath = script_dir .. "/lib/SDL3_TTF/libSDL3_ttf.so"
  libpath = "libSDL3_ttf.so"
end

local lib = ffi.load(libpath)

return lib
