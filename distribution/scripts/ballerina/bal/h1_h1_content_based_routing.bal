import ballerina/http;
import ballerina/log;
import ballerina/data.jsondata;

listener http:Listener securedEP = new(9090,
    secureSocket = {
        key: {
            path: "/home/ubuntu/ballerina-performance-distribution-1.1.1-SNAPSHOT/ballerinaKeystore.p12",
            password: "ballerina"
        }
    }
);

final http:Client nettyEP = check new("https://netty:8688",
    secureSocket = {
        cert: {
            path: "/home/ubuntu/ballerina-performance-distribution-1.1.1-SNAPSHOT/ballerinaTruststore.p12",
            password: "ballerina"
        },
        verifyHostName: false
    }
);

service /passthrough on securedEP {
    resource function post .(http:Caller caller, http:Request clientRequest) returns error? {
        json payload = check clientRequest.getJsonPayload();
        json prices = check jsondata:read(check payload.payload.'order, `$..[?(@.symbol == 'GOOG')].price`);
        json[] priceList = check prices.ensureType();
        float googlePrice = check priceList[0].ensureType();
        if googlePrice == 42.8 {
            http:Response|http:ClientError response = nettyEP->post("/service/EchoService", payload);
            if (response is http:Response) {
                error? result = caller->respond(response);
            } else {
                log:printError("Error at h1_h1_passthrough", 'error = response);
                http:Response res = new;
                res.statusCode = 500;
                res.setPayload(response.message());
                error? result = caller->respond(res);
            }
        }
    }
}
