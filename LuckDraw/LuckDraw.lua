local LuckFrameRecive = CreateFrame('frame')
local _G = getfenv(0)
local chestData = {}
local chestCount = {}
local canStartSingleRoll = true
local canStartTenRoll = true
local fontTitle = "Interface\\AddOns\\LuckDraw\\UI\\ZYHei.TTF"
local fonttext = "Interface\\AddOns\\LuckDraw\\UI\\ZYKai_T.TTF"

local defaultX = -126
local defaultY = 130
local spacing = 50
local iconLocation = {
    {x = defaultX + spacing * 0, y = defaultY - spacing * 0},
    {x = defaultX + spacing * 0, y = defaultY - spacing * 1},
    {x = defaultX + spacing * 0, y = defaultY - spacing * 2},
    {x = defaultX + spacing * 0, y = defaultY - spacing * 3},
    {x = defaultX + spacing * 0, y = defaultY - spacing * 4},
    {x = defaultX + spacing * 0, y = defaultY - spacing * 5},
    {x = defaultX + spacing * 1, y = defaultY - spacing * 5},
    {x = defaultX + spacing * 2, y = defaultY - spacing * 5},
    {x = defaultX + spacing * 3, y = defaultY - spacing * 5},
    {x = defaultX + spacing * 4, y = defaultY - spacing * 5},
    {x = defaultX + spacing * 5, y = defaultY - spacing * 5},
    {x = defaultX + spacing * 5, y = defaultY - spacing * 4},
    {x = defaultX + spacing * 5, y = defaultY - spacing * 3},
    {x = defaultX + spacing * 5, y = defaultY - spacing * 2},
    {x = defaultX + spacing * 5, y = defaultY - spacing * 1},
    {x = defaultX + spacing * 5, y = defaultY - spacing * 0},
    {x = defaultX + spacing * 4, y = defaultY - spacing * 0},
    {x = defaultX + spacing * 3, y = defaultY - spacing * 0},
    {x = defaultX + spacing * 2, y = defaultY - spacing * 0},
    {x = defaultX + spacing * 1, y = defaultY - spacing * 0},
}

function SendPacket( opcode, msg )
	--DEFAULT_CHAT_FRAME:AddMessage(opcode.."="..msg)
	SendAddonMessage(opcode, msg, "GUILD")
end

local LuckbuttonIcon = {}
local LuckButtonIconCount = {}
function InitChestData()
    for i=1,20 do
        if LuckbuttonIcon[i] ~= nil and LuckbuttonIcon[i]:IsShown() then
            LuckbuttonIcon[i]:Hide()
            LuckButtonIconCount[i]:Hide()
            LuckbuttonIcon[i] = nil
            LuckButtonIconCount[i] = nil
        end
        LuckbuttonIcon[i] = CreateFrame("Button", "LuckbuttonIcon"..i, LuckFrame, nil)
        LuckbuttonIcon[i]:SetID(i)
		LuckbuttonIcon[i]:SetWidth(48)
		LuckbuttonIcon[i]:SetHeight(48)
        LuckbuttonIcon[i]:SetPoint("CENTER", iconLocation[i].x, iconLocation[i].y)
        LuckbuttonIcon[i]:EnableMouse(true)
        LuckbuttonIcon[i]:UnlockHighlight()
        LuckbuttonIcon[i]:SetHighlightTexture("Interface\\BUTTONS\\OldButtonHilight-Square")
        LuckbuttonIcon[i]:SetBackdrop( { bgFile = GetItemIcon(chestData[i]), })
        LuckbuttonIcon[i]:SetScript("OnEnter", 
            function(self)
                GameTooltip:SetOwner(this, "ANCHOR_LEFT")
                GameTooltip:SetHyperlink(GetLink(chestData[this:GetID()]))
                GameTooltip:Show()
            end
        )
        LuckbuttonIcon[i]:SetScript("OnLeave", 
            function(self)
                GameTooltip:Hide()
            end
        )
        LuckButtonIconCount[i] = LuckbuttonIcon[i]:CreateFontString("LuckButtonIconCount"..i, "ARTWORK", "GameFontNormal")
        LuckButtonIconCount[i]:SetFont(fontTitle, 15, "OUTLINE")
        LuckButtonIconCount[i]:SetShadowOffset(1, -1)
        LuckButtonIconCount[i]:SetPoint("BOTTOMRIGHT", LuckbuttonIcon[i], "BOTTOMRIGHT",-5,5)
        LuckButtonIconCount[i]:SetText("|cff00ff00"..chestCount[i].."|r")
        LuckButtonIconCount[i]:Show()
    end
