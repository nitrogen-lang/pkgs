import "std/http"
import "std/collections"
import "std/encoding/json"

const AUTH_HEADER = 'X-Auth-Token'

class DevicesAPI {
    let client = nil

    fn init(client) {
        this.client = client
    }

    const get_device = fn(hostname) {
        const r = this.client._do_request('GET', this.client._make_url('/devices/' + hostname), nil)
        const data = json.decode(r.body)

        if len(data['devices']) > 0 and collections.contains(data.devices[0], 'device_id') {
            data['devices'][0]
        } else {
            nil
        }
    }

    const discover_device = fn(hostname) {
        const r = this.client._do_request('GET', this.client._make_url('/devices/' + toString(hostname) + '/discover'), nil)
        json.decode(r.body)
    }

    /*
{
    hostname: "",
    force_add: false,
    snmp: {
        ver: "",
        transport: "",
        community: "",
        authlevel: "",
        authname: "",
        authpass: "",
        authalgo: "",
        cryptopass: "",
        cryptoalgo: "",
    }
}
    */
    // curl -X POST -d '{"hostname":"localhost.localdomain","version":"v1","community":"public"}' -H 'X-Auth-Token: YOURAPITOKENHERE' https://librenms.org/api/v0/devices
    const add_device = fn(device) {
        if !collections.contains(device, "hostname") {
            return error("Device requires a hostname")
        }

        if !collections.contains(device, "snmp") {
            return error("Device requires snmp credentials")
        }

        const snmpver = collections.getOrDefault(device.snmp, "ver", "v2c")

        const body = {
            "hostname": device.hostname,
            "force_add": collections.getOrDefault(device, "force_add", false),
            "snmpver": snmpver,
            "transport": collections.getOrDefault(device.snmp, "transport", "udp"),
        }

        if snmpver == "v1" or snmpver == "v2c" {
            body.community = device.snmp.community
        } elif snmpver == "v3" {
            const snmp = device.snmp
            body.authlevel = snmp.authlevel
            body.authname = snmp.authname
            body.authpass = snmp.authpass
            body.authalgo = snmp.authalgo
            body.cryptopass = snmp.cryptopass
            body.cryptoalgo = snmp.cryptoalgo
        } else {
            return error("Invalid SNMP version")
        }

        const r = this.client._do_request('POST', this.client._make_url('/devices'), json.encode(body))
        json.decode(r.body)
    }

    const list_devices = fn(filter) {
        const order = collections.getOrDefault(filter, "order", "hostname")
        const filter_type = collections.getOrDefault(filter, "type", "all")
        const query = collections.getOrDefault(filter, "query", "")
        const args = "order="+order+"&type="+filter_type+"&query="+query
        const url = this.client._make_url('/devices?'+args)
        const r = this.client._do_request('GET', url, nil)
        json.decode(r.body)
    }
}

export class Client {
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

    const _do_request = fn(method, url, body) {
        http.req(method, url, body, {
            "headers": {
                AUTH_HEADER: this.api_token,
            },
            "tls_verify": this.check_tls,
        })
    }

    const system = fn() {
        const r = this._do_request('GET', this._make_url('/system'), nil)
        json.decode(r.body)
    }

    fn devices() {
        new DevicesAPI(this)
    }
}
