# git_web_cli - CLI for managing Git remote repositories

git_web_cli is a CLI (Command Line Interface) for managing remote repositories.


## Features

It currently supports the below features:

- Listing issues.
- Listing pull requests (merge requests on BitBucket)
- Creating issues.
- Creating pull requests.
- Opening issues or pull requests in the browser.
- Closing issues.

Supports GitHub, BitBucket and GitLab.


## Installation

### 1. Download The Binary

Visit the [Releases](http://example.com) page and download the binary.
Unzip it and put the 'gw' file anywhere on your PATH.

### 2. Install Erlang and OTP

Pre-packaged binaries can be found at [Erlang Solutions](https://www.erlang-solutions.com/resources/download.html).

Or alternatively:

* Mac OS X (with brew)

```bash
$ brew install erlang
```

* Debian Linux

```bash
$ sudo apt-get install erlang
```

* Ubuntu Linux

```bash
$ sudo apt-get install erlang
```

### 3. Setup Your OAuth 2 Client ID and Client Secret

Create an OAuth 2 Client ID and Client Secret in GitHub / BitBucket / GitLab.

The Callback URL should be 'urn:ietf:wg:oauth:2.0:oob'.

* GitHub
    * [New OAuth Application - GitHub](https://github.com/settings/applications/new)
* BitBucket
    * Visit 'https://bitbucket.org/account/user/YOUR_BITBUCKET_USER_ID/oauth-consumers/new' and create a new application.
* GitLab
    * Visit 'https://YOUR_GITLAB_HOST/oauth/applications/new' and create a new application.

Once you have obtained your Client ID and Client Secret, go to your repository directory and type:

```bash
$ gw set oauth2 CLIENT_ID CLIENT_SECRET
```

You should be good to go!


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
