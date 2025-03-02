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
    UIFramework.CreateTextLabel(x + 25, y + 5, title, {255,255,255,255}, 2)
end

function UIFramework.CreateTextLabel(x, y, text, color, type) 
    UIFramework.CreateTextLabel(x, y, text, color, type, ALIGN_LEFT)
end

function UIFramework.CreateTextLabel(x, y, text, color, type, align)
    local fontType = type or 0
    local alignValue = align or ALIGN_LEFT
    
    SetFontType(fontType)
    SetTextColor(color[1], color[2], color[3], color[4])
    RenderText2(x, y, text, alignValue)
end

return UIFramework
