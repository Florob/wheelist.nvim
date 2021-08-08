local strdisplaywidth = vim.fn.strdisplaywidth;

local valid_fields = {
	eol = 1, tab = 3, space = 1, lead = 1, trail = 1, extends = 1,
	precedes = 1, conceal = 1, nbsp = 1,
}

local function check_listchar(field, char)
	if type(char) == 'nil' then
		return true
	end

	local max_len = valid_fields[field]
	if not max_len or type(char) ~= 'string' then
		return false
	end

	local len = strdisplaywidth(char)
	if len < 1 or len > max_len then
		return false
	end

	return true
end

local function check_listchars(chars)
	if type(chars) ~= 'table' then
		return false
	end

	for key, value in pairs(chars) do
		if not check_listchar(key, value) then
			return false
		end
	end

	return true
end

local current_listchars = nil
local listchars = {}
local listchars_indicies = {}
local listchars_names = {}

local function check_name(name)
	return listchars[name] ~= nil
end

local _M = {}

local function activate_listchars(name)
	vim.validate{name={name, check_name, 'the name of a listchars preset'}}
	vim.opt.listchars = listchars[name]
	current_listchars = name
end
_M.activate_listchars = activate_listchars

local defaultchars = {
	tab = '> ',
	trail = '-',
	nbsp = '+',
}

function _M.add_listchars(name, chars, use_defaults)
	vim.validate{
		name={name, 'string'},
		chars={
			chars,
			check_listchars,
			"a table with valid 'listchars' options",
		},
		use_defaults={use_defaults, 'boolean', true},
	}

	if use_defaults then
		chars = vim.tbl_extend('keep', chars, defaultchars)
	end

	listchars[name] = chars
	if not listchars_indicies[name] then
		local index = #listchars_names + 1
		listchars_indicies[name] = index
		listchars_names[index] = name
	end
end

local function step_listchars(modifier)
	local num_listchars = #listchars_names
	assert(num_listchars > 0, 'No listchars defined')

	local current_index = listchars_indicies[current_listchars] or 0
	local new_index = modifier(current_index, num_listchars)
	activate_listchars(listchars_names[new_index])
end

function _M.prev_listchars()
	step_listchars(function(current_index, num_listchars)
		local prev_index = current_index - 1
		return prev_index >= 1 and prev_index or num_listchars
	end)
end

function _M.next_listchars()
	step_listchars(function(current_index, num_listchars)
		local next_index = current_index + 1
		return next_index <= num_listchars and next_index or 1
	end)
end

local function set_listchar(name, field, char)
	vim.validate{
		name={name, check_name, 'the name of a listchars preset'},
		char={
			char,
			function(v) return check_listchar(field, v) end,
			"a string valid for '"..field.."'",
		},
	}
	listchars[name][field] = char
end

for field, _ in pairs(valid_fields) do
	_M['set_'..field] = function(name, char)
		set_listchar(name, field, char)
		activate_listchars(current_listchars)
	end
end

return _M
