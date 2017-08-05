#!/bin/bash

set -e

versions=$(npm view @angular/cli versions --json)

versions=${versions//\"/}
versions=${versions//\[/}
versions=${versions//\]/}
versions=${versions//\,/}

versions=(${versions})

blocklist=(1.0.0-beta.28.3 1.0.0-beta.29 1.0.0-beta.30 1.0.0-beta.31 1.0.0-beta.32
1.0.0-beta.32.2 1.0.0-beta.32.3 1.0.0-beta.33 1.0.0-beta.33.1
1.0.0-rc.0 1.0.0-rc.1 1.0.0-rc.2 1.0.0-rc.3 1.0.0-rc.4
1.3.0-rc.4
1.4.0-rc.0
1.5.0-beta.0 1.5.0-beta.1 1.5.0-beta.2
6.0.4
7.0.0-beta.0 7.0.0-beta.1
10.0.0-rc.1)

lastVersion="1.0.0"
rebaseNeeded=false

for version in "${versions[@]}"
do

  if [[ " ${blocklist[@]} " =~ " ${version} " ]]
  then
    echo "Skipping blocklisted ${version}"
    continue
  fi

  if [ `git branch --list ${version}` ] || [ `git branch --list --remote origin/${version}` ]
  then
    echo "${version} already generated."
    git checkout ${version}
    if [ ${rebaseNeeded} = true ]
    then
      git rebase --onto ${lastVersion} HEAD~ ${version} -X theirs
      diffStat=`git --no-pager diff HEAD~ --shortstat`
      git push origin ${version} -f
      diffUrl="[${lastVersion}...${version}](https://github.com/cexbrayat/angular-cli-diff/compare/${lastVersion}...${version})"
      git checkout master
      # rewrite stats in README after rebase
      sed -i.bak -e "/^${version}|/ d" README.md && rm README.md.bak
      sed -i.bak -e 's/----|----|----/----|----|----\
NEWLINE/g' README.md && rm README.md.bak
      sed -i.bak -e "s@NEWLINE@${version}|${diffUrl}|${diffStat}@" README.md && rm README.md.bak
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
  flags="--skip-install --no-interactive"
  # strict is only applicable for version >=10.0.0-next.3
  if [ `npx semver ${version} --include-prerelease --range ">=10.0.0-next.3"` ]
  then
    flags="${flags} --strict"
  fi
  npx @angular/cli@${version} new ponyracer ${flags}
  git add ponyracer
  git commit -am "chore: version ${version}"
  diffStat=`git --no-pager diff HEAD~ --shortstat`
  git push origin ${version} -f
  git checkout master
  diffUrl="[${lastVersion}...${version}](https://github.com/cexbrayat/angular-cli-diff/compare/${lastVersion}...${version})"
  # insert a row in the version table of the README
  sed -i.bak "/^${version}|/ d" README.md && rm README.md.bak
  sed -i.bak 's/----|----|----/----|----|----\
NEWLINE/g' README.md && rm README.md.bak
  sed -i.bak "s@NEWLINE@${version}|${diffUrl}|${diffStat}@" README.md && rm README.md.bak
  # commit
  git commit -a --amend --no-edit
  git checkout ${version}
  lastVersion=${version}

done

git checkout master
git push origin master -f
