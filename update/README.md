# Update Scripts

Scripts for updating installed components.

## Neovim Updates

Update to latest nightly:
```bash
./update-neovim.sh
```

Install a specific version:
```bash
./update-neovim-specific.sh v0.12.0
```

List available versions:
```bash
./update-neovim-specific.sh
```

## Notes

- Requires initial installation via `install-neovim.sh`
- Updates are installed to `/usr/local/bin`
- The system neovim package remains for omarchy-nvim compatibility
