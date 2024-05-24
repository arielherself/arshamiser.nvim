local conditions = require("heirline.conditions")
local heirline = require("heirline.utils")
local feliniser = require("arshamiser.feliniser.util")
local util = require("arshamiser.heirliniser.util")

local space = { provider = " " }
local spring = { provider = "%=" }

local inactive_left_slant = { --{{{
  provider = util.separators.slant_right_2,
  hl = {
    fg = util.colours.short_bg,
    bg = util.colours.mid_bg,
  },
} --}}}

local inactive_right_slant = { --{{{
  provider = util.separators.slant_right_2,
  hl = {
    fg = util.colours.mid_bg,
    bg = util.colours.short_bg,
  },
} --}}}

local vim_mode = { --{{{
  init = function(self)
    self.mode_ch = self.mode:sub(1, 1) -- get only the first mode character
  end,
  hl = function(self)
    return {
      fg = util.mode_colour(self.mode_ch),
      bold = true,
    }
  end,
  {
    hl = function(self)
      return {
        fg = util.colours.statusline_bg,
        bg = util.mode_colour(self.mode_ch),
        bold = true,
      }
    end,
    provider = "  ",
  },
  {
    provider = function(self)
      return "  %2(" .. util.mode_names[self.mode][1] .. "%) "
    end,
  },
} --}}}

local fold_method = { --{{{
  condition = function()
    return vim.wo.foldenable
  end,
  {
    hl = { fg = util.colours.green_pale, bold = true },
    { provider = "  " },
    { provider = feliniser.fold_method },
  },
} --}}}

local function git_count(prop, colour, icon) --{{{
  return {
    condition = function(self)
      return self.status_dict[prop] and self.status_dict[prop] > 0
    end,
    {
      provider = icon,
      hl = { fg = util.colours.git[colour] },
    },
    {
      provider = function(self)
        return self.status_dict[prop]
      end,
    },
  }
end --}}}

local git = { --{{{
  condition = conditions.is_git_repo,

  init = function(self)
    self.status_dict = vim.b.gitsigns_status_dict
  end,
  {
    flexible = 2,
    {
      { provider = "  ", hl = { fg = util.colours.git.add } },
      {
        provider = function(self)
          return self.status_dict.head
        end,
      },
    },
  },
  {
    condition = function(self)
      return self.has_changes == self.status_dict.added ~= 0
        or self.status_dict.removed ~= 0
        or self.status_dict.changed ~= 0
    end,
    {
      flexible = 4,
      {
        git_count("added", "add", "  "),
        git_count("removed", "del", "  "),
        git_count("changed", "change", "  "),
      },
      {
        git_count("removed", "del", "  "),
        git_count("changed", "change", "  "),
      },
      {
        git_count("removed", "del", "  "),
      },
    },
  },
} --}}}

local file_size = { -- Filesize {{{
  provider = function(self)
    local suffix = { "b", "k", "M", "G", "T", "P", "E" }
    local index = 1
    local fsize = vim.fn.getfsize(self.filename)

    if fsize < 0 then
      fsize = 0
    end

    while fsize > 1024 and index < 7 do
      fsize = fsize / 1024
      index = index + 1
    end
    return string.format(index == 1 and "%g%s" or "%.2f%s", fsize, suffix[index])
  end,
  hl = {
    fg = util.colours.grey_fg,
  },
} --}}}

