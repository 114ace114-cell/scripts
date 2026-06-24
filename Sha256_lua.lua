-- SHA256 Library - Pure Luau - Fixed & Perfect for loadstring
local SHA256 = {}

local K = {
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
    0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
    0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
    0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
    0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
    0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
    0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
}

-- Localize for speed optimization
local badd = bit32.badd
local rrotate = bit32.rrotate

local function preprocess(message)
    local len = #message * 8
    local padding = 512 - ((len + 1 + 64) % 512)
    if padding == 512 then padding = 0 end

    -- Using // 8 for Luau compatibility
    local padded = message .. "\x80" .. string.rep("\0", padding // 8) .. string.pack(">I8", len)
    return padded
end

function SHA256.hash(input)
    local message = type(input) == "string" and input or buffer.tostring(input)
    message = preprocess(message)

    local h0, h1, h2, h3, h4, h5, h6, h7 = 
        0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,
        0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19

    for i = 1, #message, 64 do
        local w = table.create(64)

        -- Switched to 1-16 loop for proper Luau array speed optimization
        for j = 1, 16 do
            w[j] = string.unpack(">I4", message, i + (j - 1) * 4)
        end

        for j = 17, 64 do
            local s0 = rrotate(w[j-15], 7) ~ rrotate(w[j-15], 18) ~ (w[j-15] >> 3)
            local s1 = rrotate(w[j-2], 17) ~ rrotate(w[j-2], 19) ~ (w[j-2] >> 10)
            w[j] = badd(w[j-16], s0, w[j-7], s1) -- Fixed: wrapping addition
        end

        local a, b, c, d, e, f, g, h = h0, h1, h2, h3, h4, h5, h6, h7

        for j = 1, 64 do
            local S1 = rrotate(e, 6) ~ rrotate(e, 11) ~ rrotate(e, 25)
            local ch = (e & f) ~ (~e & g)
            local temp1 = badd(h, S1, ch, K[j], w[j]) -- Fixed: wrapping addition

            local S0 = rrotate(a, 2) ~ rrotate(a, 13) ~ rrotate(a, 22)
            local maj = (a & b) ~ (a & c) ~ (b & c)
            local temp2 = badd(S0, maj) -- Fixed: wrapping addition

            h = g; g = f; f = e; e = badd(d, temp1)
            d = c; c = b; b = a; a = badd(temp1, temp2)
        end

        h0 = badd(h0, a)
        h1 = badd(h1, b)
        h2 = badd(h2, c)
        h3 = badd(h3, d)
        h4 = badd(h4, e)
        h5 = badd(h5, f)
        h6 = badd(h6, g)
        h7 = badd(h7, h)
    end

    return string.format("%08x%08x%08x%08x%08x%08x%08x%08x",
        h0, h1, h2, h3, h4, h5, h6, h7)
end

return SHA256
