-----------------------------------------------------------------------------------------------
-- Client Lua Script for BirdoggiasSellJunk
-- Copyright (c) NCsoft. All rights reserved
-- I discovered something called JunkIt.  It was clearly created by exceptional examples of 
-- Dominion might.  I still do not trust them, but I respect their prowess.  I will base much
-- of what follows upon their skillful work.  Those interested in studying my sources may look:
-- http://www.curse.com/ws-addons/wildstar/220002-junkit
-----------------------------------------------------------------------------------------------
require "Window"
require "string"
require "math"
require "Sound"
require "Item"
require "Money"
require "GameLib"
-----------------------------------------------------------------------------------------------
-- BirdoggiasSellJunk Module Definition
-----------------------------------------------------------------------------------------------
local BirdoggiasSellJunk = {} 
local vendorAddon
local vendorOpen = false
-- There is much to learn from these JunkIt writers
local ItemCategory = {
	Junk = 94,
}
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
-- e.g. local kiExampleVariableMax = 999
 
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function BirdoggiasSellJunk:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here

    return o
end

function BirdoggiasSellJunk:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {"Vendor"}
	
	Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end
 

-----------------------------------------------------------------------------------------------
-- BirdoggiasSellJunk OnLoad
-----------------------------------------------------------------------------------------------
function BirdoggiasSellJunk:OnLoad()
    -- load our form file
	self.xmlDoc = XmlDoc.CreateFromFile("BirdoggiasSellJunk.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end

-----------------------------------------------------------------------------------------------
-- BirdoggiasSellJunk OnDocLoaded
-----------------------------------------------------------------------------------------------
function BirdoggiasSellJunk:OnDocLoaded()

	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
	   	
	self.vendorAddon = Apollo.GetAddon("Vendor")

		-- Event thrown by opening the a Vendor window
		Apollo.RegisterEventHandler("InvokeVendorWindow",	"OnInvokeVendorWindow", self)
		-- Event thrown by closing the a Vendor window
		Apollo.RegisterEventHandler("CloseVendorWindow",	"OnVendorClosed", self)
	   
		Apollo.RegisterSlashCommand("sj", "OnBirdoggiasSellJunkOn", self)


		-- Do additional Addon initialization here
	end
end

function BirdoggiasSellJunk:OnVendorClosed()
   --
	self.vendorOpen = false 
end

-- Event handler for Vendor window opening.
function BirdoggiasSellJunk:OnInvokeVendorWindow(unitArg)
	-- Check and see if options pane needs to be synced, if so sync it
	self.vendorOpen = true

end
-----------------------------------------------------------------------------------------------
-- BirdoggiasSellJunk Functions
-----------------------------------------------------------------------------------------------
-- Define general functions here

-- on SlashCommand "/sj"
function BirdoggiasSellJunk:OnBirdoggiasSellJunkOn()
	local inventory = GameLib.GetPlayerUnit():GetInventoryItems()
	local toSell = {}
	local numToSell = 0
	for key,val in ipairs(inventory) do
		if self:shouldSell(val.itemInBag) then
			table.insert(toSell,val)
			numToSell = numToSell+1
		end
	end
	self:sellItems(toSell,numToSell)
end
	
-- much of this is modified from JunkIt... They were truely Clever Girls.....
function BirdoggiasSellJunk:sellItems(toSell,numToSell )
	if toSell ~= nil and numToSell > 0 then
		for key, val in ipairs(toSell) do 
			SellItemToVendorById(val.itemInBag:GetInventoryId(), val.itemInBag:GetStackCount())
		end
		self.vendorAddon:ShowAlertMessageContainer("Dominion sold" .. numToSell .. " items", false)
	end
end
-- yes


-- yes
function BirdoggiasSellJunk:canSalvage(item) 
	return item:CanSalvage()
end 



function BirdoggiasSellJunk:shouldSell(toSell)

	if not toSell or not toSell:GetSellPrice() then return false end 

	-- I keep salvage, for the good of the Dominion.  It is also helpful when improving my mechanical form.  
	if self:canSalvage(toSell) then return false end 
	-- I sell junk.       .
	if toSell:GetItemCategory() == 84  then return true end
	-- this stuff is also junk.  I will sell it.
	if toSell:GetItemQuality() == Item.CodeEnumItemQuality.Inferior then return true end

	return false
end

-----------------------------------------------------------------------------------------------
-- BirdoggiasSellJunk Instance
-----------------------------------------------------------------------------------------------
local BirdoggiasSellJunkInst = BirdoggiasSellJunk:new()
BirdoggiasSellJunkInst:Init()

