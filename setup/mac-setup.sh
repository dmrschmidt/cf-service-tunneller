echo "Make brew up-to-date"
brew update
brew doctor
brew upgrade

echo "Install jq for cli json parsing"
brew install jq
