# musescore-plugins-pneutrinoutil

My pneutrinoutil[^1] integrations in MuseScore[^2].

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
- pneutrinoutil[^1] v0.4.1
- MuseScore 4.4.4 (as CLI)
- direnv[^3]

[^1] https://github.com/berquerant/pneutrinoutil
[^2] https://musescore.org/en
[^3] https://github.com/direnv/direnv
