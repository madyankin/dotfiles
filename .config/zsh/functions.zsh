# Shell functions.

git-clean-branches() {
  git fetch -p
  git branch -vv | grep gone | awk '{print $1}' | xargs git branch -D
}

g++-run() {
  g++ -lstdc++ -std=c++14 -pipe -O2 -Wall "$1" && ./a.out
}
