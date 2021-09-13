#!/bin/sh

# Colors
RED="\033[0;31m"
GREEN="\033[0;32m"
BOLD_CYAN="\033[1;96m"
COLOR_OFF="\033[0m"

print_red() {
  TEXT_TO_PRINT=$1
  printf "$RED$(echo $TEXT_TO_PRINT)$COLOR_OFF"
}

print_cyan() {
  TEXT_TO_PRINT=$1
  printf "$BOLD_CYAN$(echo $TEXT_TO_PRINT)$COLOR_OFF"
}

print_green() {
  TEXT_TO_PRINT=$1
  printf "$GREEN$(echo $TEXT_TO_PRINT)$COLOR_OFF"
}

wait_to_continue() {
  echo
  print_cyan 'Press Enter to continue or Ctrl-C to exit'
  read -r
}

install_xcode() {
  print_cyan 'Installing XCode'
  echo "When you press 'Enter' a dialog will pop up with several options. Click the 'Install' button and wait."
  echo "Once the process completes, come back here and we will proceed with the next step."

  xcode-select --install 2>&1

  # wait for xcode...
  while sleep 1; do
    xcode-select --print-path >/dev/null 2>&1 && break
  done

  echo
}

# TODO: Implement this - with no keys
install_aws_cli() {

  print_cyan 'Installing the AWS CLI'

  # AWS and SAM CLI
  print_cyan 'The following is the logged in user'
  printf "\n\n"
  logname

  printf "\n\nEnter the local machine username that you wish the AWS CLI to be associated with -> "
  read username
  printf "\n\nInstalling as $username"
  printf "\n\nWhile this is running, ensure you have your AWS Access Key ID and AWS Secret Access Key ready to go. \n\n"
  sudo -u $username brew tap aws/tap
  sudo -u $username brew install awscli aws-sam-cli

  # Configure AWS CLI
  printf "\n Configuring the AWS CLI"
  printf "\n\n"
  aws configure
}

install_vs_code() {

  print_cyan 'Installing VS Code'
  echo

  mkdir ~/temp

  curl -sf -L https://go.microsoft.com/fwlink/?LinkID=620882 -o ~/temp/VSCode-darwin-stable.zip

  unzip -q ~/temp/VSCode-darwin-stable.zip

  mkdir ~/temp/VS_Code

  mv Visual\ Studio\ Code.app/ ~/temp/VS_Code

  cp -R ~/temp/ /Applications/

  rm -r ~/temp/

  # Creating symlink
  sudo ln -s /Applications/Visual\ Studio\ Code.app/Contents/Resources/app/bin/code /usr/local/bin/code
}

install_brew() {
  print_cyan 'Installing Home Brew a package manager for MacOS'
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  if [[ "$(uname -m)" == "arm64" ]]; then
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >>$HOME/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
}

setup_ssh_keys() {
  print_cyan 'Setting up SSH public/private key pair'
  echo
  echo "This key is like a fingerprint for you on your laptop."
  echo "We'll use this key for connecting to GitHub without having to enter a password."

  read -p $'Enter your GitHub username: ' USERSNAME
  read -p $'Enter the your GitHub email: ' GITHUBEMAIL
  while [[ ! ($GITHUBEMAIL =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$) ]]; do
    print_red 'Invalid email'
    print_red 'Please check and re-enter your email when prompted'
    read -p $'Enter the your github email: ' GITHUB_EMAIL
  done

  git config --global user.name "$USERSNAME"
  git config --global user.email $GITHUB_EMAIL

  ssh-keygen -trsa -b4096 -C GITHUB_EMAIL -f "$HOME/.ssh/id_rsa" -N ''

  pbcopy <"$HOME/.ssh/id_rsa.pub"

  echo "We've copied your ssh key to the clipboard for you."
  echo "Now, we are going to take you to the GitHub website where you will add it as one of your keys."
  echo 'Click the "New SSH key" button'
  echo 'Give the key a title (for example: Macbook-Pro) and paste the key into the textarea'
  echo 'Once pasted, click the big green "Add SSH key" button'
  wait_to_continue
  open https://github.com/settings/ssh
  wait_to_continue
}

