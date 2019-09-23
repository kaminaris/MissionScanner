local addonName, MissionScanner = ...;

local StdUi = LibStub('StdUi', true);

function MissionScanner:ShowWindow()
	if self.mainWindow then
		self:UpdateTableData();
		self.mainWindow:Show();
		return ;
	end

	self.mainWindow = StdUi:Window(nil, addonName, 600, 500);
	self.mainWindow:SetPoint('CENTER', 0, 0);
	--mission = mission,
	--missionIcon = mission.icon,
	--missionName = mission.name or mission.title,
	--missionType = mission.type,
	--itemId = reward.itemID,
	--itemLink = itemLink,
	--itemIcon = itemIcon,
	--itemName = itemName
	local cols = {
		{
			name = 'Icon',
			width = 32,
			align = 'LEFT',
			index = 'missionIcon',
			format = 'icon',
			events = {
				OnEnter = function(table, cellFrame, rowFrame, rowData, columnData, rowIndex)
					local shouldShow = false;
					print(rowData.itemId, rowData.currencyId)

					if rowData.currencyId then
						GameTooltip:SetOwner(self.mainWindow);
						GameTooltip:SetCurrencyByID(rowData.currencyId, rowData.qty);
						shouldShow = true;
					elseif rowData.itemId then
						GameTooltip:SetOwner(self.mainWindow);
						GameTooltip:SetItemByID(rowData.itemId);
						shouldShow = true;
					elseif rowData.gold then
						GameTooltip:SetOwner(self.mainWindow);
						GameTooltip:SetText(rowData.itemName);
						GameTooltip:AddLine(GetMoneyString(rowData.gold));
						shouldShow = true;
					end

					if shouldShow then

						GameTooltip:Show();
						GameTooltip:ClearAllPoints();
						StdUi:GlueOpposite(GameTooltip, self.mainWindow, 0, 0, 'TOPRIGHT');
					end

					return false;
				end,
				OnLeave = function(table, cellFrame)
					GameTooltip:Hide();
					return false;
				end
			},
		},
		{
			name = 'Qty',
			width = 40,
			align = 'LEFT',
			index = 'qty',
			format = 'text',
		},
		{
			name = 'Name',
			width = 150,
			align = 'LEFT',
			index = 'itemName',
			format = 'text',
		},
		{
			name = 'missionName',
			width = 150,
			align = 'LEFT',
			index = 'missionName',
			format = 'text',
		},
		{
			name = 'missionType',
			width = 150,
			align = 'LEFT',
			index = 'missionType',
			format = 'text',
		},
	}

	local missionTable = StdUi:ScrollTable(self.mainWindow, cols, 20, 18);
	missionTable:EnableSelection(true);
	--missionTable:RegisterEvents({
	--	OnClick = function(table, cellFrame, rowFrame, rowData, columnData, rowIndex, button)
	--		if button == 'LeftButton' then
	--			if IsShiftKeyDown() then
	--				Sell:InstantBuy(rowData, rowIndex)
	--			elseif IsAltKeyDown() then
	--				Sell:AddToQueue(rowData, rowIndex);
	--			elseif IsControlKeyDown() then
	--				Sell:ChainBuyStart(rowIndex);
	--			else
	--				if table:GetSelection() == rowIndex then
	--					table:ClearSelection();
	--				else
	--					table:SetSelection(rowIndex);
	--				end
	--			end
	--		end
	--		return true;
	--	end
	--});
	StdUi:GlueAcross(missionTable, self.mainWindow, 20, -60, -20, 55);
	self.mainWindow.missionTable = missionTable;
	self:UpdateTableData();
end

function MissionScanner:UpdateTableData()
	self:FilterMissions();
	self.mainWindow.missionTable:SetData(self.foundMissions, true);
end