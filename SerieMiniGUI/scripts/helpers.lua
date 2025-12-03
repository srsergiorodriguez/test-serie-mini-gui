local utf8 = require 'scripts.luaLibs.utf8'
local sdl = require("scripts.SDL3")

function getWindowSize()
  -- Get scale of virtual window
  local win_w_ptr = ffi.new("int[1]")
  local win_h_ptr = ffi.new("int[1]")
  sdl.SDL_GetWindowSize(win, win_w_ptr, win_h_ptr)
  local win_w, win_h = win_w_ptr[0], win_h_ptr[0]
  return win_w, win_h
end

function getTicks()
  return tonumber(tostring(sdl.SDL_GetTicks()):match("%d+")) or 0
end

function TableTree(table)
	--Get a string representing the tree structure of a table
	local level = 0
	local tree = ""

	if type(table) ~= "table" then
		return tostring(table)
	end
	
	local function recTree(table, level)
		local tabs = ""
		for i=1,level do tabs = tabs.."	" end	
		
		for k,v in pairs(table) do
			if type(v) == "table" then
				tree = tree..tabs.."<"..k..">\n"
				recTree(v, level + 1)
			else
				tree = tree..tabs.."["..k.."]: "..tostring(v).."\n"
			end
		end
	end
	
	recTree(table, level)
	return tree
end

-- function utf8sub(s, i, j)
-- 	local _j = j and j or #s
--   local startByte = utf8.offset(s, i)
--   local endByte = utf8.offset(s, _j + 1)
--   if startByte then
--     if endByte then
--       return s:sub(startByte, endByte - 1)
--     else
--       return s:sub(startByte)
--     end
--   end
--   return ""
-- end

-- function utf8split(s, sep)
--   -- Escape any magic characters in the separator
--   sep = sep:gsub("([^%w])", "%%%1")
--   local t = {}
--   local pattern = "(.-)" .. sep
--   local last_end = 1
--   local s_len = #s
--   while true do
--     local i, j, cap = s:find(pattern, last_end)
--     if not i then break end
--     table.insert(t, cap)
--     last_end = j + 1
--   end
--   if last_end <= s_len then
--     table.insert(t, s:sub(last_end))
--   end
--   return t
-- end

-- function Middle(a, b, c)
--   if (a <= b and b <= c) or (c <= b and b <= a) then
--     return b
--   elseif (b <= a and a <= c) or (c <= a and a <= b) then
--     return a
--   else
--     return c
--   end
-- end

-- function DebugMsg(v, n)
-- 	if n == nil then
-- 		Debug = TableTree(v)
-- 	else
-- 		Debug2 = TableTree(v)
-- 	end
-- end