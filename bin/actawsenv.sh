
# SET AWSENV with MFA
# > usage: source actawsenv token-code profile
# > put bellow-script to .zshrc

# actawsenv(){
#     source path/to/actawsenv.sh $1 $2
# }


actawssenvloggerINFO(){
    echo $(date +"%H:%M:%S") "\e[32m[INFO]\e[m $1" 
}
actawssenvloggerERROR(){
    echo $(date +"%H:%M:%S") "\e[31m[ERROR]\e[m $1" 
}
actawssenvusage(){
    echo -e "\e[34musage\e[m: source $0 token-code [profile=default]" 1>&2
}

profile='default'


if [ $# -eq 1 ]; then
    mfacode=$1
elif [ $# -eq 2 ]; then
    mfacode=$1
    profile=$2
else
    echo $(date +"%H:%M:%S")' [ERROR] parameter error'
    actawssenvusage
    return
fi

actawssenvloggerINFO 'Get ARN...'
arn=$(aws sts get-caller-identity --profile ${profile} | jq -r .Arn | sed -e 's/:user\//:mfa\//')


actawssenvloggerINFO 'Get SessionToken...'
jsonToken=$(aws sts get-session-token --serial-number $arn --token-code $mfacode --profile $profile)
if [[ $jsonToken = '' ]]; then
    actawssenvloggerERROR 'can not get SessionToken'
    actawssenvusage
    return
fi

aws_access_key_id=$(echo $jsonToken | jq -r '.Credentials.AccessKeyId')
aws_secret_access_key=$(echo $jsonToken | jq -r '.Credentials.SecretAccessKey')
aws_session_token=$(echo $jsonToken | jq -r '.Credentials.SessionToken')

actawssenvloggerINFO 'Set env ...'
export AWS_ACCESS_KEY_ID=${aws_access_key_id}
export AWS_SECRET_ACCESS_KEY=${aws_secret_access_key}
export AWS_SESSION_TOKEN=${aws_session_token}
export AWS_SDK_LOAD_CONFIG=true

actawssenvloggerINFO 'SUCESS!'
# for zsh (prezto)
actawssenvloggerINFO 'Set PROMPT'
PROMPT="[$profile] "

echo "-+-+-+-+-+-+-+-+-result-+-+-+-+-+-+-+-+-+-+"
echo ARN=$arn
echo PROFILE=$profile
echo MFACODE=$mfacode
echo $jsonToken | jq .
echo "-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-"
