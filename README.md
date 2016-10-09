# oretamaBot
[oretamaBot](https://twitter.com/oretamaBot) is a [Twitter](https://twitter.com/)'s bot.

## Function
oretamaBot has following functions.

### Help

| how to call | explanation |
|----|------|
| @oretamaBot (help\|ヘルプ\|使い方\|教えて) | Display all of the help commands which Hubot knows. |

### Diagostics

| how to call | explanation |
|----|------|
| @oretamaBot (ping\|おーい\|おーい？\|おい\|おい？\|生きてる？\|生きている？\|大丈夫？) | Mention "なに～？" to you. | 
| @oretamaBot (date\|日にち\|何日) | Mention today's date to you. |
| @oretamaBot (day\|曜日) | Mention today's day to you. |
| @oretamaBot (time\|時間\|何時) | Mention now's time to you. |

### SearchTwitterTimeline

| how to call | explanation |
|----|------|
| @oretamaBot ツイート流して \<query\> | Mention the tweets which includes \<query\> to you. |
| @oretamaBot ツイート止めて | Stop to mention the tweets. |

### SearchAmazonComicRelease

| how to call | explanation |
|----|------|
| @oretamaBot kindle最新刊探して \<title\> | Mention new release kindle's comic whose title include \<title\> to you. |
| @oretamaBot comic最新刊探して \<title\> | Mention new release comic whose title include \<title\> to you. |
| @oretamaBot kindle登録して \<title\> | Register kindle's comic title that you want to know new release. |
| @oretamaBot comic登録して \<title\> | Register comic title that you want to know new release. |
| @oretamaBot 登録内容教えて | Display all the registrations. |

## Usage
```
npm install
```

You make bash file for starting bot and kick the bash.
```
#!/bin/bash

export HUBOT_TWITTER_KEY=XXXX
export HUBOT_TWITTER_SECRET=XXXX
export HUBOT_TWITTER_TOKEN=XXXX
export HUBOT_TWITTER_TOKEN_SECRET=XXXX
export AWS_ASSOCIATE_ID=XXXX
export AWS_ID=XXXX
export AWS_SECRET=XXXX

bin/hubot --adapter twitter -n oretamaBot
```

