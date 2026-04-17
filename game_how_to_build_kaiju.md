## download the repo and dependencies
gh repo clone KaijuEngine/kaiju
git submodule update --init --recursive

## install vulkan
brew install molten-vk

## install golang
skip ...

## config golang CGO_LDFLAGS
go env -w CGO_LDFLAGS='-O2 -g -L/opt/homebrew/lib'

## .bashrc: export library search path
export DYLD_LIBRARY_PATH=$DYLD_LIBRARY_PATH:/opt/homebrew/lib
sourc ~/.bashrc

## build kaiju
cd kaiju/src
go build -tags='debug,editor' -o ../ ./

## run kaiju
./kaijuengine.com
