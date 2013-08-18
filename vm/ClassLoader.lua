-- Luje
-- © 2013 David Given
-- This file is redistributable under the terms of the
-- New BSD License. Please see the COPYING file in the
-- project root for the full text.

local Utils = require("Utils")
local dbg = Utils.Debug
local classanalyser = require("classanalyser")
local Class = require("Class")

local cache = {}
local path = "../bin/"

local function LoadClass(self, name)
	local c = cache[name]
	if c then
		return c
	end

	local s = Utils.LoadFile(path..name..".class")
	local t = classanalyser(s)
	c = Class(self)
	cache[name] = c
	c:Init(t)
	return c
end

return {
	LoadClass = LoadClass
}