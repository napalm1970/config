-- STM32 / Cortex-M debugging via nvim-dap.
--
-- Стек: arm-none-eabi-gdb (как DAP-сервер) + OpenOCD (gdbserver на :3333).
-- OpenOCD стартует автоматически перед началом сессии и убивается на её завершении.
--
-- Использование в проекте:
--   * по умолчанию ищется ELF: <cwd>/build/<basename(cwd)>.elf
--   * openocd.cfg берётся из <cwd>/openocd.cfg
--   * запуск отладки: <leader>dc  (DapContinue) — соберёт через make и стартует
--   * брейкпоинты:    <leader>db
--   * UI:             <leader>du
--
-- Можно переопределить путь к ELF/cfg в .nvim.lua проекта, см. ниже.

local function project_root()
  -- Ищем корень по маркерам вверх от текущего буфера, а не полагаемся на cwd:
  -- файл может быть открыт из Core/Src, тогда make в cwd не найдёт Makefile.
  local markers = { "Makefile", "openocd.cfg", ".nvim.lua", "*.ioc" }
  local found = vim.fs and vim.fs.root and vim.fs.root(0, markers)
  return found or vim.fn.getcwd()
end

local function default_elf()
  local root = project_root()
  return root .. "/build/" .. vim.fn.fnamemodify(root, ":t") .. ".elf"
end

local function default_openocd_cfg()
  return project_root() .. "/openocd.cfg"
end

-- Достаём partnumber чипа из CubeMX .ioc (поле ProjectManager.DeviceId
-- или Mcu.UserName — там формат вида STM32F446RETx, как и ждёт probe-rs).
local function chip_from_ioc()
  local root = project_root()
  local iocs = vim.fn.glob(root .. "/*.ioc", false, true)
  if vim.tbl_isempty(iocs) then
    return nil
  end
  for _, line in ipairs(vim.fn.readfile(iocs[1])) do
    local chip = line:match("^ProjectManager%.DeviceId=(.+)") or line:match("^Mcu%.UserName=(.+)")
    if chip then
      return vim.trim(chip)
    end
  end
  return nil
end

-- Имя чипа для probe-rs (полный partnumber, не семейство).
-- Приоритет: vim.g.stm32_chip → автоопределение из .ioc → дефолт.
-- Проверить, что probe-rs знает чип: `probe-rs chip list | grep -i <имя>`.
local function probe_rs_chip()
  return vim.g.stm32_chip or chip_from_ioc() or "STM32F446RETx"
end

-- Сборка через make перед стартом сессии. Возвращает true/false.
-- nvim-dap лениво вычисляет функции-значения в конфиге, поэтому используем
-- ключ `preLaunchTask` как хук (тот же приём, что и в cortex_gdb-конфиге).
local function make_build()
  vim.cmd("silent! wall")
  local out = vim.fn.system({ "make", "-j", "-C", project_root() })
  if vim.v.shell_error ~= 0 then
    vim.notify("make failed:\n" .. out, vim.log.levels.ERROR)
    return false
  end
  return true
end

-- Глобальная ручка для процесса openocd, чтобы остановить его на terminate.
local openocd_job = nil

local function start_openocd(cfg)
  if openocd_job then
    return
  end
  if vim.fn.filereadable(cfg) == 0 then
    vim.notify("OpenOCD cfg not found: " .. cfg, vim.log.levels.ERROR)
    return
  end
  openocd_job = vim.fn.jobstart({ "openocd", "-f", cfg }, {
    on_exit = function()
      openocd_job = nil
    end,
    on_stderr = function(_, data)
      if data and #data > 0 then
        for _, line in ipairs(data) do
          if line ~= "" then
            vim.schedule(function()
              vim.notify("[openocd] " .. line, vim.log.levels.INFO)
            end)
          end
        end
      end
    end,
  })
  -- Дать OpenOCD время поднять gdbserver на :3333
  vim.wait(800)
end

local function stop_openocd()
  if openocd_job then
    vim.fn.jobstop(openocd_job)
    openocd_job = nil
  end
end

