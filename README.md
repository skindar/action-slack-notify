# Slack Notify - GitHub Action
[![Project Status: Active – The project has reached a stable, usable state and is being actively developed.](https://www.repostatus.org/badges/latest/active.svg)](https://www.repostatus.org/#active)


A [GitHub Action](https://github.com/features/actions) to send a message to a Slack channel.
This action is a part of [GitHub Actions Library](https://github.com/rtCamp/github-actions-library/) created by [rtCamp](https://github.com/rtCamp/)  

Changes: 
1) It configured to get webhook from google secrets. To do this it needs ENV variables called GCP_CREDENTIALS with GCP SA JSON. You will get error message if you don't specify GCP_CREDENTIALS. 
2) You can specify JOB_STATUS to send notification accordingly to workflow event. In other case if this variable not used it will send started build message. 

## Usage

You can use this action after any other action. Here is an example setup of this action:

1. Create a `.github/workflows/slack-notify.yml` file in your GitHub repo.
2. Add the following code to the `slack-notify.yml` file.

```yml
on: push
name: Slack Notification Demo
jobs:
  slackNotification:
    name: Slack Notification
    runs-on: ubuntu-latest
    steps:
    - name: Slack Notification
      uses: skindar/action-slack-notify@master
      env:
        GCP_CREDENTIALS: ${{ secrets.GOOGLE_APPLICATION_CREDENTIALS }}
        JOB_STATUS: ${{ job.status }}

```

3. Create `SLACK_WEBHOOK` secret using [GitHub Action's Secret](https://developer.github.com/actions/creating-workflows/storing-secrets). You can [generate a Slack incoming webhook token from here](https://slack.com/apps/A0F7XDUAZ-incoming-webhooks).


## Environment Variables

By default, action is designed to run with minimal configuration. It specify message according to github workflow event. Look code bellow
```bash
export SLACK_MESSAGE_SUCCESS="$GITHUB_REPOSITORY build: Success :the_horns:"
export SLACK_MESSAGE_STARTED="$GITHUB_REPOSITORY build: Started :clapper:"
export SLACK_MESSAGE_CANCELLED="$GITHUB_REPOSITORY build: Cancelled: :eyes:"
export SLACK_MESSAGE_FAILURE="$GITHUB_REPOSITORY build: Failure: :boom:"
export SLACK_COLOR_SUCCESS="#6aa84f"
export SLACK_COLOR_STARTED="#0074D9"
export SLACK_COLOR_CANCELLED="#cccccc"
export SLACK_COLOR_FAILURE="#ff0000"

if [[ -z "$JOB_STATUS" ]]; then
    export SLACK_MESSAGE=$SLACK_MESSAGE_STARTED
    export SLACK_COLOR=$SLACK_COLOR_STARTED
else
    MSG=SLACK_MESSAGE_$(echo $JOB_STATUS | tr a-z A-Z )
    MSG_COLOR=SLACK_COLOR_$(echo $JOB_STATUS | tr a-z A-Z )
    export SLACK_MESSAGE=${!MSG}
	export SLACK_COLOR=${!MSG_COLOR}
fi
```