end

local singleRollEnd = false
local RewardItem = nil
local RewardItemLink = ""
local TenRewardItems = {}
local TenRewardItemLinks = {}

local LuckFrame = CreateFrame("Frame", "LuckFrame", UIParent)
LuckFrame:SetWidth(400)
LuckFrame:SetHeight(550)
LuckFrame:RegisterForDrag("LeftButton")
LuckFrame:SetPoint("CENTER", UIParent)
LuckFrame:SetToplevel(true)
LuckFrame:SetClampedToScreen(true)
LuckFrame:SetMovable(true)
LuckFrame:EnableMouse(true)
LuckFrame:SetScript("OnDragStart", function(self) LuckFrame:StartMoving() end)
LuckFrame:SetScript("OnHide", function(self) LuckFrame:StopMovingOrSizing() end)
LuckFrame:SetScript("OnDragStop", function(self) LuckFrame:StopMovingOrSizing() end)
LuckFrame:SetBackdrop(
    {
        bgFile = "Interface\\AddOns\\LuckDraw\\UI\\UI-DialogBox-BackgroundLuck",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 20,
        insets = { left = 5, right = 5, top = 5, bottom = 5 }
    }
)
tinsert(UISpecialFrames, "LuckFrame")
LuckFrame:Hide()

function StrSplit(str, delimiter)
	local result = {}
    local from = 1
    local delim_from, delim_to = string.find(str, delimiter, from, 1, true)
    while delim_from do
        table.insert(result, string.sub(str, from, delim_from - 1))
        from = delim_to + 1
        delim_from, delim_to = string.find(str, delimiter, from, true)
    end
    table.insert(result, string.sub(str, from))
    return result
end

LuckFrameRecive:RegisterEvent("CHAT_MSG_ADDON")
--服务器插件数据到达处理
LuckFrameRecive:SetScript("OnEvent", function()
    if event then
        local opcode = arg1
        local message = arg2
        if event == 'CHAT_MSG_ADDON' and opcode == "GC_LUCKDRAW_SYSTEM" then
            local msgArray = StrSplit(message, "#")
            if msgArray then
                local opcode = msgArray[1]
                table.remove(msgArray, 1)
                LuckHandler(opcode, msgArray)
            end
        end
    end
end)

function LuckFrame_OnMouseUp(self)
    if (self:IsShown()) then
        self:Hide()
    else
        self:Show()
    end
end

function LuckHandler(opcode, msg)
    if (opcode == "RecieveInfo") then
        local data = {}
        for i = 1,20 do
            table.insert(data,msg[i])
        end
        local reqData = {
            item = tonumber(msg[21]),
            count = tonumber(msg[22]),
            nowCount = tonumber(msg[23]),
            item10 = tonumber(msg[24]),
            count10 = tonumber(msg[25]),
            nowCount10 = tonumber(msg[26])
        }
        RecieveInfo(data,reqData)
        LuckFrame:Show()
    elseif (opcode == "StartSingleRoll") then
        StartSingleRoll(tonumber(msg[1]))
    elseif (opcode == "StartTenRoll") then
		local Tendata = {}
        for i = 1,10 do
            table.insert(Tendata,msg[i])
        end
        StartTenRoll(Tendata)
    end
end

