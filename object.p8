-- Adapted from classic by rxi (MIT license)

Object = {}
Object.__index = Object


function Object:new()
end


function Object:extend()
  local cls = {}
  for k, v in pairs(self) do
    if sub(k, 1, 2) == "__" then
      cls[k] = v
    end
  end
  cls.__index = cls
  cls.super = self
  setmetatable(cls, self)
  return cls
end


function Object:__call(...)
  local obj = setmetatable({}, self)
  obj:new(...)
  return obj
end


function Object:is(T)
  local mt = getmetatable(self)
  while mt do
    if mt == T then
      return true
    end
    mt = getmetatable(mt)
  end
  return false
end
