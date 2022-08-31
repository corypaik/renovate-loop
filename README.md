# renovate loop minimal reproduction

This repository contains a minimal reproduction of an infinite loop issue between renovate and a ci bot's fixup commits. This readme covers basic details about the issue and files in the repository.

## Overview

Not all files are relevant as some are only required to get the buildkite ci bot pushing fixes to GitHub. The relevant portions are highlighted below.

```
├── .buildkite                        <- Buildkite pipeline config
│   ...
│
├── scripts
│   └── ci
│       └── update_pip_lockfiles.sh   <- CI script to update the lockfiles
├── third_party
│   ├── BUILD
│   ├── requirements.in               <- Pinned requirement is here
│   └── requirements.txt              <- Lockfile is here
├── .gitignore
├── renovate.json                     <- Renovate configuration
├── README.md
└── WORKSPACE
```

This repository contains one example package that causes the issue, all others have been removed or disabled. The pull request for this reproduction is [#2](https://github.com/corypaik/renovate-loop/pull/2). There is also a public [Buildkite](https://buildkite.com/corypaik/renovate-loop) available for reference.

If you wish to run this locally, you can run the following command to update the requirements lockfile (requires [Bazel](https://bazel.build/)).

```sh
git clone https://github.com/corypaik/renovate-loop.git
cd renovate-loop
bazel run //third_party:requirements.update
```

## Summary of the Issue

So far I have only observed this with python packages, but I do not have a similar procedure for other dependencies.

The process is something like this:

1. Renovate updates package `x` and commits to the repository, which triggers the first ci run.
2. The repository uses lock files with `pip-compile`, so before running builds and tests, the ci agent runs a script to update the lockfiles. This takes care of resolving dependency changes of `x`. If any changes were made, the ci bot commits them as a fixup commit (`git commit --fixup HEAD`) and pushes it to GitHub.
3. The new commit triggers a second ci run. This time, the check should pass and move on.

The ci bot is registered as a `gitIgnoredAuthor`, but in the past renovate would only overwrite the changes if the `main` branch was updated (I have `rebaseWhen` as `behind-base-branch`). Currently, every time the ci bot commits a change renovate seems to overwrite it the next time it runs. This means the repository update process is effectively stuck in an infinite loop. I'm not sure exactly what triggers this behavior and it's been a while since it worked, but it seems to have been around the same time renovate changed email names from `bot@renovateapp.com` to `29139614+renovate[bot]@users.noreply.github.com`. I recall having to manually rebase the existing branches as they were marked as modified.