local LuckEntryButton = CreateFrame("Button", "LuckEntryButton", UIParent)
LuckEntryButton:SetWidth(38)
LuckEntryButton:SetHeight(38)
LuckEntryButton:SetPoint("TOPLEFT","PlayerFrame","TOPRIGHT",-50,-80)
LuckEntryButton:SetMovable(true)
LuckEntryButton:EnableMouse(true)
LuckEntryButton:RegisterForDrag("LeftButton")
--LuckEntryButton:SetPushedTexture("Interface\\BUTTONS\\UI-Quickslot-Depress")
LuckEntryButton:SetBackdrop({bgFile = "Interface\\AddOns\\LuckDraw\\UI\\yellowgem"})
LuckEntryButton:SetScript("OnDragStart", function(self) LuckEntryButton:StartMoving() end)
LuckEntryButton:SetScript("OnDragStop", function(self) LuckEntryButton:StopMovingOrSizing() end)
LuckEntryButton:SetScript("OnMouseUp", function(self)
    if (LuckFrame:IsShown()) then
       LuckFrame:Hide()
    else
       --LuckFrame:Show()
       SendPacket("GC_LUCKDRAW_SYSTEM", "RequestData")
    end
end)

local LuckEntryBtnText = LuckEntryButton:CreateFontString("LuckEntryBtnText", "ARTWORK", "GameFontNormal")
LuckEntryBtnText:SetFont(fontTitle, 11, "OUTLINE")
LuckEntryBtnText:SetShadowOffset(1, -1)
LuckEntryBtnText:SetPoint("CENTER", 1, -30)
LuckEntryBtnText:SetText("|cFFFFC125命运轮盘|r")
LuckEntryButton:Show()

-- 关闭按钮
local LuckbuttonClose = CreateFrame("Button", "LuckbuttonClose", LuckFrame, "UIPanelCloseButton")
LuckbuttonClose:SetPoint("TOPRIGHT", 0, 0)
LuckbuttonClose:EnableMouse(true)
LuckbuttonClose:SetWidth(36)
LuckbuttonClose:SetHeight(36)

-- 标题模块
local LuckTitleBar = CreateFrame("Frame", "LuckTitleBar", LuckFrame, nil)
LuckTitleBar:SetWidth(255)
LuckTitleBar:SetHeight(50)
LuckTitleBar:SetPoint("CENTER", 0, 270)
LuckTitleBar:SetBackdrop(
    {
        bgFile = "Interface\\AddOns\\LuckDraw\\UI\\UI-DialogBox-BackgroundLuck",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        edgeSize = 16,
        tileSize = 16,
        insets = { left = 5, right = 5, top = 5, bottom = 5 }
    }
)

--标题模块文字描述
local LuckTitleText = LuckTitleBar:CreateFontString("LuckTitleText", "OVERLAY", "GameFontNormalHuge")
LuckTitleText:SetFont(fontTitle, 48)
LuckTitleText:SetWidth(300)
LuckTitleText:SetHeight(10)
LuckTitleText:SetPoint("CENTER", 0, 0)
LuckTitleText:SetText("|cFFFFC125幸运大转盘|r")

local LuckbuttonCenter = CreateFrame("Button", "LuckbuttonCenter", LuckFrame)
LuckbuttonCenter:SetWidth(80)
LuckbuttonCenter:SetHeight(80)
LuckbuttonCenter:SetPoint("CENTER", LuckFrame, "CENTER")
LuckbuttonCenter:EnableMouse(true)
LuckbuttonCenter:SetBackdrop( { bgFile = "Interface\\BUTTONS\\UI-EmptySlot", })
LuckbuttonCenterCount = LuckbuttonCenter:CreateFontString("LuckbuttonCenterCount", "ARTWORK", "GameFontNormal")
LuckbuttonCenterCount:SetFont(fontTitle, 25, "OUTLINE")
LuckbuttonCenterCount:SetShadowOffset(1, -1)
LuckbuttonCenterCount:SetPoint("BOTTOMRIGHT", LuckbuttonCenter, "BOTTOMRIGHT",-10,10)
LuckbuttonCenterCount:SetText("")
LuckbuttonCenterCount:Hide()

