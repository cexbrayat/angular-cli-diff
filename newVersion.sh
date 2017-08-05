#!/bin/bash

versions=$(npm view @angular/cli versions)

versions=${versions//\'/}
versions=${versions//\[/}
versions=${versions//\]/}
versions=${versions//\,/}

versions=(${versions})

blacklist=(1.0.0-beta.28.3 1.0.0-beta.29 1.0.0-beta.30 1.0.0-beta.31 1.0.0-beta.32
1.0.0-beta.32.2 1.0.0-beta.32.3 1.0.0-beta.33 1.0.0-beta.33.1
1.0.0-rc.0 1.0.0-rc.1 1.0.0-rc.2 1.0.0-rc.3 1.0.0-rc.4
1.3.0-rc.4
1.5.0-beta.0 1.5.0-beta.1 1.5.0-beta.2)

lastVersion="1.0.0"
rebaseNeeded=false

for version in "${versions[@]}"
do

  if [[ " ${blacklist[@]} " =~ " ${version} " ]]
  then
    echo "Skipping blacklisted ${version}"
    continue
  fi

  if [ `git branch --list ${version} ` ]
  then
    echo "${version} already generated."
    git checkout ${version}
    if [ ${rebaseNeeded} = true ]
    then
      git rebase --onto ${lastVersion} head~ ${version} -X theirs
      diffStat=`git --no-pager diff head~ --shortstat`
      git push origin ${version} -f
      diffUrl="[${lastVersion}...${version}](https://github.com/cexbrayat/angular-cli-diff/compare/${lastVersion}...${version})"
      git checkout master
      # rewrite stats in README after rebase
      sed -i "" "/^${version}|/ d" README.md
      sed -i '' 's/----|----|----/----|----|----\
NEWLINE/g' README.md
      sed -i "" "s@NEWLINE@${version}|${diffUrl}|${diffStat}@" README.md
      git commit -a --amend --no-edit
      git checkout ${version}
    fi
    lastVersion=${version}
    continue
  fi

  echo "Generate ${version}"
  rebaseNeeded=true
  git checkout -b ${version}
  # delete app
  rm -rf ponyracer
  # generate app with new CLI version
  npx @angular/cli@${version} new ponyracer --skip-install
  git add ponyracer
  git commit -am "chore: version ${version}"
  diffStat=`git --no-pager diff head~ --shortstat`
  git push origin ${version} -f
  git checkout master
  diffUrl="[${lastVersion}...${version}](https://github.com/cexbrayat/angular-cli-diff/compare/${lastVersion}...${version})"
  # insert a row in the version table of the README
  sed -i "" "/^${version}|/ d" README.md
  sed -i '' 's/----|----|----/----|----|----\
NEWLINE/g' README.md
  sed -i "" "s@NEWLINE@${version}|${diffUrl}|${diffStat}@" README.md
  # commit
  git commit -a --amend --no-edit
  git checkout ${version}
  lastVersion=${version}

done

git checkout master
git push origin master -f
