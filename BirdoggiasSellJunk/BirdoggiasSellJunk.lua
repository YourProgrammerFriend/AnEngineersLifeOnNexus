-----------------------------------------------------------------------------------------------
-- Client Lua Script for BirdoggiasSellJunk
-- Copyright (c) NCsoft. All rights reserved
-- I discovered something called JunkIt.  It was clearly created by exceptional examples of 
-- Dominion might.  I still do not trust them, but I respect their prowess.  I will base much
-- of what follows upon their skillful work.  Those interested in studying my sources may look:
-- http://www.curse.com/ws-addons/wildstar/220002-junkit
-----------------------------------------------------------------------------------------------

-- I'm going to provide documention here, for those young eningeers who might find use from this code.

-- This require tag establishes what can very broadly be called dependencies.  The require term loads and runs what are called "libraries"
-- and if they are unavailbe will cause some errors     
-- http://www.lua.org/pil/8.1.html

-- all of these are provided by the ingame "virtual environment" http://en.wikipedia.org/wiki/Virtual_environment_software
-- roughly speaking a "VE" is a digital space where your code (this script) will be executed.  The VE provides the below libraries to us.
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
-- there are 'global' variables.  I'm not exactly sure how well that definition carries in LUA atm, but what I can say is that they are for use 
-- in multiple locations later in the script and are defined here for clarity. 
local BirdoggiasSellJunk = {} 
local vendorAddon
local vendorOpen = false
-- There is much to learn from these JunkIt writers
-- this is a constant - a term we'll point to later, and that is unchanging, which has meaning within the context of our program logic.
local ItemCategory = {
	Junk = 94,
}
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
-- my lua know how is a bit slight here in terminology, however the new(0) is creating some kind of reference, or other identifier to our script
-- and its function etc.. .definitions... the term self will be used throughout the script to indicate our specific method 'namespace'...       
function BirdoggiasSellJunk:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here

    return o
end

