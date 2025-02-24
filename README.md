# musescore-plugins-pneutrinoutil

My [pneutrinoutil](https://github.com/berquerant/pneutrinoutil) integrations in [MuseScore](https://musescore.org/en).

# Install

``` shell
make
vim .envrc # rewrite values of environment variables
direnv allow
make link
# Rewrite settings
vim pneutrinoutil.qml
vim bin/pneutrinoutil.sh
```

# Requirements

- macOS Sequoia (arm)
- MuseScore 3.6.2
- pneutrinoutil v0.4.1
- MuseScore 4.4.4 (as CLI)
- [direnv](https://github.com/direnv/direnv)
