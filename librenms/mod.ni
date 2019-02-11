import "std/http"
import "std/collections"
import "std/encoding/json"

const AUTH_HEADER = 'X-Auth-Token'

class Client {
    let endpoint = ''
    let check_tls = true
    let api_token = ''

    const init = fn(endpoint) {
        this.endpoint = endpoint
    }

    const skip_tls_verify = fn() {
        this.check_tls = false
    }

    const login = fn(api_token) {
        this.api_token = api_token
        this.system()
    }

    const _make_url = fn(path) { this.endpoint + '/api/v0' + path }

    const _do_request = fn(method, url) {
        http.req(method, url, nil, {
            "headers": {
                AUTH_HEADER: this.api_token,
            },
            "tls_verify": this.check_tls,
        })
    }

    const system = fn() {
        const r = this._do_request('GET', this._make_url('/system'))
        json.decode(r.body)
    }

    const get_device = fn(hostname) {
        const r = this._do_request('GET', this._make_url('/devices/' + hostname))
        const data = json.decode(r.body)

        if len(data['devices']) > 0 and collections.contains(data.devices[0], 'device_id') {
            data['devices'][0]
        } else {
            nil
        }
    }
}

return {
    "Client": Client,
}
