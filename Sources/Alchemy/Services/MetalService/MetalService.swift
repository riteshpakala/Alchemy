import Granite

struct MetalService: GraniteService {
    @Service(.online) var center: Center
}
