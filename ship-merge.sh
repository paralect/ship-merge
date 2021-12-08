#!/usr/bin/env bash
set -e
shopt -s dotglob

template_repo="https://github.com/paralect/ship-merge"

deploy_dir="deploy-setup"
deploy_repo="https://github.com/paralect/ship-deploy"

api_dotnet=".NET API Starter"
api_dotnet_dir="api"
api_dotnet_repo="https://github.com/paralect/dotnet-api-starter"

api_koa="Koa API Starter"
api_koa_dir="api"
api_koa_repo="https://github.com/paralect/koa-api-starter"

web_next="Next Web Starter"
web_next_dir="web"
web_next_repo="https://github.com/paralect/next-starter"

web_vue="Vue Web Starter"
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
  printf "\n? Select web framework (Next or Vue): "
  read api
  if [[ "$api" = Next ]]; then
    services+=("$web_next")
  elif [[ "$api" = Vue ]]; then
    services+=("$web_vue")
  else
    printf "! Try again\n"
    read_web_framework
  fi
}

function read_platform() {
  printf "\n? Select platform (Digital Ocean or AWS): "
  read api
  if [[ "$api" = 'Digital Ocean' ]]; then
    platform="$api"
    platform_dir=digital-ocean
  elif [[ "$api" = AWS ]]; then
    platform="$api"
    platform_dir=aws
  else
    printf "! Try again\n"
    read_platform
  fi
}

read_project_name

platform=""
services=()

read_api_framework
read_web_framework
read_platform

filesToRemove=(
  "docker-compose.yml"
  "docker-compose.test.yml"
)

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
printf "  Platform\n"
printf "    $platform\n"

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
    "$api_dotnet")
      installService "$service" "$api_dotnet_repo" "$api_dotnet_dir"
    ;;
    "$api_koa")
      installService "$service" "$api_koa_repo" "$api_koa_dir"
    ;;
    "$web_next")
      installService "$service" "$web_next_repo" "$web_next_dir"
    ;;
    "$web_vue")
      installService "$service" "$web_vue_repo" "$web_vue_dir"
    ;;
  esac
done

installService "$platform" "$deploy_repo" "$deploy_dir"

mv ./"$deploy_dir"/"$platform_dir" ./deploy
mv ./"$deploy_dir"/.gitignore ./deploy
mv ./"$deploy_dir"/README.md ./deploy
mv ./deploy/.github .

rm -rf "$deploy_dir"

npm install
git init
git add .
git commit -m "initial commit"
git branch -M main
npx husky install

printf "\n! Installation completed\n"
