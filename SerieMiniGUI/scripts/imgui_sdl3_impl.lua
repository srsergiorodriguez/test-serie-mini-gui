local ffi = require("ffi")
local sdl = require("scripts.SDL3")
local imgui = require("scripts.cimgui")

local M = {}

local g_Renderer = nil
local g_Window = nil
local g_FontTexture = nil
local g_Time = 0
local g_DpiScale = 1.0

-- Helper to map SDL mouse buttons to ImGui
local function get_mouse_button_index(sdl_button)
    if sdl_button == 1 then return 0 end -- Left
    if sdl_button == 3 then return 1 end -- Right
    if sdl_button == 2 then return 2 end -- Middle
    return 0
end

function M.Init(renderer, window)
    local C = imgui.C 
    if not C then C = imgui end 

    if imgui.GetCurrentContext() == nil then
        imgui.CreateContext(nil)
    end

    g_Renderer = renderer
    g_Window = window
    local io = imgui.GetIO()

    -- Config
    io.BackendFlags = bit.bor(io.BackendFlags, imgui.ImGuiBackendFlags_HasMouseCursors)
    io.BackendFlags = bit.bor(io.BackendFlags, imgui.ImGuiBackendFlags_RendererHasVtxOffset)

    -- === 1. DETECT SCALE ===
    -- usually 2.0 on Retina, 1.0 on Monitor
    g_DpiScale = sdl.SDL_GetWindowDisplayScale(g_Window)
    if g_DpiScale <= 0 then g_DpiScale = 1.0 end

    -- === 2. LOAD HIGH-RES FONT ===
    -- We load the font BIG so the texture is crisp
    local base_font_size = 18.0
    local font_load_size = base_font_size * g_DpiScale -- e.g. 32px

    local font_config = imgui.ImFontConfig()
    font_config.PixelSnapH = true
    
    -- Load your font
    local newfont = io.Fonts:AddFontFromFileTTF("assets/fonts/RobotoMono-Regular.ttf", font_load_size, font_config)
    
    if newfont == nil then 
        C.ImFontAtlas_AddFontDefault(io.Fonts, nil) 
    else
        io.FontDefault = newfont
    end

    -- === 3. SCALE UI LOGIC DOWN ===
    -- We tell ImGui to draw "small" coordinates (logical), 
    -- even though it is using a "big" font texture.
    io.FontGlobalScale = 1.0 / g_DpiScale

    -- Build Atlas
    local pixels = ffi.new("unsigned char*[1]")
    local width = ffi.new("int[1]")
    local height = ffi.new("int[1]")
    local bytes_per_pixel = ffi.new("int[1]")

    C.ImFontAtlas_GetTexDataAsRGBA32(io.Fonts, pixels, width, height, bytes_per_pixel)

    local format_rgba32 = sdl.SDL_PIXELFORMAT_RGBA32
    g_FontTexture = sdl.SDL_CreateTexture(
        g_Renderer, format_rgba32, sdl.SDL_TEXTUREACCESS_STATIC, width[0], height[0]
    )

    sdl.SDL_UpdateTexture(g_FontTexture, ffi.NULL, pixels[0], width[0] * 4)
    sdl.SDL_SetTextureBlendMode(g_FontTexture, sdl.SDL_BLENDMODE_BLEND)
    io.Fonts.TexID = ffi.cast("uint64_t", ffi.cast("uintptr_t", g_FontTexture))
end

-- Key Maps
local KeyMap = {
    [sdl.SDL_SCANCODE_TAB]       = imgui.ImGuiKey_Tab,
    [sdl.SDL_SCANCODE_LEFT]      = imgui.ImGuiKey_LeftArrow,
    [sdl.SDL_SCANCODE_RIGHT]     = imgui.ImGuiKey_RightArrow,
    [sdl.SDL_SCANCODE_UP]        = imgui.ImGuiKey_UpArrow,
    [sdl.SDL_SCANCODE_DOWN]      = imgui.ImGuiKey_DownArrow,
    [sdl.SDL_SCANCODE_PAGEUP]    = imgui.ImGuiKey_PageUp,
    [sdl.SDL_SCANCODE_PAGEDOWN]  = imgui.ImGuiKey_PageDown,
    [sdl.SDL_SCANCODE_HOME]      = imgui.ImGuiKey_Home,
    [sdl.SDL_SCANCODE_END]       = imgui.ImGuiKey_End,
    [sdl.SDL_SCANCODE_INSERT]    = imgui.ImGuiKey_Insert,
    [sdl.SDL_SCANCODE_DELETE]    = imgui.ImGuiKey_Delete,
    [sdl.SDL_SCANCODE_BACKSPACE] = imgui.ImGuiKey_Backspace,
    [sdl.SDL_SCANCODE_SPACE]     = imgui.ImGuiKey_Space,
    [sdl.SDL_SCANCODE_RETURN]    = imgui.ImGuiKey_Enter,
    [sdl.SDL_SCANCODE_ESCAPE]    = imgui.ImGuiKey_Escape,
    [sdl.SDL_SCANCODE_LCTRL]     = imgui.ImGuiKey_LeftCtrl,
    [sdl.SDL_SCANCODE_LSHIFT]    = imgui.ImGuiKey_LeftShift,
    [sdl.SDL_SCANCODE_LALT]      = imgui.ImGuiKey_LeftAlt,
    [sdl.SDL_SCANCODE_LGUI]      = imgui.ImGuiKey_LeftSuper,
    [sdl.SDL_SCANCODE_RCTRL]     = imgui.ImGuiKey_RightCtrl,
    [sdl.SDL_SCANCODE_RSHIFT]    = imgui.ImGuiKey_RightShift,
    [sdl.SDL_SCANCODE_RALT]      = imgui.ImGuiKey_RightAlt,
    [sdl.SDL_SCANCODE_RGUI]      = imgui.ImGuiKey_RightSuper,
}
for i = 0, 9 do KeyMap[sdl.SDL_SCANCODE_1 + i - 1] = imgui.ImGuiKey_1 + i end
KeyMap[sdl.SDL_SCANCODE_0] = imgui.ImGuiKey_0
for i = 0, 25 do KeyMap[sdl.SDL_SCANCODE_A + i] = imgui.ImGuiKey_A + i end