local centerItemLink = LuckbuttonCenter:CreateFontString("centerItemLink", "ARTWORK", "GameFontNormal")
centerItemLink:SetFont(fonttext, 18, "OUTLINE")
centerItemLink:SetShadowOffset(1, -1)
centerItemLink:SetWidth(200)
centerItemLink:SetHeight(20)
centerItemLink:SetPoint("CENTER", 0, -68)

local tenButtonCenter = {}
-- 画中间十连抽文字
local TenRewardFrame = CreateFrame("Frame", "TenRewardFrame", LuckFrame)
TenRewardFrame:SetWidth(340)
TenRewardFrame:SetHeight(350)
TenRewardFrame:SetPoint("CENTER", 0, 0)
TenRewardFrame:SetToplevel(true)
TenRewardFrame:SetClampedToScreen(true)
TenRewardFrame:SetBackdrop(
    {
        bgFile = "Interface\\AddOns\\LuckDraw\\UI\\UI-Party-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        edgeSize = 16,
        tileSize = 16,
        insets = { left = 5, right = 5, top = 5, bottom = 5 }
    }
)
TenRewardFrame:Hide()

local tenDefaultX = 0
local tenDefaultY = -30
local tenSpacingX = 100
local tenSpacingY = 80
local tenRewardIconLocation = {
    {x = tenDefaultX - tenSpacingX * 1, y = tenDefaultY + tenSpacingY * 2},
    {x = tenDefaultX + tenSpacingX * 0, y = tenDefaultY + tenSpacingY * 2},
    {x = tenDefaultX + tenSpacingX * 1, y = tenDefaultY + tenSpacingY * 2},
    {x = tenDefaultX - tenSpacingX * 1, y = tenDefaultY + tenSpacingY * 1},
    {x = tenDefaultX + tenSpacingX * 0, y = tenDefaultY + tenSpacingY * 1},
    {x = tenDefaultX + tenSpacingX * 1, y = tenDefaultY + tenSpacingY * 1},
    {x = tenDefaultX - tenSpacingX * 1, y = tenDefaultY + tenSpacingY * 0},
    {x = tenDefaultX + tenSpacingX * 0, y = tenDefaultY + tenSpacingY * 0},
    {x = tenDefaultX + tenSpacingX * 1, y = tenDefaultY + tenSpacingY * 0},
    {x = tenDefaultX + tenSpacingX * 0, y = tenDefaultY - tenSpacingY * 1},
}

local tenRewardIcon = {}
local tenRewardString = {}
local tenRewardLink = {}
local SuperRewardText

function InitTenRewardIcon()
    for i=1,10 do
        if tenRewardIcon[i] == nil then
            tenRewardIcon[i] = CreateFrame("Button", "tenRewardIcon"..i, TenRewardFrame, nil)
			tenRewardIcon[i]:SetWidth(48)
			tenRewardIcon[i]:SetHeight(48)
            tenRewardIcon[i]:SetPoint("CENTER", tenRewardIconLocation[i].x, tenRewardIconLocation[i].y)
            tenRewardIcon[i]:EnableMouse(true)
            tenRewardIcon[i]:UnlockHighlight()
            tenRewardIcon[i]:SetHighlightTexture("")

            tenRewardString[i] = tenRewardIcon[i]:CreateFontString("tenRewardString"..i, "ARTWORK", "GameFontNormal")
            tenRewardString[i]:SetFont(fonttext, 12)
            tenRewardString[i]:SetAllPoints(tenRewardIcon[i])
            tenRewardIcon[i]:SetFontString(tenRewardString[i])
            tenRewardIcon[i]:SetText("")
            tenRewardIcon[i]:SetBackdrop( { bgFile = "", })

            tenRewardLink[i] = tenRewardIcon[i]:CreateFontString("tenRewardLink"..i, "ARTWORK", "GameFontNormal")
            tenRewardLink[i]:SetFont(fonttext, 13, "OUTLINE")
            tenRewardLink[i]:SetShadowOffset(1, -1)
			tenRewardLink[i]:SetWidth(200)
			tenRewardLink[i]:SetHeight(20)
            tenRewardLink[i]:SetPoint("CENTER", 0, -30)
            tenRewardLink[i]:SetText("")
            if i == 10 then
                SuperRewardText = tenRewardIcon[i]:CreateFontString("SuperRewardText", "ARTWORK", "GameFontNormal")
                SuperRewardText:SetFont(fonttext, 18, "OUTLINE")
                SuperRewardText:SetShadowOffset(1, -1)
                SuperRewardText:SetWidth(150)
			    SuperRewardText:SetHeight(20)
                SuperRewardText:SetPoint("CENTER", -80, 0)
                SuperRewardText:SetText("")
                SuperRewardText:Hide()
            end
        else
            tenRewardIcon[i]:SetText("")
            tenRewardLink[i]:SetText("")
            tenRewardIcon[i]:SetHighlightTexture("")
            tenRewardIcon[i]:UnregisterAllEvents()
            tenRewardIcon[i]:SetScript("OnEnter", nil)
            tenRewardIcon[i]:SetScript("OnLeave", nil)
            tenRewardIcon[i]:SetBackdrop( { bgFile = "", })
            SuperRewardText:Hide()
        end
    end
