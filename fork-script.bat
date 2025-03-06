git remote set-url origin %1
 
git filter-branch -f --env-filter "GIT_AUTHOR_NAME='kamidev628'; GIT_AUTHOR_EMAIL='marcin.nowak.0628@proton.me'; GIT_COMMITTER_NAME='kamidev628'; GIT_COMMITTER_EMAIL='marcin.nowak.0628@proton.me';"
 
git push --force origin master