-- init is called at the very bottom, here we register our addon, including its dependencies (Vendor is a library provided by the VirtualEnvironemtn
function BirdoggiasSellJunk:Init()
	-- we don't have any config
	local bHasConfigureFunction = false
	-- yea... more of the same, nothing here
	local strConfigureButtonText = ""
	-- dependencies!  We use the Vendor addon, which NCSOFT provides.  much nice
	local tDependencies = {"Vendor"}
	
	Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end
 

-----------------------------------------------------------------------------------------------
-- BirdoggiasSellJunk OnLoad
-----------------------------------------------------------------------------------------------
-- we don't actually have a UI, but we do have a file with some crap in it, we jus tnever show it
-- there are some usful things here though:
function BirdoggiasSellJunk:OnLoad()
    -- load our form file
	-- create an xmldoc from a file resources, as the function name implies...
	self.xmlDoc = XmlDoc.CreateFromFile("BirdoggiasSellJunk.xml")
	-- this one is cool:  it registers this script (the clojure which it represents) as a "callback handler" for the callback "OnDocLocaded" this
	-- approach will be seen throughout.  We define a function below (OnDocLoaded) which will be called when nescesary.     
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end

-----------------------------------------------------------------------------------------------
-- BirdoggiasSellJunk OnDocLoaded
-----------------------------------------------------------------------------------------------
-- see above
function BirdoggiasSellJunk:OnDocLoaded()

	-- if our doc was succesfully loaded
	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
	-- set our vendorAddon variable up for later usage by getting the addon from Apollo, which is the VM we run in.
	self.vendorAddon = Apollo.GetAddon("Vendor")

		-- we register callbacks for various vendor window actions, when the window is opened and closed

		-- Event thrown by opening the a Vendor window
		Apollo.RegisterEventHandler("InvokeVendorWindow",	"OnInvokeVendorWindow", self)
		-- Event thrown by closing the a Vendor window
		Apollo.RegisterEventHandler("CloseVendorWindow",	"OnVendorClosed", self)
	   
		-- this callback is special, it registers a slashcommand with Apollo (in this case /sj) with the callback "OnBirdoggiasSellJunkOn"
		-- which is a method below, this is how we call our function.
		Apollo.RegisterSlashCommand("sj", "OnBirdoggiasSellJunkOn", self)


		-- Do additional Addon initialization here
	end
end

function BirdoggiasSellJunk:OnVendorClosed()
   -- this lets us know th vendor window is closed or open
	self.vendorOpen = false 
end

-- Event handler for Vendor window opening.
function BirdoggiasSellJunk:OnInvokeVendorWindow(unitArg)
	-- vendor window is open!
	self.vendorOpen = true

end
-----------------------------------------------------------------------------------------------
-- BirdoggiasSellJunk Functions
-----------------------------------------------------------------------------------------------
-- Define general functions here

-- on SlashCommand "/sj"
-- a callback for when the user types /sj
function BirdoggiasSellJunk:OnBirdoggiasSellJunkOn()
	-- gets the inventory object from the GameLib library, specifically an object PlayerUnit from within there
	local inventory = GameLib.GetPlayerUnit():GetInventoryItems()
	-- a dictionary (?damn you lua) of key/val pairs of items which we seek to sell.  Starts empty, but we add to it laters
	local toSell = {}
	-- keep count
	local numToSell = 0
	-- this is a for loop.  It iterates over some set of items (the numbers 0-10, a collection of objects (orange,apple,pear) and provide each in turn 
	-- for processing.  ipairs is special in that its a stateless iterator http://www.lua.org/pil/7.3.html - i don't know enough lua right now to know
	-- what that really means
	
	-- in this case we iterate over all items in the inventory, and check if we should sell it.  If so we add it to the list of items to sell, and 
	-- increment the number of items we're going to sell.  
	for key,val in ipairs(inventory) do
		-- this checks if we should sell the item we're looking at
		if self:shouldSell(val.itemInBag) then
			-- does that insert
			table.insert(toSell,val)
			-- and iterations
			numToSell = numToSell+1
		end
	end
	-- sells the items we've set up
	-- see BirdoggiasSellJunk:sellItems(toSell,numSell)
	self:sellItems(toSell,numToSell)
end
	
-- much of this is modified from JunkIt... They were truely Clever Girls.....
function BirdoggiasSellJunk:sellItems(toSell,numToSell )
    -- this first line makes sure that the item toSell isn't nil, or for our purposes "non existant" its not quite that but it'l have to do.
    -- it also checks that our numToSell is greather than 0, just in case...
	if toSell ~= nil and numToSell > 0 then
	    -- another for loop, this time over the items we've flagged to sell
		for key, val in ipairs(toSell) do 
		    -- calls a built in function (?) to sell the tiem.  The val.itemInBag is kinda bad on my part, and should be fixed in the code which
			-- creates the list of items to sell...
			SellItemToVendorById(val.itemInBag:GetInventoryId(), val.itemInBag:GetStackCount())
		end
		-- this shows a message saying how many items were sold...
		self.vendorAddon:ShowAlertMessageContainer("Dominion sold" .. numToSell .. " items", false)
	end
end
-- yes


-- here we check if an item can be salvaged.  If it can we return true, if not we return false
function BirdoggiasSellJunk:canSalvage(item) 
	return item:CanSalvage()
end 


-- this checks if we should sell items
function BirdoggiasSellJunk:shouldSell(toSell)
    -- if the item exists, or doesn't have a price we return false (can't sell)
	if not toSell or not toSell:GetSellPrice() then return false end 

	-- I keep salvage, for the good of the Dominion.  It is also helpful when improving my mechanical form.  
	-- if you can salvage it we don't sell it...
	if self:canSalvage(toSell) then return false end 
	-- Sell junk  k  .
	if toSell:GetItemCategory() ==  ItemCategory.Junk then return true end
	-- this stuff is also junk.  I will sell it.  
	if toSell:GetItemQuality() == Item.CodeEnumItemQuality.Inferior then return true end

	return false
end

-----------------------------------------------------------------------------------------------
-- BirdoggiasSellJunk Instance
-----------------------------------------------------------------------------------------------
local BirdoggiasSellJunkInst = BirdoggiasSellJunk:new()
BirdoggiasSellJunkInst:Init()

