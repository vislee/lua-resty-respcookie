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

local _get_cookie_tab
local mt = { __index = _M }
function  _M.new()
    local tmp_cookie = ngx.header["set-cookie"] or ""

    local t = {
        _cookie = _get_cookie_tab(tmp_cookie),
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
    local tab = tab_new(n - m + 1, m + 2)

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
                    i = i + 1
                end
                state = EXPECT_SP
                j = i
            end

        elseif state == EXPECT_VALUE then
            if byte(text_cookie, i) == SEMICOLON or i == len then
                if i == len then
                    val = str_sub(text_cookie, j, i)
                else
                    val = str_sub(text_cookie, j, i-1)
                    i = i + 1
                end
                state = EXPECT_SP
                j = i
            end
        end

        if state == EXPECT_SP then
            if key == nil and val then
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

    tab["_string"] = text_cookie

    return cookie_key, tab
end


_get_cookie_tab = function(cookie)
    local tab

    if cookie ~= nil and type(cookie) == "table" then
        tab = tab_new(0, #cookie + 3)
        for i, ck in ipairs(cookie) do
            local k, t = _parse_cookie(ck)
            if k == nil then
                ngx.log(ngx.ERR, "err cookie:", ck)
            else
                tab[k] = t
            end
        end
    else
        tab = tab_new(0, 3)
        if cookie == nil or cookie == "" then
            return tab
        end

        local k, t = _parse_cookie(cookie)
        if k == nil then
            ngx.log(ngx.ERR, "err cookie:", cookie)
        elseif #k > 0 then
            tab[k] = t
        end
    end

    return tab
end


function _M.get(self, key)
    local ck = self._cookie[key]

    return ck
end


function _M.del(self, key)
    local ck = self._cookie[key]
    self._cookie[key] = nil

    return ck
end


function _M.set(self, text_cookie)
    if type(text_cookie) ~= "string" then
        return nil, "text_cookie is not string"
    end

    local key, cookie = _parse_cookie(text_cookie)
    if not key then
        return nil, "not have key"
    end

    local old_cookie = self._cookie[key] or {}
    self._cookie[key] = cookie

    return old_cookie
end


function _M.set_cookie(self)
    local tmp = tab_new(#self._cookie + 1, 0)

    for _, ck in pairs(self._cookie) do
        if ck ~= nil and type(ck) == "table" and ck["_string"] ~= nil then
            tmp[#tmp+1] = ck["_string"]
        end
    end
    ngx.log(ngx.INFO, "====", cjson.encode(tmp))

    ngx.header["set-cookie"] = tmp
    tab_clear(tmp)
end


return _M