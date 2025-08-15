# GitHub Actions Workflows

## Currently Disabled

The `build.yml` workflow has been renamed to `build.yml.disabled` to stop automatic builds on every push.

### Why disabled?
- The project is in early development
- Frequent commits were triggering many build emails
- GitHub's macOS runners need specific Xcode configuration
- Build failures were creating noise during active development

### To re-enable:
1. Rename `build.yml.disabled` back to `build.yml`
2. Fix the Xcode configuration for GitHub runners
3. Consider running only on:
   - Pull requests (not every push)
   - Manual trigger
   - Tagged releases

### To stop email notifications:
1. Go to https://github.com/PedroGruvhagen/Notepad--/settings/notifications
2. Or unwatch the repository temporarily
3. Or go to https://github.com/settings/notifications and adjust email preferences