install_node() {
  echo
  print_cyan 'Installing NVM - Node Version Manager'
  echo
  echo 'This will allow us to run JavaScript from the command line, access package managers like npm and yarn.'
  echo 'NVM allows for easy swapping of versions of Node, rather than installing an explicit version directly.'
  printf "\n\n"
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.38.0/install.sh | bash
  printf "\n\n"
  source ~/.bash_profile
  . ~/.nvm/nvm.sh

  nvm install 14.15.0

  npm install --global yarn
}

setup_git(){
  # setup the global gitignore file
  print_cyan 'Setting up global .gitignore'
  echo
  if git config --global -l | grep core.excludesfile >/dev/null; then
    echo 'It looks like you already have a global gitignore file setup (core.excludesfile).'
    echo 'We will not modify it, but make sure you have the following values in it:'
    echo
    echo ' - .DS_Store'
    echo ' - node_modules'
    echo ' - dist'
    echo ' - build'
    echo ' - .webpack'
    echo ' - .serverless'
    echo
  else
    {
      echo '.DS_Store'
      echo '.vscode'
      echo 'node_modules'
      echo 'dist'
      echo 'build'
      echo '.webpack'
      echo '.serverless'
    } >>~/.gitignore_global
    git config --global core.excludesfile ~/.gitignore_global
  fi
  # set the default git editor to nano
  print_cyan 'Setting up git preferred editor to "nano"'
  echo
  if git config --global core.editor >/dev/null; then
    echo 'It looks like you already have a preferred editor setup for git'
    echo 'We will not modify this.'
    echo
  else
    git config --global core.editor nano
  fi
}

script_results() {

  HAS_ANY_ERROR=false
  BREW_HAD_ERRORS=false
  NODE_HAD_ERRORS=false

  tput setaf 1
  command -v brew >/dev/null 2>&1 || {
    BREW_HAD_ERRORS=true
    HAS_ANY_ERROR=true
  }
  command -v node >/dev/null 2>&1 || {
    NODE_HAD_ERRORS=true
    HAS_ANY_ERROR=true
  }

  tput sgr0

  if [ "$HAS_ANY_ERROR" = false ]; then
    tput setaf 2
    echo "All services were installed successfully."
    tput sgr0
  else
    tput setaf 3
    echo "Not all services were installed."
    echo "Results are below"
    tput sgr0
    if [ "$BREW_HAD_ERRORS" = false ]; then
      tput setaf 2
      echo "BREW was installed successfully."
      tput sgr0
    else
      tput setaf 1
      echo "BREW was not able to be installed. Installation page can be found here https://brew.sh"
      tput sgr0
    fi
    if [ "$NODE_HAD_ERRORS" = false ]; then
      tput setaf 2
      echo "NODE was installed successfully."
      tput sgr0
    else
      tput setaf 1
      echo "NODE was not able to be installed. Installation page can be found here https://formulae.brew.sh/formula/node#default"
      tput sgr0
    fi
  fi

}

setup() {
  touch ~/.bash_profile
  source ~/.nvm/nvm.sh

  print_cyan 'Running setup'
  echo
  echo 'This script will install: '
  echo '  - Xcode tools'
  echo '  - Homebrew'
  echo '  - NVM and Node'
  echo '  - VS Code'

  echo
  print_cyan '***Note***'
  echo
  printf "If you have already setup any of the above on your computer, this script $(print_cyan 'will not') attempt to reinstall them\n"
  printf "During this process you may be asked for your password several times. $(print_cyan 'This is the password you use to log into your computer.')"

  echo
  echo 'When you type it in, you will not see any output in the terminal, this is normal.'
  echo

  # check for the tool then run the relevant installer functions if they do not exist
  xcode-select --print-path >/dev/null 2>&1 || install_xcode
  which brew >/dev/null 2>&1 || install_brew
  [ -f "$HOME/.ssh/id_rsa" ] || setup_ssh_keys
  ls /Applications/Visual\ Studio\ Code.app >/dev/null 2>&1 || install_vs_code
  command -v nvm >/dev/null || install_node

  setup_git

  echo
  print_cyan "We've gotten everything setup and you should be ready to go!"
  printf "\n\n"
  script_results
}

setup
