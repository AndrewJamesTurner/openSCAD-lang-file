#!/bin/bash
# Install/update/Uninstall scad.lang

# DEPENDENCIES
# zenity

# Purpose
# Simple Install/uninstall/update openSCAD-lang for gedit

# User experience
# Detect if launched from terminal or GUI
# The user will choose whether to become root or not.
# Then

# If you start it from the terminal with "sudo", it will start with GUI.
# This will need to be fixed

RETURN=$'\n'
OLD_IFS=$IFS
REMOTE_FILE="https://raw.githubusercontent.com/AndrewJamesTurner/openSCAD-lang-file/master/scad.lang"
FILE_NAME="scad.lang"
APP_NAME="openSCAD-lang for gedit"

INSTALLATION_FOLDER=""

function main(){
  detect_installation_folder
  if [[ -f "${INSTALLATION_FOLDER}/${FILE_NAME}" ]]; then
    # File already exists
    # Update or uninstall?
    RESPONSE=$(show_yes_no_message "Do you want to update?")
    printf "\n"
    if [[ "${RESPONSE}" == "0" ]]; then
      update_scad_lang
    else
      RESPONSE=$(show_yes_no_message "Do you want to uninstall?")
      printf "\n"
      if [[ "${RESPONSE}" == "0" ]]; then
        uninstall_scad_lang
      else
        show_info_message "No changes have been made."
      fi
    fi
  else
    # File does not exist
    # Install
    RESPONSE=$(show_yes_no_message "Do you want to install?")
    printf "\n"
    if [[ "${RESPONSE}" == "0" ]]; then
      install_scad_lang
    else
      show_info_message "No changes have been made."
    fi
  fi
}

function install_scad_lang(){
  cd "${INSTALLATION_FOLDER}"
  wget "${REMOTE_FILE}"
  if [[ $? == 0 ]]; then
    show_info_message "Installation completed"
  else
    show_warning_message "Something went wrong"
  fi
}

function update_scad_lang(){
  cd "${INSTALLATION_FOLDER}"
  wget "${REMOTE_FILE}"
  if [[ $? == 0 ]]; then
    show_info_message "Update completed"
  else
    show_warning_message "Something went wrong"
  fi
}

function uninstall_scad_lang(){
  cd "${INSTALLATION_FOLDER}"
  rm "${FILE_NAME}"
  if [[ $? == 0 ]]; then
    show_info_message "Language uninstalled"
  else
    show_warning_message "Something went wrong"
  fi
}

