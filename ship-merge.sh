#!/usr/bin/env bash
set -e

INCLUDE_DEPLOY=true
INCLUDE_API=true
INCLUDE_WEB=true
INCLUDE_SHARED=true

template_repo="https://github.com/paralect/ship-merge"

deploy="Deploy"
deploy_dir="deploy"
deploy_repo="https://github.com/paralect/ship-deploy"

shared_dir="shared"

api_dotnet=".NET API Starter"
api_dotnet_dir="api"
api_dotnet_repo="https://github.com/paralect/dotnet-api-starter"

api_koa="Koa API Starter"
api_koa_dir="api"
api_koa_repo="https://github.com/paralect/koa-api-starter"

web_react="React Web Starter"
web_react_dir="web"
web_react_repo="https://github.com/paralect/koa-react-starter"

web_vue="Vue.js Web Starter"
web_vue_dir="web"
web_vue_repo="https://github.com/paralect/vue-starter"

function read_project_name() {
  printf "\n? Enter project name: "
  read project_name
  if [[ -z "$project_name" ]]; then
    printf "! Project name cannot be empty\n"
    read_project_name
  fi
}

read_project_name

services=()

function read_api_framework() {
  printf "\n? Select API framework (Koa or .NET): "
  read api
  if [[ "$api" = Koa ]]; then
    services+=("$api_koa")
  elif [[ "$api" = .NET ]]; then
    services+=("$api_dotnet")
  else
    printf "! Try again\n"
    read_api_framework
  fi
}

function read_web_framework() {
  printf "\n? Select web framework (React or Vue.js): "
  read api
  if [[ "$api" = React ]]; then
    services+=("$web_react")
  elif [[ "$api" = Vue.js ]]; then
    services+=("$web_vue")
  else
    printf "! Try again\n"
    read_web_framework
  fi
}

read_api_framework
[[ $INCLUDE_WEB = true ]] && read_web_framework

[[ $INCLUDE_DEPLOY = true ]] && services+=("$deploy")

filesToRemove=( ".drone.yml"
                "docker-compose.yml"
                "docker-compose.test.yml"
                "LICENSE"
                "CHANGELOG.md"
                "CODE_OF_CONDUCT.md"
                ".all-contributorsrc"
                "CONTRIBUTING.md"
                "SHIP_README.md" )

function installService() {
  service="$1"
  repo="$2"
  dir="$3"

  printf "\n! Installing $service..."
  mkdir "$dir"
  cd "$dir"
  git clone --quiet "$repo" .
  rm -rf .git "${filesToRemove[@]}"
  cd ../
}

printf "\n"
printf "! Setup Info\n"
printf "  Project name\n"
printf "    $project_name\n"
printf "  Services\n"
printf "    %s\n" "${services[@]}"

mkdir $project_name
cd $project_name
git clone --quiet "$template_repo" .
rm -rf .git ship-merge.sh
echo "# $project_name" > README.md

for i in docker-compose*; do
  perl -i -pe"s/ship/$project_name/g" $i
done

for service in "${services[@]}"; do
  case "$service" in
    "$deploy")
      installService "$service" "$deploy_repo" "$deploy_dir"
    ;;
    "$api_dotnet")
      installService "$service" "$api_dotnet_repo" "$api_dotnet_dir"
    ;;
    "$api_koa")
      installService "$service" "$api_koa_repo" "$api_koa_dir"
      cd ..
      if [[ $INCLUDE_SHARED = true ]]; then
        cp -R shared $project_name
      fi
      cd $project_name
    ;;
    "$web_react")
      installService "$service" "$web_react_repo" "$web_react_dir"
    ;;
    "$web_vue")
      installService "$service" "$web_vue_repo" "$web_vue_dir"
    ;;
  esac
done

printf "\n! Installation completed\n"
