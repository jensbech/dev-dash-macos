# macOS menu bar app for system and CLI tool info

# What is this?
A menu bar app showing various system and configuration data, which for some features you can change state for.
- Show and change Kubectl context.
- Show and change Azure subscriptions.
- Show ISP info.
- Show Pulumi CLI login state
- Show and toggle runnig Docker containers.
- See media info / now playing / audio output source.

![example.png](example.png)

# Requirements
- macOS 26+
- `kubectl`, `az`, `gh`, `pulumi`, `docker` 

# Vibes
All Swift code made with vibes.

# Install
- Build from source and install, I have no Apple Developer account to cert sign the app.

# Build from source
- `just` is required: `brew install just`
- Build: `just build`
- Compile: `just bundle`
- Zip release: `just zip`
- Install into your Applications: `just install`