#########################################
# Detect installation folder            #
# CRITIC! Exit if can't find the folder #
#########################################
function detect_installation_folder(){
  IFS=$RETURN
  INSTALLATION_FOLDER=""
  PARENT_FOLDER="/home/`whoami`/.local/share"
  if [[ "`whoami`" == "root" ]]; then
    PARENT_FOLDER="/usr/share"
  fi
  GTKSOURCEVIEW_FOLDERS=($(ls -1 "${PARENT_FOLDER}" | grep -i "gtksourceview"))
  if [[ ${#GTKSOURCEVIEW_FOLDERS[@]} == 0 ]]; then
    show_error_message "No gtksourceview folder found.\nNo changes have been made.\nProgram finished."
    exit
  else
    # gtksourceview folder was found!
    LAST_ITEM=$(( ${#GTKSOURCEVIEW_FOLDERS[@]} - 1 ))
    GTKSOURCEVIEW_FOLDER="${GTKSOURCEVIEW_FOLDERS[${LAST_ITEM}]}"
    INSTALLATION_FOLDER="${PARENT_FOLDER}/${GTKSOURCEVIEW_FOLDER}/language-specs"
    # language-specs folder must exists
    if [[ ! -d "${INSTALLATION_FOLDER}" ]]; then
      mkdir -p "${INSTALLATION_FOLDER}"
    fi
  fi
}

###################
# Start from GUI? #
###################
GUI=false
if [[ $(readlink -f /proc/$(ps -o ppid:1= -p $$)/exe) != $(readlink -f "$SHELL") ]]; then
  GUI=true
fi

# Zenity is installed?
ZENITY_VERSION=$(zenity --version)
ERR_ZENITY=$?

################################
# Show message with/out zenity #
################################
MESSAGE_RESPONSE=""
function _show_message() # Core function for messages
{
  MESSAGE_RESPONSE=""
  TYPE="$1"
  MESSAGE="$2"
  if [[ ${GUI} == true ]] && [[ ${ERR_ZENITY} == 0 ]]; then
    zenity --"${TYPE}" --ellipsize --title="${APP_NAME}" --text="${MESSAGE}"
    if [[ $? == 0 ]] && [[ "${TYPE}" == "question" ]]; then
      MESSAGE_RESPONSE=0
    else
      MESSAGE_RESPONSE=1
    fi
  else
    TYPE=$(to_uppercase "${TYPE}")
    
    if [[ "${TYPE}" == "QUESTION" ]]; then
      while : ; do
        read -n 1 -p "${MESSAGE} [Y/N]" MESSAGE_RESPONSE
        printf "\n"
        MESSAGE_RESPONSE=$(to_uppercase "${MESSAGE_RESPONSE}")
        if [[ "${MESSAGE_RESPONSE}" == "Y" ]] || [[ "${MESSAGE_RESPONSE}" == "N" ]]; then
          if [[ "${MESSAGE_RESPONSE}" == "Y" ]]; then
            MESSAGE_RESPONSE=0
          else
            MESSAGE_RESPONSE=1
          fi
          break
        fi
      done
    else
      printf "${TYPE}: ${MESSAGE}\n"
    fi
  fi
  echo "${MESSAGE_RESPONSE}"
}

function show_info_message()
{
  _show_message "info" "$1"
}

function show_warning_message()
{
  _show_message "warning" "$1"
}

function show_error_message()
{
  _show_message "error" "$1"
}

# RETURN
# 0: if response is true
# 1: if response is false | error occours
function show_yes_no_message()
{
  echo $(_show_message "question" "$1")
}

function to_lowercase()
{
  echo "$1" | tr '[:upper:]' '[:lower:]'
}

function to_uppercase()
{
  echo "$1" | tr '[:lower:]' '[:upper:]'
}

##########################
# LOCALIZATION WITH      #
# zen-sudo LITE EMBEDDED #
##########################

# Default language: en_US
# zen-sudo strings
ZEN_SUDO_NAME="zen-sudo LITE EMBEDDED"
THIS_COMMAND_REQUIRE_ROOT_PERMISSIONS="This command require root permissions"
WORKING_FOLDER="Working folder"
COMMAND_NOT_EXECUTED="Command not executed."

##########################
# zen-sudo LITE EMBEDDED #
##########################

if [[ `whoami` != "root" ]] && [[ ${GUI} == true ]]; then
  if [[ "`cat /proc/${PPID}/comm`" == "sudo" ]]; then       # If called from sudo...
    COMMAND="$(cat /proc/${PPID}/cmdline | tr '\0' ' ')"    # Detect command line
    #          └────────────┬──────────┘   └────┬────┘
    #                       │                   └───────────→ Translate all zero bytes with spaces
    #                       └───────────────────────────────→ Print comand line from parent process
    zenity --entry \
    --hide-text \
    --title="${ZEN_SUDO_NAME}" \
    --text="${THIS_COMMAND_REQUIRE_ROOT_PERMISSIONS}:\
    \n${COMMAND}\
    \n\n${WORKING_FOLDER}:\
    \n${PWD}\
    \n\n$1"                                                 # Showing request with command and current folder
  else                                                      # If called from user...
    RESPONSE=$(show_yes_no_message "Hello `whoami`! Do you want to switch to root?")
    if [[ "${RESPONSE}" == "0" ]]; then
      # yes
      export SUDO_ASKPASS="$(realpath "$0")"                  # I am the guy for the GUI
      sudo -A "$(realpath "$0")" "$@"                         # Request root permissions to myself
      SUCCESS="$?"                                            # Read result of sudo: 0 should be great
      if [[ "${SUCCESS}" != "0" ]]; then                      # If wrong with sudo...
        zenity --warning\
         --ellipsize\
         --title="${ZEN_SUDO_NAME}" \
         --text="${COMMAND_NOT_EXECUTED}"
      fi
    else
      main
    fi
  fi
else
  main
fi
