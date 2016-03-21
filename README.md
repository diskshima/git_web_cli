# git_web_cli - CLI for managing Git remote repositories

git_web_cli is a CLI (Command Line Interface) to manage remote repositories.

## Features

It currently supports the below features:

- Listing issues.
- Listing pull requests (merge requests on BitBucket)
- Creating issues.
- Creating pull requests.
- Opening issues or pull requests in the browser.
- Closing issues.

Supports GitHub, BitBucket and GitLab.


## Command Line Examples

#### Listing Issues

```bash
$ gw issues      # (or just 'gw is')
25: Better support for specifying configurations
24: Close pull requests
15: Support specifying credential file
14: Write README
10: Add help (--help)
```

#### Listing Pull Requests

```bash
$ gw pull-requests     # (or just 'gw prs')
15: Update README
```

#### Creating a Issue

```bash
$ gw issue --title 'Major Bug that needs fixing'
  or
$ gw i --title 'Major Bug that needs fixing'
```

#### Creating a Pull Request

```bash
$ gw pull-request --title 'My Next Big Feature'
  or
$ gw pr --title 'My Next Big Feature'
```

#### Closing a Issue

The below closes issue #15.

```bash
$ gw close issue 15      # (or just 'gw close i 15')
```

#### Opening a Issue or Pull Request in the Browser

```bash
$ gw open issue 15           # (or just 'gw o i 15')
$ gw open pull-request 5     # (or just 'gw o pr 5')
```

## Contributing

1. Fork the repo.
1. Create a branch with a descriptive name.
1. Create a pull request to this repo's master branch.

## License

Released under the MIT License: http://www.opensource.org/licenses/mit-license.php
