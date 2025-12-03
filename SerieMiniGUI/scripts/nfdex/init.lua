local ffi = require("ffi")

ffi.cdef[[
  // Types from nfd.h
  typedef unsigned int nfdfiltersize_t;
  typedef struct {
    size_t type;
    void* handle;
  } nfdwindowhandle_t;
  typedef size_t nfdversion_t;
  typedef char nfdu8char_t;

  typedef struct {
    const nfdu8char_t* name;
    const nfdu8char_t* spec;
  } nfdu8filteritem_t;

  typedef struct {
    const nfdu8filteritem_t* filterList;
    nfdfiltersize_t filterCount;
    const nfdu8char_t* defaultPath;
    const nfdu8char_t* defaultName;
    nfdwindowhandle_t parentWindow;
  } nfdsavedialogu8args_t;

  typedef struct {
    const nfdu8filteritem_t* filterList;
    nfdfiltersize_t filterCount;
    const nfdu8char_t* defaultPath;
    nfdwindowhandle_t parentWindow;
  } nfdopendialogu8args_t;

  // Added for PickFolder
  typedef struct {
    const nfdu8char_t* defaultPath;
    nfdwindowhandle_t parentWindow;
  } nfdpickfolderu8args_t;

  typedef enum {
    NFD_ERROR,
    NFD_OKAY,
    NFD_CANCEL
  } nfdresult_t;

  // Function declarations with version parameter (use 1 for NFD_INTERFACE_VERSION)
  nfdresult_t NFD_OpenDialogU8_With_Impl(nfdversion_t version, nfdu8char_t** outPath, const nfdopendialogu8args_t* args);
  nfdresult_t NFD_SaveDialogU8_With_Impl(nfdversion_t version, nfdu8char_t** outPath, const nfdsavedialogu8args_t* args);
  // Added for PickFolder
  nfdresult_t NFD_PickFolderU8_With_Impl(nfdversion_t version, nfdu8char_t** outPath, const nfdpickfolderu8args_t* args);

  void NFD_FreePathU8(nfdu8char_t* filePath);
  const char* NFD_GetError(void);

  int NFD_Init(void);
  void NFD_Quit(void);
]]

local os = jit.os
local libpath

local script_dir = arg[0]:match("^(.*)/") or "."
if ffi.os == "Windows" then -- Windows
  libpath = "./libnfdex.dll"
elseif ffi.os == "OSX" then -- MacOS
  libpath = "libnfdex.dylib"
else -- Linux
  --libpath = script_dir .. "/lib/nfdex/libnfdex.so"
  libpath = "libnfdex.so"
end

local lib = ffi.load(libpath)

local M = {}

function M.Init()
  local initResult = lib.NFD_Init()
  if initResult ~= ffi.C.NFD_OKAY then
    -- Fixed: Use lib.NFD_GetError() instead of undefined nfdex variable
    error("Failed to initialize native file dialog: " .. ffi.string(lib.NFD_GetError()))
  end
end

function M.Shutdown()
  lib.NFD_Quit()
end

-- Helper to convert Lua table { {name="Text", spec="txt"}, ... } to C struct
local function make_filters(filters)
    if not filters or #filters == 0 then return nil, 0, nil end

    -- We need to keep the char arrays alive so they aren't GC'd during the C call
    local anchors = {} 
    local c_filters = ffi.new("nfdu8filteritem_t[?]", #filters)

    for i, item in ipairs(filters) do
        local c_name = ffi.new("char[?]", #item.name + 1, item.name)
        local c_spec = ffi.new("char[?]", #item.spec + 1, item.spec)
        
        table.insert(anchors, c_name)
        table.insert(anchors, c_spec)

        c_filters[i-1].name = c_name
        c_filters[i-1].spec = c_spec
    end

    return c_filters, #filters, anchors
end

function M.Open(defaultPath, filters)
    local c_filters, count, anchors = make_filters(filters)
    
    local args = ffi.new("nfdopendialogu8args_t")
    args.filterList = c_filters
    args.filterCount = count
    args.defaultPath = defaultPath
    args.parentWindow = {0, nil} -- Use 0 for default native parent

    local outPath = ffi.new("nfdu8char_t*[1]")
    
    -- Call NFD (Blocks execution)
    local result = lib.NFD_OpenDialogU8_With_Impl(1, outPath, args)

    if result == ffi.C.NFD_OKAY then
        local str = ffi.string(outPath[0])
        lib.NFD_FreePathU8(outPath[0])
        return str
    elseif result == ffi.C.NFD_CANCEL then
        return nil
    else
        print("NFD Error: " .. ffi.string(lib.NFD_GetError()))
        return nil
    end
end

function M.Save(defaultPath, defaultName, filters)
    local c_filters, count, anchors = make_filters(filters)
    
    local args = ffi.new("nfdsavedialogu8args_t")
    args.filterList = c_filters
    args.filterCount = count
    args.defaultPath = defaultPath
    args.defaultName = defaultName
    args.parentWindow = {0, nil}

    local outPath = ffi.new("nfdu8char_t*[1]")
    
    local result = lib.NFD_SaveDialogU8_With_Impl(1, outPath, args)

    if result == ffi.C.NFD_OKAY then
        local str = ffi.string(outPath[0])
        lib.NFD_FreePathU8(outPath[0])
        return str
    elseif result == ffi.C.NFD_CANCEL then
        return nil
    else
        print("NFD Error: " .. ffi.string(lib.NFD_GetError()))
        return nil
    end
end

function M.pickFolder(defaultPath)
    local args = ffi.new("nfdpickfolderu8args_t")
    args.defaultPath = defaultPath
    args.parentWindow = {0, nil} 

    local outPath = ffi.new("nfdu8char_t*[1]")
    
    local result = lib.NFD_PickFolderU8_With_Impl(1, outPath, args)

    if result == ffi.C.NFD_OKAY then
        local str = ffi.string(outPath[0])
        lib.NFD_FreePathU8(outPath[0])
        return str
    elseif result == ffi.C.NFD_CANCEL then
        return nil
    else
        print("NFD Error: " .. ffi.string(lib.NFD_GetError()))
        return nil
    end
end

return M