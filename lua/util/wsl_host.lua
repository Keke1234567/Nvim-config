-- Resolve the mirrored Windows host IP for services on the Windows side
-- (LM Studio, Godot editor's LSP, ...). With WSL2 mirrored networking, the
-- host's LAN interfaces are mirrored into WSL, so our own primary LAN IPv4
-- *is* the Windows host address. Loopback (`127.0.0.1`) does NOT reach
-- Windows in this setup — see the wsl-lmstudio-networking memory.
--
-- Prefers RFC1918 LAN ranges; skips loopback, link-local, and (likely)
-- docker bridges. Hardcoded fallback last so a broken DHCP doesn't produce
-- a nil URL.
local M = {}

function M.ip()
  local uv = vim.uv or vim.loop
  local lan, any
  for _, addrs in pairs(uv.interface_addresses()) do
    for _, a in ipairs(addrs) do
      if a.family == "inet" and not a.internal
        and not a.ip:match("^169%.254%.") then
        any = any or a.ip
        if a.ip:match("^192%.168%.") or a.ip:match("^10%.") then
          lan = lan or a.ip
        end
      end
    end
  end
  return lan or any or "192.168.50.187"
end

return M
