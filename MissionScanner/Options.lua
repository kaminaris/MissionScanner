local addonName, MissionScanner = ...;

local StdUi = LibStub('StdUi', true);

--:ResetDB


local function updateItemButton(parent, checkbox, data)
	checkbox.data = data;

	checkbox:SetText(data.itemName);
	checkbox.icon:SetTexture(data.texture);
	StdUi:SetObjSize(checkbox, 60, 20);
	checkbox:SetPoint('RIGHT');
	checkbox:SetPoint('LEFT');

	if not checkbox.OnValueChanged then
		checkbox.OnValueChanged = function(_, flag)
			data.checked = flag;
		end
	end

	return checkbox;
end

local createItemFrame = function (frame, row, info, dataKey, db)
	local element = StdUi:ScrollFrame(frame, 300, 200);

	function element:UpdateItems()
		if not self.childItems then
			self.childItems = {};
		end

		StdUi:ObjectList(
			self.scrollChild,
			self.childItems,
			'IconCheckbox',
			updateItemButton,
			db.wantedRewards, 1, 0, 0
		);
	end

	element:UpdateItems();
	return element;
end

local addItemButtonFn = function()
	local addItemBox = MissionScanner.optionsFrame.elements['addItemBox'];
	local itemId = addItemBox:GetValue();
	local itemName = addItemBox:GetText();

	if itemId and addItemBox:IsValid() then
		print('adding', itemId);
		if not MissionScanner.db.global.wantedRewards[itemId] then
			local itemIcon = GetItemIcon(itemId);

			MissionScanner.db.global.wantedRewards[itemId] = {
				itemId = itemId,
				itemName = itemName,
				texture = itemIcon
			};
		end

		MissionScanner.optionsFrame.elements['items']:UpdateItems();
	else
		MissionScanner:Print('Invalid item, please provide item ID or select it from list');
	end

	MissionScanner.optionsFrame.elements['items']:UpdateItems();
end

local customButtonUpdate = function(panel, optionButton, data)
	if not optionButton.icon then
		optionButton.text:SetJustifyH('LEFT');
		optionButton.text:ClearAllPoints();
		StdUi:GlueAcross(optionButton.text, optionButton, 22, -2, -2, 2);

		optionButton.icon = StdUi:Texture(optionButton, 20, 20);
		StdUi:GlueLeft(optionButton.icon, optionButton, 2, 0, true);
	end

	optionButton.icon:SetTexture(data.texture)
	optionButton.value = data.value;

	optionButton:SetWidth(panel:GetWidth());
	optionButton:SetText(data.text);
end

local itemsFn = function(ac, plainText)
	local itemLimit = ac.itemLimit;
	local result = {};

	for itemId, itemName in pairs(allItems) do
		if itemName:lower():find(plainText:lower(), nil, true) then
			local itemIcon = GetItemIcon(itemId);
			tinsert(result, {
				text = itemName,
				value = itemId,
				texture = itemIcon
			});
		end

		if #result >= itemLimit then
			break;
		end
	end

	return result;
end

function MissionScanner:GetOptionsConfig()
	local config = {
		layoutConfig = { padding = { top = 30 } },
		database     = self.db.global,
		rows         = {
			[1] = {
				enabled = {
					type   = 'checkbox',
					label  = 'Enable addon',
					column = 6
				},
				alert = {
					type   = 'checkbox',
					label  = 'Show alert when new mission is up',
					column = 6
				},
			},
			[2] = {
				garrisons = {
					type = 'dropdown',
					label = 'Garrison Types',
					multi = true,
					assoc = true,
					options = {
						{text = 'Garrison', value = LE_FOLLOWER_TYPE_GARRISON_6_0},
						{text = 'Order Hall', value = LE_FOLLOWER_TYPE_GARRISON_7_0},
						{text = 'War Campaign', value = LE_FOLLOWER_TYPE_GARRISON_8_0},
					}
				}
			},
			[3] = {
				addItemBox = {
					type = 'autocomplete',
					label = 'Search or provide Item ID',
					column = 6,
					order = 1,
					items = itemsFn,
					validator = StdUi.Util.autocompleteItemValidator,
					transformer = StdUi.Util.autocompleteItemTransformer,
					buttonUpdate = customButtonUpdate
				},
				addItem = {
					type   = 'button',
					text  = 'Add Item',
					column = 6,
					order = 2,
					onClick = addItemButtonFn
				},
			},
			[4] = {
				items = {
					type = 'custom',
					createFunction = createItemFrame
				}
			}
		},
	};

	return config;
end

function MissionScanner:OpenOptions()
	if self.optionsWindow then
		self.optionsWindow:Show();
		return;
	end

	local optionsWindow = StdUi:PanelWithTitle(UIParent, 100, 100, addonName .. ' Options');
	self.optionsWindow = optionsWindow;

	StdUi:BuildWindow(self.optionsWindow, self:GetOptionsConfig());
	StdUi:EasyLayout(optionsWindow, { padding = { top = 40 } });

	optionsWindow:SetScript('OnShow', function(of)
		of:DoLayout();
	end);
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