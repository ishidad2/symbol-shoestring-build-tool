shoestring build tool
===

# 概要

[symbol-shoestring](https://github.com/symbol/product/tree/main/tools/shoestring)をDockerコンテナ内で実行するためのツールです。

Python3.9の環境をコンテナ化してあるので、Windows(WSL)、Mac、Linuxで動きます。

# 実行

```
curl -o build.sh https://raw.githubusercontent.com/ishidad2/symbol-shoestring-build-tool/main/build.sh && bash build.sh
```

# 補足　Dockerコンテナのビルド

- 初回実行時には数分かかる可能性があります。
- コマンドを実行したディレクトリに `target`ディレクトリ、`Dockerfile`、`docker-compose.yml` が作成されます。
  `docker-compose up -d` を実行してコンテナを立ち上げてください。

  続いて、 `docker-compose exec app bash` を実行してコンテナ内に入ってください。
  
  コンテナ内では `python3 -m shoestring.wizard` が使用できます。（shoestringに関わるコマンドが実行できます）

