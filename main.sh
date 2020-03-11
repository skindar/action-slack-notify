#!/usr/bin/env bash
export GOOGLE_APPLICATION_CREDENTIALS=$service_account_key
export GITHUB_BRANCH=${GITHUB_REF##*heads/}
export SLACK_ICON=${SLACK_ICON:-"https://octodex.github.com/images/jetpacktocat.png"}
export SLACK_USERNAME=${SLACK_USERNAME:-"GH Action - Build"}
export CI_SCRIPT_OPTIONS="ci_script_options"
export SLACK_TITLE=${SLACK_TITLE:-"Message"}
export COMMIT_MESSAGE=$(cat "/github/workflow/event.json" | jq .commits | jq '.[0].message' -r)
# slack messages

export SLACK_MESSAGE_SUCCESS=$GITHUB_REPOSITORY build: Success :the_horns:
export SLACK_MESSAGE_STARTED=$GITHUB_REPOSITORY build: Started :clapper:
export SLACK_MESSAGE_CANCELLED=$GITHUB_REPOSITORY build: Cancelled: :eyes:
export SLACK_MESSAGE_FAILED=$GITHUB_REPOSITORY build: Failure: :boom:

hosts_file="$GITHUB_WORKSPACE/.github/hosts.yml"

if [[ -z "$SLACK_CHANNEL" ]]; then
	if [[ -f "$hosts_file" ]]; then
		user_slack_channel=$(cat "$hosts_file" | shyaml get-value "$CI_SCRIPT_OPTIONS.slack-channel" | tr '[:upper:]' '[:lower:]')
	fi
fi

if [[ -n "$user_slack_channel" ]]; then
	export SLACK_CHANNEL="$user_slack_channel"
fi

# Login to vault using GH Token
if [[ -n "$VAULT_GITHUB_TOKEN" ]]; then
	unset VAULT_TOKEN
	vault login -method=github token="$VAULT_GITHUB_TOKEN" > /dev/null
fi

# Google Auth
echo $GOOGLE_APPLICATION_CREDENTIALS > /github/home/key.json
export project=$(cat /github/home/key.json | python -c "import sys, json; print json.load(sys.stdin)['project_id']")
export client_email=$(cat /github/home/key.json | python -c "import sys, json; print json.load(sys.stdin)['client_email']")
gcloud auth activate-service-account $client_email --key-file=/github/home/key.json
export SLACK_WEBHOOK=$(gcloud secrets versions access latest --secret="SLACK_WEBHOOK" --project $project)

if [[ -n "$VAULT_GITHUB_TOKEN" ]] || [[ -n "$VAULT_TOKEN" ]]; then
	export SLACK_WEBHOOK=$(vault read -field=webhook secret/slack)
fi

if [[ -f "$hosts_file" ]]; then
	hostname=$(cat "$hosts_file" | shyaml get-value "$GITHUB_BRNCH.hostname")
	user=$(cat "$hosts_file" | shyaml get-value "$GITHUB_BRANCH.user")
	export HOST_NAME="\`$user@$hostname\`"
	export DEPLOY_PATH=$(cat "$hosts_file" | shyaml get-value "$GITHUB_BRANCH.deploy_path")

	temp_url=${DEPLOY_PATH%%/app*}
	export SITE_NAME="${temp_url##*sites/}"
    export HOST_TITLE="SSH Host"
fi

k8s_site_hostname="$GITHUB_WORKSPACE/.github/kubernetes/hostname.txt"

if [[ -f "$k8s_site_hostname" ]]; then
    export SITE_NAME="$(cat $k8s_site_hostname)"
    export HOST_NAME="\`$CLUSTER_NAME\`"
    export HOST_TITLE="Cluster"
fi

if [[ -n "$SITE_NAME" ]]; then
    export SITE_TITLE="Site"
fi


if [[ -z "$SLACK_MESSAGE" ]]; then
	export SLACK_MESSAGE="$COMMIT_MESSAGE"
fi

slack-notify "$@"