local file_lock_info = { -- Modified / Readonly {{{
  {
    provider = function()
      if vim.bo.modified then
        return " "
      end
    end,
    hl = { fg = util.colours.green },
  },

  {
    provider = function()
      if not vim.bo.modifiable or vim.bo.readonly then
        return " "
      end
    end,
    hl = { fg = util.colours.orange },
  },
}

local file_name = { -- Filename {{{
  {
    flexible = 1,
    {
      provider = function(self)
        return self.short_filename
      end,
    },
    {
      provider = function(self)
        return vim.fn.pathshorten(self.short_filename)
      end,
    },
  },
} --}}}

local file_icon = { -- File icon {{{
  provider = function(self)
    return self.icon and (self.icon .. " ")
  end,
  hl = function(self)
    return { fg = self.icon_color }
  end,
} --}}}

local folder_name = {
  condition = function()
    return conditions.is_git_repo()
  end,
  { provider = util.separators.folder_icon, hl = { fg = util.colours.folder } },
  { provider = feliniser.git_root },
  space,
}

local fileinfo = { --{{{
  {
    flexible = 3,
    {
      folder_name,
      file_icon,
      file_name,
      file_lock_info,
      space,
      file_size,
    },
    {
      folder_name,
      file_icon,
      file_name,
      file_lock_info,
    },
    {
      folder_name,
      file_name,
    },
    {
      file_name,
    },
  },
} --}}}

local active_left_segment = { --{{{
  hl = {
    fg = util.colours.grey_fg,
  },
  vim_mode,
  { flexible = 3, fold_method },
  heirline.surround({ " ", " " }, util.colours.statusline_bg, git),
} --}}}

local active_middle_segment = { --{{{
  condition = function()
    return vim.fn.expand("%:t") ~= ""
  end,
  heirline.surround({ " ", " " }, util.colours.statusline_bg, fileinfo),
} --}}}

local locallist = { --{{{
  provider = feliniser.locallist_count,
  condition = function()
    return #vim.fn.getloclist(0) > 0
  end,
  hl = { fg = util.colours.purple },
} --}}}

local cursor_location = { --{{{
  { provider = "%l/%L|%c ", hl = { bold = true } },
  {
    provider = " %P",
    hl = function(self)
      return {
        fg = util.mode_colour(self.mode),
        bg = util.colours.mid_bg,
      }
    end,
  },
} --}}}

local active_right_segment = { --{{{
  condition = function()
    return vim.fn.expand("%:t") ~= ""
  end,
  hl = { fg = util.colours.grey_fg },
  {
    static = {
      icon = "  ",
    },
    condition = conditions.lsp_attached,
    {
      flexible = 2,
      {
        {
          provider = function(self)
            return self.icon .. feliniser.lsp_client_names()
          end,
        },
        { provider = feliniser.get_lsp_progress },
      },
      {
        {
          provider = function(self)
            return self.icon .. feliniser.lsp_client_names()
          end,
        },
      },
    },
  },

  { -- Diagnostics {{{
    condition = conditions.has_diagnostics,

    static = {
      error_icon = "  ",
      warn_icon = "  ",
      info_icon = "  ",
      hint_icon = "  ",
    },

    init = function(self)
      self.errors = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.ERROR })
      self.warnings = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.WARN })
      self.hints = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.HINT })
      self.info = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.INFO })
    end,

    {
      provider = function(self)
        return self.errors > 0 and (self.error_icon .. self.errors .. " ")
      end,
      hl = { fg = util.colours.diag.error },
    },
    {
      provider = function(self)
        return self.warnings > 0 and (self.warn_icon .. self.warnings .. " ")
      end,
      hl = { fg = util.colours.diag.warn },
    },
    {
      provider = function(self)
        return self.info > 0 and (self.info_icon .. self.info .. " ")
      end,
      hl = { fg = util.colours.diag.info },
    },
    {
      provider = function(self)
        return self.hints > 0 and (self.hint_icon .. self.hints)
      end,
      hl = { fg = util.colours.diag.hint },
    },
  }, --}}}

  { -- Spell check {{{
    provider = " 暈",
    condition = function()
      return vim.wo.spell
    end,
    hl = {
      fg = util.colours.yellow,
      bold = true,
    },
  }, --}}}

  { -- Filetype {{{
    flexible = 2,
    {
      hl = function(self)
        return {
          fg = self.icon_color,
          bold = true,
        }
      end,
      space,
      {
        provider = function(self)
          return self.icon or ""
        end,
      },
      space,
      {
        provider = function()
          return string.upper(vim.bo.filetype)
        end,
      },
    },
  }, --}}}

  space,
  { provider = feliniser.search_results },

  space,
  { -- Cursor Location {{{
    hl = function(self)
      return {
        fg = util.colours.light_bg,
        bg = util.mode_colour(self.mode),
      }
    end,
    {
      provider = util.separators.left_rounded,
      hl = function(self)
        return {
          fg = util.mode_colour(self.mode),
          bg = util.colours.light_bg,
        }
      end,
    },
    { provider = "" },

    space,
    {
      provider = feliniser.quickfix_count,
      condition = function()
        return #vim.fn.getqflist() > 0
      end,
      hl = { fg = util.colours.red_dark },
    },
    locallist,
    cursor_location,
  }, --}}}
} --}}}

