# Contributing to OpenCollar

We welcome contributions to OpenCollar of any kind including documentation,
organization,bug reports, issues, feature requests, feature implementations,
pull requests, answering questions in the group / discord, helping to manage issues, etc.

The OpenCollar community and maintainers are active and helpful, and the project benefits greatly from this activity.

*Changes to the codebase **and** related documentation, e.g. for a new feature, should still use a single pull request.*

## Table of Contents

* [Asking Support Questions](#asking-support-questions)
* [Reporting Issues](#reporting-issues)
* [Submitting Patches](#submitting-patches)
  * [Code Contribution Guidelines](#code-contribution-guidelines)
  * [Git Commit Message Guidelines](#git-commit-message-guidelines)
  * [Fetching the Sources From GitHub](#fetching-the-sources-from-github)
  * [Linting and Testing OpenCollar with Your Changes](#Linting-and-Testing-OpenCollar-with-Your-Changes)

## Asking Support Questions

We have active [discussion channels](https://discord.gg/WUmBMemYqf) where users and developers can ask questions.
Please don't use the GitHub issue tracker to ask general questions.

## Reporting Issues

If you believe you have found a defect in OpenCollar or its documentation, use
the GitHub issue tracker to report
the problem to the maintainers. When reporting the issue, please provide the version of OpenCollar in use (Help > About).

- [OpenCollar Issues · OpenCollarTeam/OpenCollar](https://github.com/OpenCollarTeam/OpenCollar/issues)
- [OpenCollar Documentation · OpenCollarTeam/opencollarteam.github.io](https://github.com/OpenCollarTeam/opencollarteam.github.io)

## Code Contribution

As OpenCollar's user base continues to grow, any new functionality must:

* be useful to many.
* fit naturally into _what OpenCollar does best._
* strive not to break existing functionality
* close or update an open [OpenCollar Issue](https://github.com/OpenCollarTeam/OpenCollar/issues)

If the feature is of some complexity, the contributor is expected to maintain and support the new feature in the future (answer questions in-world or in discord, fix any bugs etc.).

It is recommended to open up a discussion on the [Issues Tab](https://github.com/OpenCollarTeam/OpenCollar/issues) to get feedback on your idea before you begin. 

Any non-trivial code change needs to update an open [issue](https://github.com/OpenCollarTeam/OpenCollar/issues). A non-trivial code change without an issue reference with one of the labels `bug` or `enhancement` will not be merged.

**Bug fixes are, of course, always welcome.**

## Submitting Patches

The [OpenCollar](https://github.com/OpenCollarTeam/OpenCollar) Team welcomes all contributors and contributions regardless of skill or experience level. If you are interested in helping with the project, we will help you with your contribution.

### Code Contribution Guidelines

Because we want to create the best possible product for our users and the best contribution experience for our developers, we have a set of guidelines which ensure that all contributions are acceptable. The guidelines are not intended as a filter or barrier to participation. If you are unfamiliar with the contribution process, the [OpenCollar](https://github.com/OpenCollarTeam/OpenCollar) team will help you and teach you how to bring your contribution in accordance with the guidelines.

To make the contribution process as seamless as possible, we ask for the following:

* Go ahead and fork the project and make your changes.  We encourage pull requests to allow for review and discussion of code changes.
* When you’re ready to create a pull request, be sure to:
    * Have test cases for the new code. If you have questions about how to do this, please ask in your pull request.
    * Add documentation if you are adding new features or changing functionality.  The docs site lives on [opencollarteam.github.io](https://github.com/OpenCollarTeam/opencollarteam.github.io).
    * Squash your commits into a single commit. `git rebase -i`. It’s okay to force update your pull request with `git push -f`.
    * Ensure that `lslint` succeeds. [GitHub Actions](https://github.com/OpenCollarTeam/OpenCollar/actions)  will fail the build if `lslint` fails.
    * Follow the **Git Commit Message Guidelines** below.

### Git Commit Message Guidelines

This [blog article](http://chris.beams.io/posts/git-commit/) is a good resource for learning how to write good commit messages,
the most important part being that each commit message should have a title/subject in imperative mood starting with a capital letter and no trailing period:
*"Return error on wrong use of the Paginator"*, **NOT** *"returning some error."*

Also, if your commit references one or more GitHub issues, always end your commit message body with *See #1234* or *Fixes #1234*.
Replace *1234* with the GitHub issue ID. The last example will close the issue when the commit is merged into *master*.

Sometimes it makes sense to prefix the commit message with the package name (or docs folder) all lowercased ending with a colon.
That is fine, but the rest of the rules above apply.
So it is "meta: Add new contributor guidelines", not "this adds new contributor guidelines", and "docs: Document emoji", not "doc: document emoji."

Please use a short and descriptive branch name, e.g. **NOT** "patch-1". It's very common but creates a naming conflict each time when a submission is pulled for a review.

Use the following sentence as a guide for writing the commit message:
`If applied, this commit will [your text]`



An example:

```text
meta: Compile LSLint on every workflow dispatch

Remove static linking of lslint binaries, rather clone and build the tool automatically on execution.

PR-URL: #502
```

### Linting and Testing OpenCollar with Your Changes

OpenCollar uses [lslint](https://github.com/Makopo/lslint) to check the syntactic and semantic validity of the code. Additionally, you should test your changes in-world and make sure that no changes modify any other, unrelated component.

Download [lslint from the releases page](https://github.com/Makopo/lslint/releases)

To lint OpenCollar:

```bash
./run_lslint.sh /path/to/lslint/binary
```