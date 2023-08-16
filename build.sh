#!/bin/bash -eu

USER_ID=$(id -u)
GROUP_ID=$(id -g)
USER_NAME=ubuntu

# targetフォルダが存在しない場合のみ作成
if [ ! -d "target" ]; then
  mkdir target
fi

cat << EOS > Dockerfile
FROM ubuntu:20.04

# 必要なものをインストール
RUN apt-get update && \
    apt-get install -y sudo git vim curl ca-certificates wget build-essential libreadline-dev \
    libncursesw5-dev libssl-dev libsqlite3-dev libgdbm-dev libbz2-dev liblzma-dev zlib1g-dev uuid-dev libffi-dev libdb-dev openssl \
    language-pack-ja-base language-pack-ja locales && \
    apt-get clean -y

# 任意バージョンのpython install
RUN wget --no-check-certificate https://www.python.org/ftp/python/3.9.5/Python-3.9.5.tgz && \
    tar -xf Python-3.9.5.tgz && \
    cd Python-3.9.5 && \
    ./configure --enable-optimizations && \
    make && \
    make install

# サイズ削減のため不要なものは削除
RUN apt-get autoremove -y

ENV TZ=Asia/Tokyo
RUN ln -snf /usr/share/zoneinfo/\$TZ /etc/localtime && echo \$TZ > /etc/timezone
RUN locale-gen ja_JP.UTF-8

# ユーザーを作成
RUN useradd -m --uid $USER_ID --groups sudo $USER_NAME && echo $USER_NAME:$USER_NAME | chpasswd

# ユーザーがNoPassでsudoが使えるように設定
RUN echo "$USER_NAME ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/$USER_NAME && \
    chmod 0440 /etc/sudoers.d/$USER_NAME

# 作成したユーザーに切り替える
USER $USER_NAME
WORKDIR /home/$USER_NAME/symbol

# 日本語化
RUN echo "export LANG=ja_JP.UTF-8" >> /home/$USER_NAME/.bashrc

CMD ["tail", "-f", "/dev/null"]
EOS

# tag名を入力
echo -n "input docker image name:"
#入力を受付、その入力を「tagname」に代入
read tagname

# Build docker image
if [[ ${tagname} =~ ^([a-zA-Z0-9]+-)?[vV]?[0-9]+(\.[0-9]+){2}(-[a-zA-Z0-9]+)?$|^latest$ ]]; then
  COMMAND="docker build -t symbol-shoestring:${tagname} ."
  echo ${COMMAND}
  eval ${COMMAND}
else
  echo "タグ名を入力してください。"
  exit
fi

cat << EOS > docker-compose.yml
version: '2.4'
services:
  app:
    image: symbol-shoestring:$tagname
    volumes:
      - ./target:/home/$USER_NAME/symbol
    user: "$USER_ID:$GROUP_ID"
EOS

cat << EOS > target/README.md
# githubからソースコード取得
※元プロジェクトへのPRを送るなら自身のプロジェクトにforkしたプロジェクトからcloneしてください。

\`\`\`
git clone https://github.com/symbol/product.git
\`\`\`

\`\`\`
cd product/tools/shoestring
\`\`\`

# dev_requirements.txtのインストール

(docker compose downをすると初期化されるので毎回必要)

\`\`\`
pip3 install -r dev_requirements.txt
\`\`\`

# requirements.txtのインストール

(docker compose downをすると初期化されるので毎回必要)

\`\`\`
pip3 install -r requirements.txt
\`\`\`

# パスの追加

(docker compose downをすると初期化されるので毎回必要)

\`\`\`
PATH=\$PATH:/home/$USER_NAME/.local/bin
\`\`\`

# build実行

(言語ファイル修正毎に必要)

\`\`\`
./scripts/ci/build.sh
\`\`\`

# インストール

(コード修正毎に必要)

\`\`\`
pip3 install .
\`\`\`

# 実行

\`\`\`
PYTHONPATH=. python3 -m shoestring --help

※wizardを日本語で起動する場合
LC_MESSAGES=ja python3 -m shoestring.wizard
\`\`\`


# pipインストールパッケージを調べる

\`\`\`
pip3 show shoestring
\`\`\`


EOS

echo "Dockerイメージのビルドが完了しました。"
echo "ビルドイメージ名は symbol-shoestring:${tagname} です"
echo "docker-compose(またはdocker compose) up -d でコンテナを起動し、docker-compose exec app(またはdocker compose exec app) bash コマンドを実行してコンテナに入ってください。"
echo "コンテナ内では python3 -m shoestring.wizard コマンドが使用出来ます。"