local function UpdateKeyModifiers(io)
    local mod_state = sdl.SDL_GetModState()
    io:AddKeyEvent(imgui.ImGuiMod_Ctrl,  bit.band(mod_state, sdl.SDL_KMOD_CTRL) ~= 0)
    io:AddKeyEvent(imgui.ImGuiMod_Shift, bit.band(mod_state, sdl.SDL_KMOD_SHIFT) ~= 0)
    io:AddKeyEvent(imgui.ImGuiMod_Alt,   bit.band(mod_state, sdl.SDL_KMOD_ALT) ~= 0)
    io:AddKeyEvent(imgui.ImGuiMod_Super, bit.band(mod_state, sdl.SDL_KMOD_GUI) ~= 0)
end

function M.ProcessEvent(event)
    local io = imgui.GetIO()
    local type = event.type

    -- SDL3 sends Logical coordinates by default when HighDPI is enabled.
    -- We pass them directly to ImGui (since ImGui is also running in Logical coords).
    
    if type == sdl.SDL_EVENT_MOUSE_MOTION then
        local ev = ffi.cast("SDL_MouseMotionEvent*", event)
        io:AddMousePosEvent(ev.x, ev.y)
        return true

    elseif type == sdl.SDL_EVENT_MOUSE_BUTTON_DOWN or type == sdl.SDL_EVENT_MOUSE_BUTTON_UP then
        local ev = ffi.cast("SDL_MouseButtonEvent*", event)
        local btn_idx = get_mouse_button_index(ev.button)
        io:AddMouseButtonEvent(btn_idx, type == sdl.SDL_EVENT_MOUSE_BUTTON_DOWN)
        return true

    elseif type == sdl.SDL_EVENT_MOUSE_WHEEL then
        local ev = ffi.cast("SDL_MouseWheelEvent*", event)
        io:AddMouseWheelEvent(ev.x, ev.y)
        return true

    elseif type == sdl.SDL_EVENT_KEY_DOWN or type == sdl.SDL_EVENT_KEY_UP then
        local ev = ffi.cast("SDL_KeyboardEvent*", event)
        UpdateKeyModifiers(io)
        local scancode_num = tonumber(ev.scancode)
        local imgui_key = KeyMap[scancode_num]
        if imgui_key then
            io:AddKeyEvent(imgui_key, type == sdl.SDL_EVENT_KEY_DOWN)
        end
        return true

    elseif type == sdl.SDL_EVENT_TEXT_INPUT then
        local ev = ffi.cast("SDL_TextInputEvent*", event)
        io:AddInputCharactersUTF8(ev.text)
        return true
    end
    
    return false
end

function M.NewFrame()
    local io = imgui.GetIO()

    -- 1. Get LOGICAL Window Size (Points, not Pixels)
    -- This ensures the UI fills the window correctly.
    local w_log, h_log = ffi.new("int[1]"), ffi.new("int[1]")
    sdl.SDL_GetWindowSize(g_Window, w_log, h_log)
    
    io.DisplaySize.x = w_log[0]
    io.DisplaySize.y = h_log[0]

    -- 2. No Framebuffer Scale
    -- We are handling the resolution via the Texture/Font scaling, not the coordinate scaling.
    io.DisplayFramebufferScale.x = 1.0
    io.DisplayFramebufferScale.y = 1.0

    -- 3. Delta Time
    local current_time = sdl.SDL_GetTicks()
    local dt = (current_time - g_Time) / 1000.0
    if dt <= 0 then dt = 1.0/60.0 end
    io.DeltaTime = dt
    g_Time = current_time

    imgui.NewFrame()