end
function DrawTenRewardIcon(i,id,itemLink)
    id = tonumber(id)
    tenRewardIcon[i]:SetBackdrop( { bgFile = GetItemIcon(chestData[id]), }) -- 设十连抽图标
    tenRewardLink[i]:SetText(itemLink)
    tenRewardIcon[i]:SetHighlightTexture("Interface\\BUTTONS\\OldButtonHilight-Square")
    tenRewardIcon[i]:SetScript("OnEnter", 
        function(self)
            GameTooltip:SetOwner(tenRewardIcon[i], "ANCHOR_LEFT")
            GameTooltip:SetHyperlink(GetLink(chestData[id]))
            GameTooltip:Show()
        end
    )
    tenRewardIcon[i]:SetScript("OnLeave", 
        function(self)
            GameTooltip:Hide()
        end
    )
    SendPacket("GC_LUCKDRAW_SYSTEM", "RequestSendTenRollReward "..i)
    if i == 10 then
        SuperRewardText:Show()
        tenRewardIcon[i]:SetWidth(48)
		tenRewardIcon[i]:SetHeight(48)
    end
end

local LuckFontTest = LuckbuttonCenter:CreateFontString("LuckFontTest", "ARTWORK", "GameFontNormal")
LuckFontTest:SetFont(fonttext, 8)
LuckFontTest:SetAllPoints(LuckbuttonCenter)
LuckbuttonCenter:SetFontString(LuckFontTest)

LuckbuttonCenter:SetScript("OnEnter",
    function(self)
        if (singleRollEnd == true) then
            -- 如果单抽结束，中间有奖品，那么中间可以显示tooltip
            GameTooltip:SetOwner(LuckbuttonCenter, "ANCHOR_RIGHT")
                GameTooltip:SetHyperlink(GetLink(chestData[RewardItem]))
                GameTooltip:Show()
          end
    end
)

LuckbuttonCenter:SetScript("OnLeave",
    function(self)
        GameTooltip:Hide()
    end
)

local infoString = LuckFrame:CreateFontString("infoString", "ARTWORK", "GameFontNormal")
infoString:SetFont(fonttext, 16)
infoString:SetWidth(400)
infoString:SetHeight(100)
infoString:SetPoint("CENTER", 0, -190)
infoString:SetText("|cFFFFC125奖品直接发放到背包，务必确保背包空间充足！|r")

local infoString2 = LuckFrame:CreateFontString("infoString2", "ARTWORK", "GameFontNormalLarge")
infoString2:SetFont(fonttext, 18)
infoString2:SetWidth(400)
infoString2:SetHeight(50)
infoString2:SetPoint("CENTER", 0, 200)
infoString2:SetText("|cFFFFC125极品装备 炫酷宝物 稀有材料\n人品爆发 即刻拥有|r")

