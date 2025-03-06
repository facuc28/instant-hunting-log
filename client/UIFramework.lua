UIFramework = {}

function UIFramework.CreatePanel(x, y, width, height, bgColor, borderColor, title)
    EnableAlphaTest()

    -- Background
    glColor4f(bgColor[1], bgColor[2], bgColor[3], bgColor[4])
    DrawBar(x, y, width, height, 0.0, 0)

    -- Title Bar
    glColor4f(borderColor[1], borderColor[2], borderColor[3], borderColor[4])
    DrawBar(x, y, width, 20, 0.0, 0)

    -- Border
    glColor4f(borderColor[1], borderColor[2], borderColor[3], borderColor[4])
    DrawBar(x - 1, y - 1, width + 2, 1, 0.0, 0)       -- Top Border
    DrawBar(x - 1, y + height, width + 2, 1, 0.0, 0)  -- Bottom Border
    DrawBar(x - 1, y, 1, height, 0.0, 0)              -- Left Border
    DrawBar(x + width, y, 1, height, 0.0, 0)          -- Right Border

    DisableAlphaBlend()
    UIFramework.CreateTextLabel(x + 30, y + 5, title, {255,255,255,255}, 1, ALIGN_CENTER, borderColor)
end

function UIFramework.CreateTextLabel(x, y, text, color, type) 
    UIFramework.CreateTextLabel(x, y, text, color, type, ALIGN_LEFT, nil)
end

function UIFramework.CreateTextLabel(x, y, text, color, type, align)
    UIFramework.CreateTextLabel(x, y, text, color, type, align, nil)
end

function UIFramework.CreateTextLabel(x, y, text, color, type, align, bgcolor)
    local fontType = type or 0
    local alignValue = align or ALIGN_LEFT
    local backgroundColor = bgcolor or {0,0,0,0}
    
    SetFontType(fontType)
    SetTextColor(color[1], color[2], color[3], color[4])
    SetTextBg(backgroundColor[1], backgroundColor[2], backgroundColor[3], backgroundColor[4])
    RenderText2(x, y, text, alignValue)
    
end

return UIFramework
