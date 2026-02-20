-- File: blackbox.lua

local function d(s)
    return (s:gsub("\\(%d+)", function(n)
        return string.char(tonumber(n))
    end))
end

-- Giải mã trực tiếp trong bộ nhớ
local s_id = tonumber(d("\\50\\48\\51\\53\\56"))
local s_key = d("\\51\\102\\55\\56\\57\\55\\102\\102\\45\\50\\56\\97\\100\\45\\52\\99\\102\\49\\45\\56\\98\\100\\100\\45\\50\\53\\56\\101\\97\\52\\56\\55\\98\\53\\100\\56")
local m_link = d("\\104\\116\\116\\112\\115\\58\\47\\47\\114\\97\\119\\46\\103\\105\\116\\104\\117\\98\\117\\115\\101\\114\\99\\111\\110\\116\\101\\110\\116\\46\\99\\111\\109\\47\\76\\101\\109\\111\\110\\79\\110\\84\\104\\101\\77\\105\\99\\47\\109\\97\\105\\110\\47\\114\\101\\102\\115\\47\\104\\101\\97\\100\\115\\47\\109\\97\\105\\110\\47\\109\\97\\105\\110\\46\\108\\117\\97")

-- Hàm băm dữ liệu (để giấu Secret)
local function lDigest(input)
    local hash = {}
    for i = 1, #tostring(input) do
        table.insert(hash, string.byte(tostring(input), i))
    end
    local hashHex = ""
    for _, byte in ipairs(hash) do
        hashHex = hashHex .. string.format("%02x", byte)
    end
    return hashHex
end

-- TRẢ VỀ CÁC HÀM (FUNCTIONS), KHÔNG TRẢ VỀ DỮ LIỆU
return {
    GetID = function()
        return s_id
    end,
    
    GetHash = function(nonce)
        -- Tự động tính toán Hash bằng Secret Key bên trong Hộp đen
        return lDigest("true-" .. nonce .. "-" .. s_key)
    end,
    
    LoadMain = function()
        -- Tự động Loadstring, hacker không thấy được link
        loadstring(game:HttpGet(m_link))()
    end
}
