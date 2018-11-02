import "stdlib/http"
import "stdlib/collections"
import "stdlib/encoding/json"

const AUTH_HEADER = 'Authorization'

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
        this.api_token = 'Token ' + api_token
        this._test_token()
    }

    func _make_url(path) { this.endpoint + '/api' + path }

    func _do_request(method, url) {
        return http.req(method, url, nil, {
            "headers": {
                AUTH_HEADER: this.api_token,
            },
            "tls_verify": this.check_tls,
        })
    }

    func _test_token() {
        const r = this._do_request('GET', this._make_url('/extras/_choices'))
        if r.status_code == 403 {
            throw "Invalid API token"
        }
    }

    func get_ipam_addresses(parent) {
        const url = this._make_url('/ipam/ip-addresses') + '?parent=' + parent
        let r = this._do_request('GET', url)
        let data = json.decode(r.body)

        let ips = data.results

        while !isNull(data.next) {
            r = this._do_request('GET', data.next)
            data = json.decode(r.body)
            ips = ips + data.results
        }

        return ips
    }
}

return {
    "Client": Client,
}
