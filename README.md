# Octlitch Linux

Octlitch is a Fedora-based Linux distribution built around KDE Plasma.

It is heavily customized, intentionally minimal, and highly opinionated. The goal is to ship a clean base system without unnecessary preinstalled software, so users can install only what they actually want.

Octlitch keeps Fedora's underlying security and system infrastructure while replacing the default desktop experience with Octlitch branding, themes, defaults, and tooling.

> **Status:** Early development / alpha  
> Octlitch is not yet recommended for production systems.

## Website

https://octlitch.com/

## Goals

- Fedora base for stability and security
- KDE Plasma desktop
- Minimal preinstalled application set
- Dark, focused visual design
- Compact bottom panel
- Sharp window decorations
- Multiple Octlitch themes and wallpapers
- LibreWolf included as the default browser
- Flatpak and Flathub for desktop applications
- DNF for system package management
- No built-in AI agents or services
- SELinux and Fedora security infrastructure retained
- No proprietary NVIDIA drivers included in the ISO

## Current themes

Octlitch currently ships with four curated desktop themes:

- Octlitch Valley
- Octlitch Model
- Octlitch Coast
- Octlitch Mountain

## Current state

The development ISO currently includes:

- Fedora 44 base
- KDE Plasma
- Octlitch branding
- Octlitch Plymouth boot splash
- Octlitch KDE splash
- Custom KWin decoration
- Custom Plasma themes
- Custom wallpapers
- LibreWolf
- KDE Discover
- Flatpak and Flathub support
- Customized live environment
- Customized installer launcher
- Octlitch documentation and website

## Package management

Octlitch uses:

- **DNF** for system packages
- **KDE Discover** for graphical Flatpak applications
- **Flathub** as the default Flatpak application source

The Fedora OCI Flatpak remote is not enabled by default.

## NVIDIA

Proprietary NVIDIA drivers are not bundled with the Octlitch ISO.

Users who choose to install them after installation can use the Octlitch NVIDIA helper:

```bash
sudo octlitch-install-nvidia
```

This keeps proprietary NVIDIA driver components out of the base installation image.

## Base image

Current development base:

- Fedora KDE Desktop 44
- x86_64

## Independence

Octlitch is an independent project.

It is not affiliated with, sponsored by, or endorsed by Fedora, Red Hat, KDE, LibreWolf, or their respective projects and organizations.

All trademarks belong to their respective owners.

## Warning

Octlitch is currently experimental software.

Expect:

- Bugs
- Incomplete hardware support
- Breaking changes between development builds
- Installer issues
- Package changes
- Theme and configuration changes

Do not rely on development builds for important data without maintaining backups.

## Contributing

Octlitch is open source.

You are free to:

- Fork the project
- Modify the source
- Build your own versions
- Submit improvements
- Open issues
- Submit pull requests

Contributions are welcome.

Source code:

https://github.com/OctavianIlie/octlitch

## License

Octlitch-specific source code in this repository is licensed under the MIT License unless otherwise stated.

Third-party software, Fedora packages, KDE components, LibreWolf, fonts, wallpapers, icons, and other externally sourced assets retain their respective upstream licenses.

See [LICENSE](LICENSE) for the Octlitch source-code license.

