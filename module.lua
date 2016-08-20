local setmetatable, unpack, mask, add, g = setmetatable, unpack, bit.band, bit.bor, getfenv(0)
local DECLARED, PUBLIC, MUTABLE, ACCESSOR, MUTATOR = 1, 2, 4, 8, 16
local MODIFIER = {public=PUBLIC, mutable=MUTABLE, accessor=ACCESSOR, mutator=MUTATOR}
local _10, _01, tf, ft = {[true]=1, [false]=0}, {[true]=0, [false]=1}, {true, false}, {false, true}
local importer_mt, modifier_mt, env_mt, interface_mt, lock_mt
local define_property, declarator_accessor, public_accessor, mutable_accessor, accessor_accessor, mutator_accessor, index, error
local _modules, _metadata, _data, _accessors, _mutators, _imports, _declarators, _declarator_state = setmetatable({}, lock_mt), {}, {}, {}, {}, {}, {}, {}
function error(message, ...) g.error(format(message, unpack(arg))..'\n'..debugstack(3, 5, 0), 3) end
importer_mt = {__metatable=false}
function importer_mt.__call(self, ...)
	local imports = _imports[self]
	for i=1,arg.n do imports[arg[i]] = true end
end
function declarator_accessor(modifier)
	return function(declarator) return function() _declarator_state[declarator] = DECLARED+modifier return declarator end end
end
public_accessor, mutable_accessor, accessor_accessor, mutator_accessor = declarator_accessor(PUBLIC), declarator_accessor(MUTABLE), declarator_accessor(ACCESSOR), declarator_accessor(MUTATOR)
function define_property(self, key, t)
	local accessor, mutator = t.get, t.set
	_declarator_state[self] = add(_01[not accessor]*ACCESSOR, _01[not mutator]*MUTATOR, _declarator_state[self])
	_accessors[self][key], _mutators[self][key] = accessor, mutator
end
modifier_mt = {__metatable=false}
function modifier_mt.__index(self, key)
	local modifier = MODIFIER[key]
	if not modifier then return function(t) define_property(self, key, t) end end
	_declarator_state[self] = add(modifier, _declarator_state[self])
	return self
end
function modifier_mt.__newindex(self, key, value)
	if _metadata[self][key] then error('Field "%s" already exists.', key) end
	_metadata[self][key], _data[self][key], _accessors[self][key], _mutators[self][key] = _declarator_state[self], value, value, value
end
function index(access, default)
	return function(self, key)
		local modifiers = _metadata[self][key] or 0
		if mask(access+ACCESSOR, modifiers) == access then
			return _data[self][key]
		elseif mask(access, modifiers) ~= 0 then
			return _accessors[self]()
		else
			return default[key] or error('No field "%s".', key)
		end
	end
end
env_mt = {__metatable=false, __index=index(DECLARED, g)}
function env_mt.__newindex(self, key, value)
	if not _metadata[self][key] then
		_metadata[self][key] = DECLARED
	elseif mask(MUTABLE, _metadata[self][key]) == 0 then
		error('Field "%s" is immutable.', key)
	end
	_data[self][key] = value
end
interface_mt = {__metatable=false, __index=index(PUBLIC, {})}
function interface_mt.__newindex(self, key, value) self[key](value) end
lock_mt = {}
function g.aux_module(name)
	if not _modules[name] then
		local metadata, data, accessors, mutators, imports, importer, declarator, env, interface
		imports, importer, declarator, env, interface = {}, setmetatable({}, importer_mt), setmetatable({}, modifier_mt), setmetatable({}, env_mt), setmetatable({}, interface_mt)
		metadata = setmetatable({g=DECLARED, m=DECLARED, import=DECLARED, public=ACCESSOR, mutable=ACCESSOR, accessor=ACCESSOR, mutator=ACCESSOR}, lock_mt)
		data = {g=g, m=env, import=importer, public=public_accessor(declarator), mutable=mutable_accessor(declarator), accessor=accessor_accessor(declarator), mutator=mutator_accessor(declarator)}
		_metadata[name], _metadata[declarator], _metadata[env], _metadata[interface] = metadata, metadata, metadata, metadata
		_data[name], _data[declarator], _data[env], _data[interface] = data, data, data, data
		_accessors[name], _accessors[declarator], _accessors[env], _accessors[interface] = accessors, accessors, accessors, accessors
		_mutators[name], _mutators[declarator], _mutators[env], _mutators[interface] = mutators, mutators, mutators, mutators
		_imports[name], _imports[importer] = imports, imports
		_declarators[name] = declarator
		_modules[name] = {env, interface}
	end
	return unpack(_modules[name])
end
local frame = CreateFrame 'Frame'
frame:RegisterEvent 'PLAYER_LOGIN'
frame:SetScript('OnEvent', function()
	lock_mt.__newindex = function() error 'Cannot change modules after the loading phase.' end
	local count = 0
	local t0 = GetTime()
	for name in _modules do
		local declarator = _declarators[name]
		for import_name in _imports[name] do
			if not _modules[import_name] then error('Invalid import %s in %s.', import_name, name) end
			local data = _data[import_name]
			for key, modifiers in _metadata[import_name] do
				if mask(PUBLIC, modifiers) ~= 0 then
					_declarator_state[declarator] = modifiers
					declarator[key] = data[key]
				end
			end
		end
	end
	aux.log('imported: '..count..' in '..(GetTime()-t0))
end)