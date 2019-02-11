import "std/http"
import "std/collections"
import "std/encoding/json"

const AUTH_HEADER = 'Authorization'

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
        this.api_token = 'Token ' + api_token
        this._test_token()
    }

    const _make_url = fn(path) { this.endpoint + '/api' + path }

    const _do_request = fn(method, url) {
        http.req(method, url, nil, {
            "headers": {
                AUTH_HEADER: this.api_token,
            },
            "tls_verify": this.check_tls,
        })
    }

    const _test_token = fn() {
        const r = this._do_request('GET', this._make_url('/extras/_choices'))
        if r.status_code == 403 {
            throw "Invalid API token"
        }
    }

    const get_ipam_addresses = fn(parent) {
        const url = this._make_url('/ipam/ip-addresses') + '?parent=' + parent
        let r = this._do_request('GET', url)
        let data = json.decode(r.body)

        let ips = data.results

        while !isNull(data.next) {
            r = this._do_request('GET', data.next)
            data = json.decode(r.body)
            ips = ips + data.results
        }

        ips
    }
}

return {
    "Client": Client,
}
