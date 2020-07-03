#!/usr/bin/env bash

brew install rustup-init

rustup install stable
rustup install nightly
rustup component add rust-src
rustup run nightly cargo install rustfmt-nightly
