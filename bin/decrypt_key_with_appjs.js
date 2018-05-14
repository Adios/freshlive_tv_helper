#!/usr/bin/env node

'use strict'

const C = require('crypto-js')
const request = require('request')

if (process.argv.length < 4) {
    console.log('Usage: ' + __filename + ' ENCRYPTION_KEY_URI APPJS_URL')
    process.exit(64)
}

var encryption_key_uri = process.argv[2],
    appjs_url = process.argv[3]

let parse = /abemafresh:\/\/abemafresh\/([^\/]+)\/(.+)/,
    m = parse.exec(encryption_key_uri),
    token = m[1],
    encrypted_key = m[2]

request(appjs_url, (err, response, body) => {
    if (err) throw err

    let find_abemafresh_secret = /abemafresh:([^}]+)/,
        m = find_abemafresh_secret.exec(body)

    if (!m) {
        throw 'Find no secrets.'
    } else {
        let secret = ''
        // inject
        eval('secret = ' + m[1])

        process.stdout.write(
            binarize16(
                decrypt(token, secret, encrypted_key)
            )
        )
    }
})

/*
 *  Learned from app.js.
**/
function decrypt(hmac_key, hmac_msg, aes_cipher) {
    let aes_key = C.HmacSHA256(
            hmac_key,
            C.lib.WordArray.create(hmac_msg)
        )

    return C.AES.decrypt(
        C.lib.CipherParams.create({
            ciphertext: C.enc.Hex.parse(aes_cipher)
        }),
        aes_key,
        {
            mode: C.mode.ECB,
            padding: C.pad.NoPadding
        }
    ).toString()
}

function binarize16(str) {
    let a = new Uint8Array(16),
        i = 0

    for (; 16 > i; i++) {
        a[i] = parseInt(str.substr(2 * i, 2), 16)
    }
    return a
}
