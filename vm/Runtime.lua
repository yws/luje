-- Luje
-- © 2013 David Given
-- This file is redistributable under the terms of the
-- New BSD License. Please see the COPYING file in the
-- project root for the full text.

local ffi = require("ffi")
local Utils = require("Utils")
local dbg = Utils.Debug
local pretty = require("pl.pretty")
local string_byte = string.byte
local string_find = string.find
local table_concat = table.concat

local native_methods = {}
local globalhash = 0

local primitivetypes =
{
	[4] = {"Z", "bool"},
	[5] = {"C", "uint16_t"},
	[6] = {"F", "float"},
	[7] = {"D", "double"},
	[8] = {"B", "uint8_t"},
	[9] = {"S", "int16_t"},
	[10] = {"I", "int32_t"},
	[11] = {"J", "int64_t"}
}

local function New(classo)
	local hash = globalhash
	globalhash = globalhash + 1

	local o = {
		Class = function() return classo end,
		Hash = function() return hash end,
	}
	classo:InitInstance(o)

	setmetatable(o,
		{
			__index = function(self, k)
				local _, _, n = string_find(k, "m_(.*)")
				if n then
					Utils.Assert(n, "table slot for method ('", k, "') does not begin with m_")
					local m = classo:FindMethod(n)
					rawset(o, k, m)
					return m
				else
					return nil
				end
			end,
		}
	)

	return o
end

return {
	RegisterNativeMethod = function(class, name, func)
		native_methods[class.." "..name] = func
	end,

	FindNativeMethod = function(class, name)
		return native_methods[class.." "..name]
	end,

	New = New,

	NewArray = function(kind, length, callerclasso)
		local k = primitivetypes[kind]
		Utils.Assert(k, "unsupported primitive kind ", kind)
		local typechar, impl = unpack(k)

		local classname = "["..typechar
		local classo = callerclasso:ClassLoader():LoadInternalClass(classname)
		local object = New(classo)

		local store = ffi.new(impl.."["..tonumber(length).."]")

		object.ArrayPut = function(self, index, value)
			Utils.Assert((index >= 0) and (index < length), "array out of bounds access")
			store[index] = value
		end

		object.ArrayGet = function(self, index)
			Utils.Assert((index >= 0) and (index < length), "array out of bounds access")
			return store[index]
		end
				
		object.Length = function(self)
			return length
		end

		return object
	end,

	NewAArray = function(classo, length, callerclasso)
		local classname = "[L"..classo:ThisClass()..";"
		local arrayclasso = callerclasso:ClassLoader():LoadInternalClass(classname)
		local object = New(arrayclasso)

		local store = {}

		object.ArrayPut = function(self, index, value)
			Utils.Assert((index >= 0) and (index < length), "array out of bounds access")
			store[index] = value
		end

		object.ArrayGet = function(self, index)
			Utils.Assert((index >= 0) and (index < length), "array out of bounds access")
			return store[index]
		end
			
		object.Length = function(self)
			return length
		end

		return object
	end,

	CheckCast = function(o, classo)
		if not o then
			return
		end
		local c = o:Class()
		while c do
			if (c == classo) then
				return
			end
			c = c:SuperClass()
		end
		Utils.Throw("bad cast")
	end
}
