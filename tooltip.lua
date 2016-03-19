local private, public = {}, {}
Aux.tooltip = public

local game_tooltip_hooks = {}

function public.on_load()
    for func, hook in game_tooltip_hooks do
        local func, hook = func, hook
        Aux.hook(
            func,
            function(...)
                local results = {Aux.orig[GameTooltip][func](unpack(arg))}
                hook(unpack(arg))
                return unpack(results)
            end,
            GameTooltip
        )
    end
    local orig = SetItemRef
    SetItemRef = function(...)
        local result = orig(unpack(arg))
        local name, _, quality = GetItemInfo(arg[1])
        if not IsShiftKeyDown() and not IsControlKeyDown() and name then
            local _, _, _, hex = GetItemQualityColor(quality)
            local link = hex.. '|H'..arg[1]..'|h['..name..']|h|r'
            private.extend_tooltip(ItemRefTooltip, link, 1)
        end
        return result
    end
end

function private.extend_tooltip(tooltip, hyperlink, quantity)
    local item_id, suffix_id = Aux.info.parse_hyperlink(hyperlink)

    if not Aux.static.item_info(item_id) then
        return
    end

    local item_key = (item_id or 0)..':'..(suffix_id or 0)

    local value = Aux.history.value(item_key)

    local value_line = 'Value: '

    value_line = value_line..(value and Aux.util.format_money(value) or GRAY_FONT_COLOR_CODE..'---'..FONT_COLOR_CODE_CLOSE)

    local color = {r=1.0, g=1.0, b=0.6}

    tooltip:AddLine(value_line, color.r, color.g, color.b)

    if aux_tooltip_daily then
        local market_value = Aux.history.market_value(item_key)

        local market_value_line = 'Today: '
        market_value_line = market_value_line..(market_value and Aux.util.format_money(market_value)..' ('..Aux.auction_listing.percentage_historical(Aux.round(market_value / value * 100))..')' or GRAY_FONT_COLOR_CODE..'---'..FONT_COLOR_CODE_CLOSE)

        tooltip:AddLine(market_value_line, color.r, color.g, color.b)
    end

    tooltip:Show()
end

function game_tooltip_hooks:SetHyperlink(itemstring)
    local name, _, quality = GetItemInfo(itemstring)
    if name then
        local _, _, _, hex = GetItemQualityColor(quality)
        local link = hex.. '|H'..itemstring..'|h['..name..']|h|r'
        private.extend_tooltip(GameTooltip, link, 1)
    end
end

function game_tooltip_hooks:SetAuctionItem(type, index)
    local link = GetAuctionItemLink(type, index)
    if link then
        local _, _, quantity = GetAuctionItemInfo(type, index)
        private.extend_tooltip(GameTooltip, link, quantity)
    end
end

function game_tooltip_hooks:SetLootItem(slot)
    local link = GetLootSlotLink(slot)
    if link then
        local _, _, quantity = GetLootSlotInfo(slot)
        private.extend_tooltip(GameTooltip, link, quantity)
    end
end

function game_tooltip_hooks:SetQuestItem(qtype, slot)
    local link = GetQuestItemLink(qtype, slot)
    if link then
        local _, _, quantity = GetQuestItemInfo(qtype, slot)
        private.extend_tooltip(GameTooltip, link, quantity)
    end
end

function game_tooltip_hooks:SetQuestLogItem(qtype, slot)
    local link = GetQuestLogItemLink(qtype, slot)
    if link then
        local _, _, quantity = GetQuestLogRewardInfo(slot)
        private.extend_tooltip(GameTooltip, link, quantity)
    end
end

function game_tooltip_hooks:SetBagItem(bag, slot)
    local link = GetContainerItemLink(bag, slot)
    if link then
        local _, quantity = GetContainerItemInfo(bag, slot)
        private.extend_tooltip(GameTooltip, link, quantity)
    end
end

--function game_tooltip_hooks:SetInboxItem(index)
--    local name, _, quantity = GetInboxItem(index)
--
--    for itemID = 1, 30000 do
--        local itemName, itemstring, itemQuality = GetItemInfo(itemID)
--        if (itemName and itemName == inboxItemName) then
--            local _, _, _, hex = GetItemQualityColor(tonumber(itemQuality))
--            local itemLink = hex.. '|H'..itemstring..'|h['..itemName..']|h|r'
--            tooltipCall(GameTooltip, inboxItemName, itemLink, inboxItemQuality, inboxItemCount)
--            break
--        end
--    end
--end

function game_tooltip_hooks:SetInventoryItem(unit, slot)
    local link = GetInventoryItemLink(unit, slot)
    if link then
        private.extend_tooltip(GameTooltip, link, 1)
    end
end

function game_tooltip_hooks:SetMerchantItem(slot)
    local link = GetMerchantItemLink(slot)
    if link then
        local _, _, _, quantity = GetMerchantItemInfo(slot)
        private.extend_tooltip(GameTooltip, link, quantity)
    end
end

function game_tooltip_hooks:SetCraftItem(skill, slot)
    local link, quantity
    if slot then
        link = GetCraftReagentItemLink(skill, slot)
        quantity = ({GetCraftReagentInfo(skill, slot)})[3]
    else
        link = GetCraftItemLink(skill)
        quantity = 1
    end
    if link then
        private.extend_tooltip(GameTooltip, link, quantity)
    end
end

function game_tooltip_hooks:SetCraftSpell(slot)
    local link = GetCraftItemLink(slot)
    if link then
        private.extend_tooltip(GameTooltip, link, 1)
    end
end

function game_tooltip_hooks:SetTradeSkillItem(skill, slot)
    local link, quantity
    if slot then
        link = GetTradeSkillReagentItemLink(skill, slot)
        quantity = ({GetTradeSkillReagentInfo(skill, slot)})[3]
    else
        link = GetTradeSkillItemLink(skill)
        quantity = 1
    end
    if link then
        private.extend_tooltip(GameTooltip, link, quantity)
    end
end

function game_tooltip_hooks:SetAuctionSellItem()
    local name, _, quantity, _, _, _ = GetAuctionSellItemInfo()
    if name then
        for bag = 0, 4 do
            if GetBagName(bag) then
                for slot = 1, GetContainerNumSlots(bag) do
                    local link = GetContainerItemLink(bag, slot)
                    if link and ({Aux.info.parse_hyperlink(link)})[5] == name then
                        private.extend_tooltip(GameTooltip, link, quantity)
                        return
                    end
                end
            end
        end
    end
end