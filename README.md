# renovate loop minimal reproduction

This repository contains a minimal reproduction of an infinite loop issue between renovate and a ci bot's fixup commits. This readme covers basic details about the issue and files in the repository.

## Overview

The bug seems to occur anytime a fixup commit is pushed to one of renovate's branches by a user marked as `gitIgnoredAuthors`. This can be reproduced using the commands below.

```bash
# clone the repository
git clone https://github.com/corypaik/renovate-loop.git
cd renovate-loop

# checkout renovate's branch.
git checkout renovate/datasets-1.x

# make any change and commit as a fixup commit.
touch test.txt
git add test.txt
git commit --fixup HEAD --author 'buildkite[bot] <buildkite-bot@buildkite.com>'
git push
```

Renovate will force push that branch the next time it runs, overwriting the user's commits. Note that this may not happen right away as there is only 1 package and it does not run when the commit is first pushed. It will overwrite the change on any later run of renovate, whether that is triggered based on a another branch being pushed to, or simply requesting for Renovate to run again on this repository using the [Dependency Dashboard](https://github.com/corypaik/renovate-loop/issues/1).

### Other test cases

In order to further isolate the issue, I tried a few different tests. Each one performs the same change (adding an empty file). Changing from using a fixup commit message to a different commit message does not change the observed behavior. This seems to mean that renovate overwrites changes by `gitIgnoredAuthors` even when the branch is up to date, regardless of what the change is. I also found that if `rebaseWhen` is omitted, then we see the expected behavior for `gitIgnoredAuthors`.

| Action                                                                             | Expected Outcome         | Current Outcome          |
| :--------------------------------------------------------------------------------- | :----------------------- | :----------------------- |
| A fixup commit from an author not in `gitIgnoredAuthors`                           | Marked as edited/blocked | Marked as edited/blocked |
| A non-fixup commit from an author not in `gitIgnoredAuthors`                       | Marked as edited/blocked | Marked as edited/blocked |
| A fixup commit from an author in `gitIgnoredAuthors`                               | No Action                | Overwrites changes       |
| A non-fixup commit from an author in `gitIgnoredAuthors`                           | No Action                | Overwrites changes       |
| A fixup commit from an author in `gitIgnoredAuthors` with `rebaseWhen` omitted     | No Action                | No Action                |
| A non-fixup commit from an author in `gitIgnoredAuthors` with `rebaseWhen` omitted | No Action                | No Action                |

## Summary of the Issue

So far I have only observed this with python packages, but I do not have a similar procedure for other dependencies.

The process is something like this:

1. Renovate updates package `x` and commits to the repository, which triggers the first ci run.
2. The repository uses lock files with `pip-compile`, so before running builds and tests, the ci agent runs a script to update the lockfiles. This takes care of resolving dependency changes of `x`. If any changes were made, the ci bot commits them as a fixup commit (`git commit --fixup HEAD`) and pushes it to GitHub.
3. The new commit triggers a second ci run. This time, the check should pass and move on.

The ci bot is registered as a `gitIgnoredAuthor`, but in the past renovate would only overwrite the changes if the `main` branch was updated (I have `rebaseWhen` as `behind-base-branch`). Currently, every time the ci bot commits a change renovate seems to overwrite it the next time it runs. This means the repository update process is effectively stuck in an infinite loop. I'm not sure exactly what triggers this behavior and it's been a while since it worked, but it seems to have been around the same time renovate changed email names from `bot@renovateapp.com` to `29139614+renovate[bot]@users.noreply.github.com`. I recall having to manually rebase the existing branches as they were marked as modified.
