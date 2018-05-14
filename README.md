# freshlive.tv Helper

The repository contains a collection of tools for downloading archived programs of subscribed channels on _[Fresh!](https://freshlive.tv/)_.

_[Fresh!](https://freshlive.tv/)_ is a Japanese live streaming platform which delivers programs in [HTTP Live Streaming](https://en.wikipedia.org/wiki/HTTP_Live_Streaming). It protects paid contents by HLS encryption with keys (`EXT-X-KEY`) that are further encrypted with user tokens in a custom algorithm.

- first [retrieve_encryption_key_uri.rb](bin/retrieve_encryption_key_uri.rb) to get the encrypted key of a paid program,
- and [decrypt_key_with_appjs.js](bin/decrypt_key_with_appjs.js) to decrypt the key,
- finally make a [ffmpeg](https://www.ffmpeg.org/)-friendly m3u8 by [customize_playlist.rb](bin/customize_playlist.rb). 

It also comes with a simple [run.sh](/run.sh) for downloading a program, and could possibly explain the usage contexts for the above tools. (The script could be outdated if the site get updated in the future.) 

## Prerequisites

- _shell commands_ (_sh, sed, grep_)
- _ruby_
- _node_
- _ffmpeg_ (_if need downloading_)

tested on macOS High Sierra.

## Installing

Checkout the codes first,

```bash
git clone https://github.com/Adios/freshlive_tv_helper
```

And then setup the modules for node,

```bash
npm install
```

Finally the gems with [Bundler](https://bundler.io/),

```bash
bundle --standalone
```

## Usage
Before starting, you should obtain two URLs from the program page,

- Log into _[Fresh!](https://freshlive.tv/)_
- Browse to an archieved paid program you want to download, e.g.: https://freshlive.tv/uchidamaaya/191012.
(_Note that you must be a subscriber for that channel in order to get the required information._)
- Open developer tool, find the link to the _**archive.m3u8**_ with **a token included**, it looks like this:
  ```
  https://movie.freshlive.tv/manifest/191012/archive.m3u8?token=NNNNNNtNNNNXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX&version=2&beta4k=
  ```
- _**app.js**_, at which the site stores **the custom secret**, e.g.:
  ```
  https://freshlive.tv/assets/1524096831/app.js
  ```

### Step By Step

Let us first get the _encrypted encryption key_ of that program from the _**archive.m3u8**_ ,
```bash
bin/retrieve_encryption_key_uri.rb \
        'https://movie.freshlive.tv/manifest/191012/archive.m3u8?token=NNNNNNtNNNNXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX&version=2&beta4k='
```
You would see the result string like this,
```
abemafresh://abemafresh/NNNNNNtNNNNXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX/0de7c2f47df5b6a559fbdeff5341363a
```
Acutually it's the URI value of the m3u8's `EXT-X-KEY` field. However _ffmpeg_ is unable to recognize the meaning since it is further encrypted with _[Fresh!](https://freshlive.tv/)_'s algorithm. That's why you can't `ffmpeg -i m3u8 -c copy` without pain.

Now let us decrypt the string with the secret stored at _**app.js**_
```bash
bin/decrypt_key_with_appjs.js \
        'abemafresh://abemafresh/NNNNNNtNNNNXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX/0de7c2f47df5b6a559fbdeff5341363a' \
        'https://freshlive.tv/assets/1524096831/app.js' > program.key
```

Congratulations! You obtain the real encryption key _**program.key**_ which should be a 16-bytes binary file. And we then **make a new playlist** from _**archive.m3u8**_ with the real encryption key:

```bash
bin/customize_playlist.rb \
        'https://movie.freshlive.tv/manifest/191012/archive.m3u8?token=NNNNNNtNNNNXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX&version=2&beta4k=' \
        program.key > program.m3u8
```

And finally download it with _ffmpeg_:
```bash
ffmpeg -allowed_extensions ALL \
        -protocol_whitelist 'crypto+https,file,crypto,https,tls,tcp' \
        -i program.m3u8 -codec copy program.ts
```

### All-For-One

1. Log in, browser to program page, e.g.: https://freshlive.tv/uchidamaaya/191012.
2. Open developer tool, look for `?token=NNNNNNtNNNNXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX` to get your token.
3. [run.sh](/run.sh) it.
    ```bash
    ./run.sh 'NNNNNNtNNNNXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX' 'https://freshlive.tv/uchidamaaya/191012'
    ```

## Authors

* **Adios** - *Initial work* - [Adios](https://github.com/Adios)
