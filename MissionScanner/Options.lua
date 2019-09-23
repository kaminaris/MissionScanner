local addonName, MissionScanner = ...;

local StdUi = LibStub('StdUi', true);

MissionScanner.defaultOptions = {
	global = {
		enabled = true,
		alert = true,
		garrisons = {
			[LE_FOLLOWER_TYPE_GARRISON_6_0] = true,
			[LE_FOLLOWER_TYPE_SHIPYARD_6_2] = true,
			[LE_FOLLOWER_TYPE_GARRISON_7_0] = true,
			[LE_FOLLOWER_TYPE_GARRISON_8_0] = true,
		},
		mode = 1,
		list = {
			currencies = {},
			items = {}
		},
	}
}

function MissionScanner:ResetDB()
	self.db:ResetDB(self.defaultOptions);
end

function MissionScanner:OpenOptions()
	if IsAddOnLoaded('MissionScannerOptions') then
		MissionScannerOptions:OpenOptions();
	else
		if not LoadAddOn('MissionScannerOptions') then
			self:Print('MissionScannerOptions addon is disabled!');
			return;
		end

		MissionScannerOptions:OpenOptions();
	end
end

function MissionScanner:AddToBlizzardOptions()
	if self.optionsFrame then
		return;
	end

	local optionsFrame = StdUi:PanelWithTitle(UIParent, 100, 100, addonName .. ' Options');
	self.optionsFrame = optionsFrame;
	optionsFrame:Hide();
	optionsFrame.name = addonName;

	local btn = StdUi:Button(optionsFrame, 200, 20, 'Open Options');
	btn:SetPoint('CENTER');
	btn:SetScript('OnClick', function ()
		self:OpenOptions();
	end);

	InterfaceOptions_AddCategory(optionsFrame);
end