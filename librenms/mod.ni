import "std/http"
import "std/collections"
import "std/encoding/json"

const AUTH_HEADER = 'X-Auth-Token'

class Client {
    let endpoint = ''
    let check_tls = true
    let api_token = ''

    func init(endpoint) {
        this.endpoint = endpoint
    }

    func skip_tls_verify() {
        this.check_tls = false
    }

    func login(api_token) {
        this.api_token = api_token
        this.system()
    }

    func _make_url(path) { this.endpoint + '/api/v0' + path }

    func _do_request(method, url) {
        return http.req(method, url, nil, {
            "headers": {
                AUTH_HEADER: this.api_token,
            },
            "tls_verify": this.check_tls,
        })
    }

    func system() {
        const r = this._do_request('GET', this._make_url('/system'))
        return json.decode(r.body)
    }

    func get_device(hostname) {
        const r = this._do_request('GET', this._make_url('/devices/' + hostname))
        const data = json.decode(r.body)

        if len(data['devices']) > 0 and collections.contains(data.devices[0], 'device_id') {
            return data['devices'][0]
        }

        return nil
    }
}

return {
    "Client": Client,
}