local singleRollBeganString = LuckFrame:CreateFontString("singleRollBeganString", "ARTWORK", "GameFontNormal")
singleRollBeganString:SetFont(fonttext, 18)
singleRollBeganString:SetWidth(400)
singleRollBeganString:SetHeight(100)
singleRollBeganString:SetPoint("CENTER", -100, -230)
singleRollBeganString:SetText("|cFFFFC125正在单抽...|r")
singleRollBeganString:Hide()

local tenRollBeganString = LuckFrame:CreateFontString("tenRollBeganString", "ARTWORK", "GameFontNormal")
tenRollBeganString:SetFont(fonttext, 18)
tenRollBeganString:SetWidth(400)
tenRollBeganString:SetHeight(100)
tenRollBeganString:SetPoint("CENTER", 100, -230)
tenRollBeganString:SetText("|cFFFFC125正在连抽...|r")
tenRollBeganString:Hide()

local gainedRewardsString = LuckFrame:CreateFontString("gainedRewardsString", "ARTWORK", "GameFontNormal")
gainedRewardsString:SetFont(fonttext, 15)
gainedRewardsString:SetWidth(400)
gainedRewardsString:SetHeight(100)
gainedRewardsString:SetPoint("CENTER", 0, -165)
gainedRewardsString:SetText("|cFFFF66FF您的奖品已发放完毕|r")
gainedRewardsString:Hide()

--单抽按钮
local SingleRollBtn = CreateFrame("Button", "SingleRollBtn", LuckFrame, nil)
SingleRollBtn:SetWidth(150)
SingleRollBtn:SetHeight(50)
SingleRollBtn:SetPoint("CENTER", -70, -230)
SingleRollBtn:EnableMouse(true)
SingleRollBtn:SetNormalTexture("Interface\\BUTTONS\\UI-Panel-Button-Up")
SingleRollBtn:SetHighlightTexture("Interface\\BUTTONS\\UI-Panel-Button-Highlight")
SingleRollBtn:SetPushedTexture("Interface\\BUTTONS\\UI-Panel-Button-Disabled")
SingleRollBtn:SetScript("OnClick",
    function(self)
        SendPacket("GC_LUCKDRAW_SYSTEM", "RequestSingleRoll")
    end
)

local SingleRollBtnText = SingleRollBtn:CreateFontString("SingleRollBtnText", "ARTWORK", "GameFontNormalLarge")
SingleRollBtnText:SetFont(fonttext, 18)
SingleRollBtnText:SetPoint("TOPLEFT",  30, -9)
SingleRollBtn:SetFontString(SingleRollBtnText)
SingleRollBtn:SetText("抽一次")

local SingleRollReqText = SingleRollBtn:CreateFontString("SingleRollReqText", "ARTWORK", "GameFontNormal")
SingleRollReqText:SetFont(fonttext, 14)
SingleRollReqText:SetWidth(200)
SingleRollReqText:SetHeight(20)
SingleRollReqText:SetPoint("CENTER", -28, -19)

--十连抽
local TenRollBtn = CreateFrame("Button", "TenRollBtn", LuckFrame, nil)
TenRollBtn:SetWidth(150)
TenRollBtn:SetHeight(50)
TenRollBtn:SetPoint("CENTER", 120, -230)
TenRollBtn:EnableMouse(true)
TenRollBtn:SetNormalTexture("Interface\\BUTTONS\\UI-Panel-Button-Up")
TenRollBtn:SetHighlightTexture("Interface\\BUTTONS\\UI-Panel-Button-Highlight")
TenRollBtn:SetPushedTexture("Interface\\BUTTONS\\UI-Panel-Button-Disabled")

TenRollBtn:SetScript("OnClick",
    function(self)
        --if (canStartTenRoll == false) then SendPacket("GC_LUCKDRAW_SYSTEM", "cantTenRollMsg") return end
        SendPacket("GC_LUCKDRAW_SYSTEM", "RequestTenRoll")
    end
)

