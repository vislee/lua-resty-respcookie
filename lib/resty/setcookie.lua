-- Copyright (C) 2018 vislee
local cjson = require "cjson.safe"

local byte       = string.byte
local str_sub    = string.sub

local EQUAL         = byte("=")
local SEMICOLON     = byte(";")
local SPACE         = byte(" ")
local HTAB          = byte("\t")

local ok, tab_new = pcall(require, "table.new")
if not ok then
    tab_new = function(narr, nrec) return {} end
end
local ok, tab_clear = pcall(require, "table.clear")
if not ok then
    tab_clear = function(tab) for k, _ in pairs(tab) do tab[k] = nil end end
end

local _M = tab_new(0, 6)
_M.version = "0.02"

local mt = { __index = _M }
function  _M.new()
    local cookie = ngx.header["set-cookie"] or tab_new(3, 0)
    local t = {
        _cookie = cookie,
        _cookie_cache = nil,
    }

    return setmetatable(t, mt)
end


local keyword = {Expires = 1, expires = 1,
    ["Max-Age"] = 1, ["max-age"] = 1,
    Domain = 1, domain = 1,
    Path = 1, path = 1,
    SameSite = 1,  sameSite = 1
}


-- key=val; key=val; val; val
local function _parse_cookie(text_cookie)
    local len = #text_cookie
    local m, n = 0, 0

    for i = 1, len do
        if byte(text_cookie, i) == SEMICOLON then
            n = n + 1
        elseif byte(text_cookie, i) == EQUAL then
            m = m + 1
        end
    end
    local tab = tab_new(n - m + 1, m + 1)

    local EXPECT_KEY    = 1
    local EXPECT_VALUE  = 2
    local EXPECT_SP     = 3

    local i, j = 1
    local key, val, cookie_key
    local state = EXPECT_SP

    while i <= len do
        if state == EXPECT_KEY then
            if byte(text_cookie, i) == EQUAL then
                key = str_sub(text_cookie, j, i-1)
                state = EXPECT_VALUE
                j = i + 1

                if not keyword[key] and not cookie_key then
                    cookie_key = key
                end

            elseif byte(text_cookie, i) == SEMICOLON or i == len then
                if i == len then
                    val = str_sub(text_cookie, j, i)
                else
                    val = str_sub(text_cookie, j, i-1)
                end
                state = EXPECT_SP
                j = i + 1
            end

        elseif state == EXPECT_VALUE then
            if byte(text_cookie, i) == SEMICOLON or i == len then
                if i == len then
                    val = str_sub(text_cookie, j, i)
                else
                    val = str_sub(text_cookie, j, i-1)
                end
                state = EXPECT_SP
                j = i + 1
            end

        else -- state == EXPECT_SP
            if not key and val then
                tab[#tab+1] = val
            elseif key and val then
                tab[key] = val
            end

            key, val = nil, nil
            if byte(text_cookie, i) ~= SPACE and byte(text_cookie, i) ~= HTAB then
                state = EXPECT_KEY
                j = i
            end
        end

        i = i + 1
    end

    return cookie_key, tab
end


local function _get_cookie_tab(cookie)
    local tab

    if type(cookie) == "table" then
        tab = tab_new(0, #cookie + 3)
        for i, ck in ipairs(cookie) do
            local k, t = _parse_cookie(ck)
            if k == nil then
                ngx.log(ngx.ERR, "err cookie:", ck)
            else
                t._index = i
                tab[k] = t
            end
        end
    else
        tab = tab_new(0, 3)
        local k, t = _parse_cookie(cookie)
        if k == nil then
            ngx.log(ngx.ERR, "err cookie:", cookie)
        else
            t._index = 1
            tab[k] = t
        end
    end

    return tab
end


function _M.get(self, key)
    if not self._cookie_cache then
        self._cookie_cache = _get_cookie_tab(self._cookie) or tab_new(1, 1)
    end

    local ck = self._cookie_cache[key]
    if not ck then
        return {}
    end

    local copy_ck = tab_new(3, #ck)
    for k, v in pairs(ck) do
        if not k then
            copy_ck[#copy_ck+1] = v
        elseif k ~= "_index" then
            copy_ck[k] = v
        end
    end

    return copy_ck
end


function _M.del(self, key)
    if not self._cookie_cache then
        self._cookie_cache = _get_cookie_tab(self._cookie) or tab_new(1, 1)
    end

    local ck = self._cookie_cache[key]
    if not ck then
        return
    end

    self._cookie[ck._index] = ""
    self._cookie_cache[key] = nil

    ck._index = nil

    return ck
end


function _M.set(self, text_cookie)
    if not self._cookie_cache then
        self._cookie_cache = _get_cookie_tab(self._cookie) or tab_new(1, 1)
    end

    if type(text_cookie) ~= "string" then
        return nil, "text_cookie is not string"
    end

    local key, cookie = _parse_cookie(text_cookie)

    if not key then
        return nil, "not have key"
    end

    local old_cookie = self._cookie_cache[key]
    if old_cookie and old_cookie._index then
        self._cookie[old_cookie._index] = ""
        old_cookie._index = nil
    end

    self._cookie[#self._cookie+1] = text_cookie
    cookie._index = #self._cookie
    self._cookie_cache[key] = cookie

    return old_cookie or {}
end


function _M.set_cookie(self)
    local c = self._cookie_cache
    self._cookie_cache = nil

    ngx.log(ngx.INFO, "====", cjson.encode(self._cookie))

    local tmp = {}
    for _, ck in ipairs(self._cookie) do
        if ck ~= nil and type(ck) == "string" and ck ~= "" then
            tmp[#tmp+1] = ck
        end
    end
    ngx.header["set-cookie"] = tmp
    -- if c and type(c) == "table" then
    --     tab_clear(c)
    -- end
end


return _M