end

-- Buffers for Rendering (Keep these at module level)
local g_ColorBuffer = nil
local g_ColorBufferSize = 0

function M.Render()
    imgui.Render()
    local draw_data = imgui.GetDrawData()

    if draw_data.DisplaySize.x <= 0 or draw_data.DisplaySize.y <= 0 then return end

    -- 1. Calculate and Set Scale
    local w_log, h_log = ffi.new("int[1]"), ffi.new("int[1]")
    local w_phy, h_phy = ffi.new("int[1]"), ffi.new("int[1]")
    
    sdl.SDL_GetWindowSize(g_Window, w_log, h_log)
    sdl.SDL_GetRenderOutputSize(g_Renderer, w_phy, h_phy)

    local scale_x = 1.0
    local scale_y = 1.0
    
    if w_log[0] > 0 and h_log[0] > 0 then
        scale_x = w_phy[0] / w_log[0]
        scale_y = h_phy[0] / h_log[0]
    end

    local old_scale_x, old_scale_y = ffi.new("float[1]"), ffi.new("float[1]")
    sdl.SDL_GetRenderScale(g_Renderer, old_scale_x, old_scale_y)

    -- Apply global scale (Affects both Geometry AND ClipRects)
    sdl.SDL_SetRenderScale(g_Renderer, scale_x, scale_y)

    for n = 0, tonumber(draw_data.CmdListsCount) - 1 do
        local cmd_list = draw_data.CmdLists.Data[n]
        local vtx_buffer = cmd_list.VtxBuffer.Data
        local idx_buffer = cmd_list.IdxBuffer.Data
        local total_vtx_count = cmd_list.VtxBuffer.Size

        -- Resize buffer if needed
        if total_vtx_count > g_ColorBufferSize then
            g_ColorBufferSize = total_vtx_count + 5000 
            g_ColorBuffer = ffi.new("SDL_FColor[?]", g_ColorBufferSize)
        end

        -- Convert Colors
        for i = 0, tonumber(total_vtx_count) - 1 do
            local col = vtx_buffer[i].col
            local dest = g_ColorBuffer[i]
            dest.r = bit.band(col, 0xFF) / 255.0
            dest.g = bit.band(bit.rshift(col, 8), 0xFF) / 255.0
            dest.b = bit.band(bit.rshift(col, 16), 0xFF) / 255.0
            dest.a = bit.band(bit.rshift(col, 24), 0xFF) / 255.0
        end

        for cmd_i = 0, tonumber(cmd_list.CmdBuffer.Size) - 1 do
            local pcmd = cmd_list.CmdBuffer.Data[cmd_i]
            if pcmd.UserCallback == nil then
                local clip_rect = pcmd.ClipRect
                
                -- === FIX IS HERE ===
                -- Pass Logical Coordinates directly. 
                -- SDL_SetRenderScale will handle the multiplication for us.
                local rect = ffi.new("SDL_Rect", {
                    x = math.floor(clip_rect.x),
                    y = math.floor(clip_rect.y),
                    w = math.floor(clip_rect.z - clip_rect.x),
                    h = math.floor(clip_rect.w - clip_rect.y)
                })
                -- ===================

                sdl.SDL_SetRenderClipRect(g_Renderer, rect)

                local tex_id = ffi.cast("uintptr_t", pcmd.TextureId)
                local texture = ffi.cast("SDL_Texture*", ffi.cast("void*", tex_id))
                local vtx_offset_ptr = vtx_buffer + pcmd.VtxOffset
                local col_offset_ptr = g_ColorBuffer + pcmd.VtxOffset
                local idx_offset_ptr = idx_buffer + pcmd.IdxOffset

                sdl.SDL_RenderGeometryRaw(
                    g_Renderer, texture,
                    ffi.cast("float*", vtx_offset_ptr), ffi.sizeof("ImDrawVert"),
                    col_offset_ptr, ffi.sizeof("SDL_FColor"),
                    ffi.cast("float*", ffi.cast("char*", vtx_offset_ptr) + 8), ffi.sizeof("ImDrawVert"),
                    tonumber(cmd_list.VtxBuffer.Size) - tonumber(pcmd.VtxOffset),
                    idx_offset_ptr, tonumber(pcmd.ElemCount), ffi.sizeof("ImDrawIdx")
                )
            end
        end
    end
    
    sdl.SDL_SetRenderClipRect(g_Renderer, ffi.NULL)
    sdl.SDL_SetRenderScale(g_Renderer, old_scale_x[0], old_scale_y[0])
end

function M.Shutdown()
    if g_FontTexture ~= nil then
        sdl.SDL_DestroyTexture(g_FontTexture)
        g_FontTexture = nil
    end
    imgui.DestroyContext(nil)
end

return M