local TenRollBtnText = TenRollBtn:CreateFontString("TenRollBtnText", "ARTWORK", "GameFontNormalLarge")
TenRollBtnText:SetFont(fonttext, 18)
TenRollBtnText:SetPoint("TOPLEFT", 29, -9)
TenRollBtn:SetFontString(TenRollBtnText)
TenRollBtn:SetText("十连抽")

local TenRollReqText = TenRollBtn:CreateFontString("TenRollReqText", "ARTWORK", "GameFontNormal")
TenRollReqText:SetFont(fonttext, 14)
TenRollReqText:SetWidth(200)
TenRollReqText:SetHeight(20)
TenRollReqText:SetPoint("CENTER", -28, -19)

-- 初始动画不播
local rollAnimationIsPlaying = false
local tenRollAnimationIsPlaying = false
local loop = 1
local loop10 = 1
local animationDelay = 0.05
local animationDelay10 = 1
local now = GetTime()
LuckFrame:SetScript("OnUpdate",
    function(self)
        if rollAnimationIsPlaying == true then
            local totalLoop = 40 + RewardItem
            if loop <= totalLoop then
                if GetTime() >= (now + animationDelay) then
                    if (totalLoop - loop) <= 10 then 
                        animationDelay = (10 - (totalLoop - loop)) * 0.05
                    end
                    local i = math.fmod(loop - 1, 20) + 1
                    LuckbuttonCenter:SetBackdrop( { bgFile = GetItemIcon(chestData[i]), })
                    LuckbuttonCenterCount:SetText("|cff00ff00"..chestCount[i].."|r")
                    LuckbuttonCenterCount:Show()
                    LuckbuttonIcon[i]:SetHighlightTexture("Interface\\BUTTONS\\CheckButtonHilight")
                    LuckbuttonIcon[i]:LockHighlight()
                    if loop >= 2 then
                        LuckbuttonIcon[math.fmod(loop - 2, 20) + 1]:UnlockHighlight()
                        LuckbuttonIcon[math.fmod(loop - 2, 20) + 1]:SetHighlightTexture("Interface\\BUTTONS\\OldButtonHilight-Square")
                    end
                    loop = loop + 1
                    now = GetTime()
                end
            end
            if loop > totalLoop then
            	-- 动画放完了展现抽奖结果同时请求服务器发奖
                ShowRollResult()
            end
        elseif tenRollAnimationIsPlaying == true then
            if loop10 <= 10 then
                if GetTime() >= (now + animationDelay10) then
                    DrawTenRewardIcon(loop10,TenRewardItems[loop10],TenRewardItemLinks[loop10])
                    loop10 = loop10 + 1
                    now = GetTime()
                end
            end
            if loop10 > 10 then
                ShowTenRollResult()
            end
        end
    end
)

function StartSingleRoll(id)
    TenRewardFrame:Hide()
    rollAnimationIsPlaying = true
    gainedRewardsString:Hide() --奖品已发
    SingleRollBtn:Hide()
    singleRollBeganString:Show() --正在单抽......
    LuckbuttonCenter:UnlockHighlight()
    LuckbuttonCenter:SetHighlightTexture("Interface\\BUTTONS\\OldButtonHilight-Square")
    for i=1,20 do
        LuckbuttonIcon[i]:UnlockHighlight()
        LuckbuttonIcon[i]:SetHighlightTexture("Interface\\BUTTONS\\OldButtonHilight-Square")
    end
    RewardItem = tonumber(id)
    RewardItemLink = GetItemLink(chestData[RewardItem])
    -- 开奖动画，在OnUpdate event中循环播放动画，播放完了停止
    centerItemLink:SetText("")
    singleRollEnd = false
    SendPacket("GC_LUCKDRAW_SYSTEM", "RequestSingleRollReward")
end

-- 十连抽
function StartTenRoll(ids)
    TenRewardItems = ids
    TenRewardItemLinks = {}
    for _, id in ipairs(ids) do
        table.insert(TenRewardItemLinks, GetItemLink(chestData[tonumber(id)]))
    end
    tenRollAnimationIsPlaying = true
    gainedRewardsString:Hide() --奖品已发
    TenRollBtn:Hide()
    tenRollBeganString:Show() --正在十连
    InitTenRewardIcon()
    TenRewardFrame:Show()
