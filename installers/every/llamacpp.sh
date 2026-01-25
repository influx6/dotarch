#!/bin/env bash

source $DOTFILES/shell/load_functions

sudo pacman -Sy --noconfirm

sudo pacman -S --noconfirm --needed pciutils base-devel cmake curl \
	base-devel git cmake vulkan-icd-loader vulkan-devel

yay -Sy --noconfirm --needed rocm-hip-sdk rocm-hip-libraries rocm-hip-runtime


mkdir $HOME/apps
cd $HOME/apps
git clone https://github.com/ggml-org/llama.cpp 

cmake llama.cpp -B llama.cpp/build \
    -DBUILD_SHARED_LIBS=OFF  \
		-DGGML_CUDA=ON \
		-DGGML_VULKAN=ON \
		-DGGML_HIPBLAS=ON  


cmake --build llama.cpp/build --config Release -j --clean-first --target llama-cli llama-mtmd-cli llama-server llama-gguf-split

export LLAMA_CPP_BIN="$HOME/apps/llama.cpp/build/bin/"
export PATH="$LLAMA_CPP_BIN:$PATH"

cd -

pip install huggingface_hub hf_transfer
pip install sglang
pip install git+https://github.com/huggingface/transformers.git

git config --global credential.helper store

hf auth login
