#!/bin/bash

printf "\033[0;36m================================================================================================================> Condition 1: Develop environment \033[0m\n"
printf "\033[0;32m============> Adding SSH deploy key \033[0m\n"
git config --global core.sshCommand "ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"
eval `ssh-agent -s`
echo "$4" > ssh-key
chmod 400 ssh-key
ssh-add ssh-key

if [[ "$GITOPS_BRANCH" == "develop" ]]; then
    printf "\033[0;36m================================================================================================================> Condition 1: Develop environment \033[0m\n"
    printf "\033[0;32m============> Cloning $6 - Branch: develop \033[0m\n"
    git clone $7 -b develop
    cd $6
    git config --local user.email "action@github.com"
    git config --local user.name "GitHub Action"
    echo "Repo $6 cloned!!!"

    printf "\033[0;32m============> Develop branch Kustomize step - DEV Overlay \033[0m\n"
    cd k8s/$1/overlays/dev
    sed -i "s/version:.*/version: '$RELEASE_VERSION'/g" datadog-env-patch.yaml
    kustomize edit set image IMAGE=$2/$1:$RELEASE_VERSION
    echo "Done!!"

    printf "\033[0;32m============> Git push: Branch develop \033[0m\n"
    cd ../..
    git commit -am "$3 has Built a new version: $RELEASE_VERSION"
    git push origin develop

    printf "\033[0;32m============> Merge develop in to homolog branch \033[0m\n"
    git checkout homolog
    git merge develop
    git push origin homolog

elif [[ "$GITOPS_BRANCH" == "homolog" ]]; then
    printf "\033[0;36m================================================================================================================> Condition 2: Homolog environment \033[0m\n"
    printf "\033[0;32m============> Cloning $6 - Branch: homolog \033[0m\n"
    git clone $7 -b develop
    cd $6
    git config --local user.email "action@github.com"
    git config --local user.name "GitHub Action"
    echo "Repo $6 cloned!!!"

    printf "\033[0;32m============> Develop branch Kustomize step - HML Overlay \033[0m\n"
    cd k8s/$1/overlays/homolog
    sed -i "s/version:.*/version: '$RELEASE_VERSION'/g" datadog-env-patch.yaml
    kustomize edit set image IMAGE=$2/$1:$RELEASE_VERSION
    echo "Done!!"

    printf "\033[0;32m============> Git commit and push \033[0m\n"
    cd ../..
    git commit -am "$3 has Built a new version: $RELEASE_VERSION"
    git push origin develop

    printf "\033[0;32m============> Merge develop in to homolog branch \033[0m\n"
    git checkout homolog
    git merge develop
    git push origin homolog

elif [[ "$GITOPS_BRANCH" == "homolog" ]]; then
    printf "\033[0;36m================================================================================================================> Condition 3: New release (HML and PRD environment) \033[0m\n"
    printf "\033[0;32m============> Cloning $6 - Branch: $GITOPS_BRANCH \033[0m\n"
    git clone $7 -b develop
    cd $6
    git config --local user.email "action@github.com"
    git config --local user.name "GitHub Action"
    echo "Repo $6 cloned!!!"

    printf "\033[0;32m============> Develop branch Kustomize step - HML Overlay \033[0m\n"
    cd k8s/$1/overlays/homolog
    sed -i "s/version:.*/version: '$RELEASE_VERSION'/g" datadog-env-patch.yaml
    kustomize edit set image IMAGE=$2/$1:$RELEASE_VERSION
    echo "Done!!"

    printf "\033[0;32m============> Develop branch Kustomize step - PRD Overlay \033[0m\n"
    cd ../prod
    sed -i "s/version:.*/version: '$RELEASE_VERSION'/g" datadog-env-patch.yaml
    kustomize edit set image IMAGE=$2/$1:$RELEASE_VERSION
    echo "Done!!"

    printf "\033[0;32m============> Git commit and push: Branch develop \033[0m\n"
    cd ../..
    git commit -am "$3 has Built a new version: $RELEASE_VERSION"
    git push origin develop

    printf "\033[0;32m============> Merge develop in to homolog branch \033[0m\n"
    git checkout homolog
    git merge develop
    git push origin homolog

    printf "\033[0;32m============> Open PR: homolog -> main \033[0m\n"
    export GITHUB_TOKEN=$5
    gh pr create --head homolog --base main -t "GitHub Actions: Automatic PR opened by $3 - $RELEASE_VERSION" --body "GitHub Actions: Automatic PR opened by $3 - $RELEASE_VERSION"

fi