end

function RecieveInfo(data,reqData)
    local tempData = {}
    for i=1,20 do
        local item = StrSplit(data[i],"-")
        chestData[i] = tonumber(item[1])
        chestCount[i] = tonumber(item[2])
    end
    InitChestData()
    local countText = " ("..reqData.nowCount.."/"..reqData.count..")"
    if reqData.nowCount < reqData.count then 
        countText = "|cffff0000"..countText.."|r" 
        canStartSingleRoll = false
    end
    local countText10 = " ("..reqData.nowCount10.."/"..reqData.count10..")"
    if reqData.nowCount10 < reqData.count10 then 
        countText10 = "|cffff0000"..countText10.."|r"
        canStartTenRoll = false
    end
    if reqData.item and reqData.item > 0 then
        _G["SingleRollReqText"]:SetText("|cFFFFC125 需要|r"..GetItemLink(reqData.item)..countText)
    end
    if reqData.item10 and reqData.item10 > 0 then
        _G["TenRollReqText"]:SetText("|cFFFFC125 需要|r"..GetItemLink(reqData.item10)..countText10)
    end
end

LuckFrame:SetScript("OnShow",
    function(self)
        --SendPacket("GC_LUCKDRAW_SYSTEM", "RequestData")
        singleRollEnd = false
        gainedRewardsString:Hide()
        LuckbuttonCenter:UnlockHighlight()
        LuckbuttonCenter:SetHighlightTexture("Interface\\BUTTONS\\OldButtonHilight-Square")
        LuckbuttonCenter:SetBackdrop( { bgFile = "Interface\\BUTTONS\\UI-EmptySlot", })
        LuckbuttonCenterCount:SetText("")
        LuckbuttonCenterCount:Hide()
        centerItemLink:SetText("")
        TenRewardFrame:Hide()
    end
)

function ShowRollResult()
    -- 先把动画停掉，防止OnUpdate event中继续放
    rollAnimationIsPlaying = false
    loop = math.fmod(RewardItem, 20) + 1
    singleRollEnd = true
    animationDelay = 0.05
    now = GetTime()
    centerItemLink:SetText(RewardItemLink)
    -- 动画播完之后再发奖品
    SendPacket("GC_LUCKDRAW_SYSTEM", "RequestSendReward")

    --单抽奖品已发放，请检查背包
    gainedRewardsString:Show() 
    LuckbuttonCenter:SetHighlightTexture("Interface\\BUTTONS\\CheckButtonHilight")
    LuckbuttonCenter:LockHighlight()
    SingleRollBtn:Show()
    singleRollBeganString:Hide() --正在单抽......
    SendPacket("GC_LUCKDRAW_SYSTEM", "RequestData")
end

function ShowTenRollResult()
    -- 先把动画停掉，防止OnUpdate event中继续放
    tenRollAnimationIsPlaying = false
    loop10 = 1
    now = GetTime()

    --单抽奖品已发放，请检查背包
    TenRollBtn:Show()
    tenRollBeganString:Hide() --正在十连抽抽......
    SendPacket("GC_LUCKDRAW_SYSTEM", "RequestData")
end

function GetLink(id)
    return "item:"..id..":0:0:1"
end

function GetItemLink(id)
    local name, code, quality = GetItemInfo("item:"..id..":0:0:1")
    if name then
        local _,_,_,color = GetItemQualityColor(quality)
        local s = color .. "|H" .. code .. "|h[" .. name .. "]|h|r"
        return s
    end
    return GetLink(id)
end

function GetItemIcon(id)
    if (not id) then return "Interface\\BUTTONS\\UI-EmptySlot"  end
    if not GetItemInfo(id) then
        return "Interface\\BUTTONS\\UI-EmptySlot" 
    end
    local sName, sLink, iQuality, iLevel, sType, sSubType, iCount, sEquipLoc, sTexture = GetItemInfo("item:"..id..":0:0:1")
    return sTexture
end
