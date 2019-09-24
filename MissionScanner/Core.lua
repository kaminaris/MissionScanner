local addonName, MissionScanner = ...;

LibStub('AceAddon-3.0'):NewAddon(
	MissionScanner, addonName, 'AceConsole-3.0', 'AceEvent-3.0', 'AceTimer-3.0', 'AceBucket-3.0'
);
_G[addonName] = MissionScanner;

local TableInsert = tinsert;
local GetItemInfo = GetItemInfo;
local ipairs = ipairs;
local pairs = pairs;
local GetAvailableMissions = C_Garrison.GetAvailableMissions;

MissionScanner.foundMissions = {};
MissionScanner.hasBeenScanned = false;

function MissionScanner:OnInitialize()
	self.db = LibStub('AceDB-3.0'):New('MissionScannerDb', self.defaultOptions);

	self:RegisterAllEvents();
	self:RegisterChatCommand('mscan', 'ShowWindow');
	self:AddToBlizzardOptions();
end

function MissionScanner:RegisterAllEvents()
	self:RegisterBucketEvent('GARRISON_MISSION_LIST_UPDATE', 2, 'FilterMissions');
	self:RegisterEvent('PLAYER_ENTERING_WORLD', 'CheckMissionsOnLogin')
	--'GET_ITEM_INFO_RECEIVED'
end

function MissionScanner:CheckMissionsOnLogin(e, isInitialLogin, isReloadingUi, isTimer)
	if isReloadingUi or not isInitialLogin then
		return;
	end

	if isTimer then
		self.activeInitTimer = nil;
	end

	if self.activeInitTimer then
		-- Timer has been scheduled, cancel
		return;
	end

	if not self.hasBeenScanned then
		self.activeInitTimer = self:ScheduleTimer('CheckMissionsOnLogin', 5, e, isInitialLogin, isReloadingUi, true);
		return;
	end

	if InCombatLockdown() or IsInInstance() then
		self.activeInitTimer = self:ScheduleTimer('CheckMissionsOnLogin', 5, e, isInitialLogin, isReloadingUi, true);
		return;
	end

	if self.activeInitTimer then
		self:CancelTimer(self.activeInitTimer);
		self.activeInitTimer = nil;
	end

	if #self.foundMissions > 0 then
		self:ShowWindow();
	else
		self:Print('Not found any missions');
	end
end

function MissionScanner:FilterMissions()
	if self.activeTimer then
		-- Timer has been scheduled, cancel
		return;
	end

	if InCombatLockdown() or IsInInstance() then
		self.activeTimer = self:ScheduleTimer('FilterMissions', 20);
		return;
	end

	if self.activeTimer then
		self:CancelTimer(self.activeTimer);
		self.activeTimer = nil;
	end

	self.foundMissions = {};

	for garrisonId, garrisonEnabled in pairs(self.db.global.garrisons) do
		if garrisonEnabled then
			--self:Print('Scanning garrison type: ' .. garrisonId)
			self:ScanGarrisonReward(garrisonId);
		end
	end

	--self:Print('FilterMissions');
	self.hasBeenScanned = true;
end

function MissionScanner:IsMissionWanted(mission)
	for _, reward in ipairs(mission.rewards) do
		local itemName, itemIcon, itemLink;

		if reward.itemID then
			itemName, itemLink, _, _, _, _, _, _, _, itemIcon = GetItemInfo(reward.itemID);
			if self.db.global.list.items[reward.itemID] then
				return true,
					itemIcon or mission.icon or reward.icon,
					reward.quantity or 1,
					itemName or reward.title,
					reward.itemID;
			end
		end

		if reward.currencyID then
			itemName = GetCurrencyInfo(reward.currencyID);
			if self.db.global.list.currencies[reward.currencyID] then
				return true,
					itemIcon or mission.icon or reward.icon,
					reward.quantity or 1,
					itemName or reward.title,
					reward.currencyID,
					reward.currencyID;
			end
		end

		if reward.currencyID == 0 then
			if self.db.global.list.currencies['gold'] then
				local money = math.floor(reward.quantity / 10000);
				return true,
					reward.icon,
					money,
					reward.title,
					nil,
					nil,
					reward.quantity
				;
			end
		end
	end

	return false;
end

function MissionScanner:ScanGarrisonReward(garrisonId)
	local missions = GetAvailableMissions(garrisonId);
	if not missions then
		return;
	end

	for _, mission in ipairs(missions) do
		local isWanted, icon, qty, itemName, itemId, currencyId, gold = self:IsMissionWanted(mission);

		if isWanted then
			TableInsert(self.foundMissions, {
				mission = mission,
				missionIcon = icon,
				qty = qty,
				itemName = itemName,
				missionName = mission.name or mission.title,
				missionType = mission.type,
				itemId = itemId,
				currencyId = currencyId,
				gold = gold,
			});
		end
	end
end