local active_status_line = { --{{{
  condition = conditions.is_active,
  hl = {
    fg = heirline.get_highlight("StatusLine").fg,
    bg = heirline.get_highlight("StatusLine").bg,
  },

  heirline.surround(
    { "", util.separators.right_filled },
    util.colours.statusline_bg,
    active_left_segment
  ),

  spring,
  heirline.surround(
    { util.separators.left_filled, util.separators.right_filled },
    util.colours.statusline_bg,
    active_middle_segment
  ),

  spring,
  heirline.surround(
    { util.separators.left_filled, "" },
    util.colours.statusline_bg,
    active_right_segment
  ),
} --}}}

local inactive_right_segment = { --{{{
  condition = function()
    return vim.fn.expand("%:t") ~= ""
  end,

  hl = {
    fg = util.colours.mid_bg,
    bg = util.colours.green_pale,
  },
  {
    {
      provider = util.separators.slant_left,
      hl = {
        fg = util.colours.green_pale,
        bg = util.colours.short_bg,
      },
    },
    { provider = "" },
    locallist,
    cursor_location,
  },
} --}}}

local inactive_status_line = { --{{{
  condition = function()
    return not conditions.is_active()
  end,
  hl = {
    fg = util.colours.white,
    bg = util.colours.short_bg,
  },
  {
    hl = { bg = util.colours.mid_bg },
    git,
    space,
    inactive_right_slant,
  },

  spring,
  {
    inactive_left_slant,
    space,
    hl = { bg = util.colours.mid_bg },
    fileinfo,
    space,
    inactive_right_slant,
  },

  spring,
  inactive_right_segment,
} --}}}

local disabled_buffers = { --{{{
  condition = function()
    return conditions.buffer_matches({
      filetype = { "NvimTree", "dbui", "packer", "startify", "fugitive", "fugitiveblame" },
      buftype = { "nofile", "help", "quickfix", "terminal" },
    })
  end,
  provider = " ",
} --}}}

local help_file_name = { --{{{
  condition = function()
    return vim.bo.filetype == "help"
  end,
  provider = function()
    local filename = vim.api.nvim_buf_get_name(0)
    return vim.fn.fnamemodify(filename, ":t")
  end,
  hl = { fg = util.colours.blue },
} --}}}

local status_line = { --{{{
  statusline = {
    init = function(self)
      self.filename = vim.api.nvim_buf_get_name(0)
      self.short_filename = vim.fn.fnamemodify(self.filename, ":.")
      if self.short_filename == "" then
        self.short_filename = "[No Name]"
      end

      local extension = vim.fn.fnamemodify(self.filename, ":e")
      self.icon, self.icon_color =
        require("nvim-web-devicons").get_icon_color(self.filename, extension, { default = true })
      self.mode = vim.fn.mode(1)
    end,

    stop_when = function(_, out)
      return out ~= ""
    end,
    help_file_name,
    disabled_buffers,
    active_status_line,
    inactive_status_line,
  },
} --}}}

require("heirline").setup(status_line)

-- vim: foldmethod=marker foldlevel=0