return {
  {
    "mfussenegger/nvim-dap",
    opts = function()
      local dap = require("dap")

      -- arm-none-eabi-gdb >= 14 умеет работать как DAP-сервер.
      dap.adapters.cortex_gdb = {
        type = "executable",
        command = "arm-none-eabi-gdb",
        args = { "-i", "dap" },
      }

      local cortex_config = {
        name = "STM32: OpenOCD + arm-none-eabi-gdb",
        type = "cortex_gdb",
        -- ВНИМАНИЕ: нативный DAP-сервер GDB (`gdb -i dap`) НЕ поддерживает
        -- `setupCommands` (это формат cpptools/VS Code) и в режиме `launch`
        -- не подключается к удалённому gdbserver. Поэтому:
        --   * request = "attach" + target = "localhost:3333"
        --     (gdb выполнит `target remote localhost:3333`);
        --   * прошивку (`load`) делаем отдельным gdb-батчем в preLaunchTask,
        --     т.к. native DAP `load`/`monitor` через конфиг не умеет.
        request = "attach",
        program = default_elf,
        cwd = project_root,
        target = "localhost:3333",
        stopAtBeginningOfMainSubprogram = true,
        -- Перед сессией: пересобрать, поднять openocd, прошить.
        preLaunchTask = function()
          vim.cmd("silent! wall")
          local make_ok = vim.fn.system({ "make", "-j", "-C", project_root() })
          if vim.v.shell_error ~= 0 then
            vim.notify("make failed:\n" .. make_ok, vim.log.levels.ERROR)
            return false
          end
          start_openocd(default_openocd_cfg())
          local flash = vim.fn.system({
            "arm-none-eabi-gdb", "-batch",
            "-ex", "target remote localhost:3333",
            "-ex", "monitor reset halt",
            "-ex", "load",
            "-ex", "monitor reset halt",
            default_elf(),
          })
          if vim.v.shell_error ~= 0 then
            vim.notify("flash failed:\n" .. flash, vim.log.levels.ERROR)
            return false
          end
          return true
        end,
      }

      -- probe-rs: собственный DAP-сервер, сам прошивает и держит соединение
      -- со ST-Link по SWD. OpenOCD/gdb не нужны.
      --   * adapter стартует `probe-rs dap-server --port <port>`;
      --   * формат launch.json — специфичный для probe-rs (chip/coreConfigs);
      --   * программирование делает сам probe-rs (flashingEnabled).
      dap.adapters.probe_rs = {
        type = "server",
        port = "${port}",
        executable = {
          command = "probe-rs",
          args = { "dap-server", "--port", "${port}" },
        },
      }

      local probe_rs_config = {
        name = "STM32: probe-rs",
        type = "probe_rs",
        request = "launch",
        cwd = project_root,
        chip = probe_rs_chip,
        connectUnderReset = false,
        speed = 8000,
        flashingConfig = {
          flashingEnabled = true,
          haltAfterReset = true,
        },
        coreConfigs = {
          {
            coreIndex = 0,
            programBinary = default_elf,
            -- rttEnabled = true,  -- включить, если в прошивке настроен RTT
          },
        },
        -- Пересобрать прошивку перед стартом (см. make_build).
        preLaunchTask = make_build,
      }

      for _, ft in ipairs({ "c", "cpp" }) do
        dap.configurations[ft] = dap.configurations[ft] or {}
        table.insert(dap.configurations[ft], cortex_config)
        table.insert(dap.configurations[ft], probe_rs_config)
      end

      -- Останавливаем openocd при завершении/отключении сессии.
      dap.listeners.after.event_terminated["stm32"] = function() stop_openocd() end
      dap.listeners.after.event_exited["stm32"]     = function() stop_openocd() end
      dap.listeners.after.disconnect["stm32"]       = function() stop_openocd() end

      -- Удобная команда для ручного контроля openocd.
      vim.api.nvim_create_user_command("OpenOCDStart", function()
        start_openocd(default_openocd_cfg())
      end, {})
      vim.api.nvim_create_user_command("OpenOCDStop", function()
        stop_openocd()
      end, {})
    end,
    keys = {
      { "<leader>dR", function() require("dap").run_to_cursor() end,                         desc = "Run to Cursor" },
      { "<leader>dM", function() require("dap").repl.toggle() end,                           desc = "DAP REPL" },
      { "<leader>dS", function() require("dap").session() end,                               desc = "DAP Session" },
    },
  },
}
