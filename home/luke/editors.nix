{ ... }:
{
  programs.neovim = {
    defaultEditor = true;
    enable = true;
    viAlias = true;
    vimAlias = true;
  };

  xdg.configFile."nvim/lua/plugins/transparent.lua".text = ''
    return {
      {
        "xiyaowong/transparent.nvim",
        lazy = false,
        config = function()
          require("transparent").setup({
            extra_groups = { "StatusLine", "StatusLineNC" },
          })
          require("transparent").toggle(true)
          local function fix_stl()
            vim.api.nvim_set_hl(0, "StatusLine", { link = "Normal" })
            vim.api.nvim_set_hl(0, "StatusLineNC", { link = "Normal" })
          end
          vim.defer_fn(fix_stl, 1000)
          vim.api.nvim_create_autocmd({"BufEnter", "ColorScheme"}, {
            callback = function() vim.defer_fn(fix_stl, 100) end,
          })
        end,
      },
    }
  '';
}
