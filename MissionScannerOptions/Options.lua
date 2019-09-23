local addonName, MissionScannerOptions = ...;

_G[addonName] = MissionScannerOptions;

local StdUi = LibStub('StdUi', true);
local LIN = LibStub('LibItemNames');

local allItems = LIN:GetItemNames();
local TableInsert = tinsert;

MissionScannerOptions.db = MissionScanner.db;

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
			db.list.items, 1, 0, 0
		);
	end

	element:UpdateItems();
	return element;
end

local addItemButtonFn = function()
	local Msc = MissionScannerOptions;
	local addItemBox = Msc.optionsWindow.elements['addItemBox'];
	local itemId = addItemBox:GetValue();
	local itemName = addItemBox:GetText();

	if itemId and addItemBox:IsValid() then
		print('adding', itemId);
		if not Msc.db.global.list.items[itemId] then
			local itemIcon = GetItemIcon(itemId);

			Msc.db.global.list.items[itemId] = {
				itemId = itemId,
				itemName = itemName,
				texture = itemIcon
			};
		end

		Msc.optionsWindow.elements['items']:UpdateItems();
	else
		MissionScanner:Print('Invalid item, please provide item ID or select it from list');
	end

	Msc.optionsWindow.elements['items']:UpdateItems();
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
			TableInsert(result, {
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

function MissionScannerOptions:GetOptionsConfig()
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
					column = 6,
					options = {
						{text = 'Garrison', value = LE_FOLLOWER_TYPE_GARRISON_6_0},
						{text = 'Shipyard', value = LE_FOLLOWER_TYPE_SHIPYARD_6_2},
						{text = 'Order Hall', value = LE_FOLLOWER_TYPE_GARRISON_7_0},
						{text = 'War Campaign', value = LE_FOLLOWER_TYPE_GARRISON_8_0},
					}
				},
				mode = {
					type = 'dropdown',
					label = 'Filter Type',
					column = 6,
					options = {
						{text = 'White list', value = 1},
						{text = 'Black list', value = 2},
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
					hasLabel = true,
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
			},
			[5] = {
				currencies = {
					type = 'header',
					label = 'Currencies'
				}
			},
		},
	};

	local supportedCurrencies = {
		'gold', -- Gold
		1718, -- Titan Residuum
		1721, -- Prismatic Manapearl
		1533, -- Wakening Essence
		1508, -- Veiled Argunite
		823,  -- Apexis Crystal
		1226, -- Nethershard
		1101, -- Oil
		1553, -- Azerite
		1342, -- Legionfall War Supplies
	};

	local row = {};
	for i = 1, #supportedCurrencies do
		local currency = supportedCurrencies[i];

		local currencyName = currency == 'gold' and 'Gold' or GetCurrencyInfo(currency);

		row[currency] = {
			type = 'checkbox',
			label  = currencyName,
			initialValue = self.db.global.list.currencies[currency];
			onValueChanged = function(_, flag)
				self.db.global.list.currencies[currency] = flag;
			end,
			column = 4,
			order = i % 3
		}

		if i % 3 == 0 or i == #supportedCurrencies then
			TableInsert(config.rows, row);
			row = {};
		end
	end
	return config;
end

function MissionScannerOptions:OpenOptions()
	if self.optionsWindow then
		self.optionsWindow:Show();
		return;
	end

	local optionsWindow = StdUi:Window(UIParent, 'MissionScanner Options', 600, 600);
	optionsWindow:SetPoint('CENTER');

	self.optionsWindow = optionsWindow;

	StdUi:BuildWindow(self.optionsWindow, self:GetOptionsConfig());
	StdUi:EasyLayout(optionsWindow, { padding = { top = 40 } });

	optionsWindow:SetScript('OnShow', function(of)
		of:DoLayout();
	end);
end