# BbCli - CLI for managing Git remote repositories

BbCli is a CLI (Command Line Interface) to manage remote repositories.

## Features

It currently supports the below features:

- Listing issues.
- Listing pull requests (merge requests on BitBucket)
- Creating issues.
- Creating pull requests.
- Opening issues or pull requests in the browser.
- Closing issues.

Supports GitLab and BitBucket (GitHub is on the way).


## Command Line Examples

#### Listing Issues

```bash
$ bb_cli issues      # (or just 'bb_cli is')
25: Better support for specifying configurations
24: Close pull requests
15: Support specifying credential file
14: Write README
10: Add help (--help)
```

#### Listing Pull Requests

```bash
$ bb_cli pull-requests     # (or just 'bb_cli prs')
15: Update README
```

#### Creating Issues

```bash
$ bb_cli issue --title 'Major Bug that needs fixing'
  or
$ bb_cli i --title 'Major Bug that needs fixing'
```

#### Creating Pull Requests

```bash
$ bb_cli pull-request --title 'My Next Big Feature'
  or
$ bb_cli pr --title 'My Next Big Feature'
```

#### Closing Issues

The below closes issue #15.

```bash
$ bb_cli close issue 15      # (or just 'bb_cli close i 15')
```

## Contributing

1. Fork the repo.
1. Create a branch with a descriptive name.
1. Create a pull request to this repo's master branch.

## License

Released under the MIT License: http://www.opensource.org/licenses/mit-license.php
